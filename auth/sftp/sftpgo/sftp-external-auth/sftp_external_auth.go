package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/storage"
	"github.com/sirupsen/logrus"
	"google.golang.org/api/option"
)

const bufferSize = 1024

var log *logrus.Logger

func isAlphanum(c rune) bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
}

func isAlphanumString(s string) bool {
	for _, c := range s {
		if !isAlphanum(c) {
			return false
		}
	}

	return true
}

type gcsConfig struct {
	Bucket               string `json:"bucket,omitempty"`
	Credentials          string `json:"credentials,omitempty"`
	AutomaticCredentials int    `json:"automatic_credentials"`
	KeyPrefix            string `json:"key_prefix"`
}

type filesystem struct {
	// 0 local filesystem, 1 Amazon S3 compatible, 2 Google Cloud Storage
	Provider  int       `json:"provider"`
	GCSConfig gcsConfig `json:"gcsconfig"`
}

type responseStruct struct {
	Status            int                    `json:"status"`
	Username          string                 `json:"username"`
	ExpirationDate    int                    `json:"expiration_date"`
	HomeDir           string                 `json:"home_dir"`
	UID               int                    `json:"uid"`
	GID               int                    `json:"gid"`
	MaxSessions       int                    `json:"max_sessions,omitempty"`
	QuotaSize         int                    `json:"quota_size,omitempty"`
	QuotaFiles        int                    `json:"quota_files,omitempty"`
	Permissions       map[string]interface{} `json:"permissions"`
	UploadBandwidth   int                    `json:"upload_bandwidth,omitempty"`
	DownloadBandwidth int                    `json:"download_bandwidth,omitempty"`
	Filters           map[string]interface{} `json:"filters"`
	PublicKeys        []string               `json:"public_keys,omitempty"`
	FsConfig          filesystem             `json:"filesystem"`
}

func authFailure(username string, err error, msg string) {
	log.WithFields(logrus.Fields{
		"username": username,
		"err":      err.Error(),
		"ctx":      "external_auth",
	}).Error(msg)

	// this print to stdout will be consumed by sftpgo
	fmt.Printf("{\"username\":\"\"}")

	os.Exit(1)
}

func authSuccess(username string, uid int, gid int, homeDir string, publicKey string, bucketName string, credentials string) {
	// This is from here - https://github.com/drakkan/sftpgo/blob/0.9.6/httpd/schema/openapi.yaml#L1076
	permissions, ok := os.LookupEnv("SFTP_PERMISSIONS")
	if !ok {
		permissions = "list"
	}
	response := responseStruct{
		Status:         1,
		Username:       username,
		ExpirationDate: 0,
		HomeDir:        homeDir,
		UID:            uid,
		GID:            gid,
		MaxSessions:    2,
		QuotaFiles:     0,
		Permissions: map[string]interface{}{
			"/": strings.Split(permissions, ","),
		},
		Filters: map[string]interface{}{
			"allowed_ip":           []string{},
			"denied_ip":            []string{},
			"denied_login_methods": []string{"password", "keyboard-interactive"},
		},
		PublicKeys: []string{publicKey},
	}

	if len(bucketName) > 0 {
		gcsConfig := gcsConfig{
			Bucket:               bucketName,
			AutomaticCredentials: 0,
			Credentials:          credentials,
			KeyPrefix:            username,
		}

		filesystem := filesystem{
			Provider:  2,
			GCSConfig: gcsConfig,
		}

		response.FsConfig = filesystem
	}

	json, err := json.Marshal(response)
	if err != nil {
		authFailure(username, err, "error while marshalling json")
	}

	jsonString := string(json)

	log.WithFields(logrus.Fields{
		"username": username,
		"ctx":      "external_auth",
		"json":     jsonString,
	}).Info("successfully authenticated")

	// this print to stdout will be consumed by sftpgo
	fmt.Printf("%v\n", jsonString)

	os.Exit(0)
}

func setupLogger() {
	log = logrus.New()

	logsDir, ok := os.LookupEnv("LOGS_DIR")
	if !ok {
		logsDir = "/logs"
	}

	logFileName := fmt.Sprintf("%s/sftpgo_external_auth.log", logsDir)

	logFile, err := os.OpenFile(logFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic(fmt.Sprintf("error when opening log file: %s; err: %s", logFileName, err.Error()))
	}

	log.Out = logFile
	log.Formatter = &logrus.JSONFormatter{}

	log.SetLevel(logrus.DebugLevel)
}

func main() {
	setupLogger()

	username, ok := os.LookupEnv("SFTPGO_AUTHD_USERNAME")
	if !ok {
		authFailure("", errors.New("SFTPGO_AUTHD_USERNAME is undefined"), "username is empty")
	}

	if !isAlphanumString(username) {
		authFailure(username, errors.New("non alphanumeric username"), "username is invalid")
	}

	uid := 100
	gid := 100

	uidString, ok := os.LookupEnv("PUID")
	if ok {
		uid, _ = strconv.Atoi(uidString)
	}

	gidString, ok := os.LookupEnv("PGID")
	if ok {
		gid, _ = strconv.Atoi(gidString)
	}

	publicKey, ok := os.LookupEnv("SFTPGO_AUTHD_PUBLIC_KEY")
	if !ok {
		authFailure(username, errors.New("SFTPGO_AUTHD_PUBLIC_KEY is undefined"), "public key is empty")
	}

	publicKeyFields := strings.Split(strings.TrimSpace(publicKey), " ")
	if len(publicKeyFields) != 2 {
		authFailure(username, errors.New("SFTPGO_AUTHD_PUBLIC_KEY is invalid"), "public key should have algorithm and the field")
	}

	// local directory where the payload is written to
	payloadBaseDir, ok := os.LookupEnv("PAYLOAD_BASE_DIR")
	if !ok {
		payloadBaseDir = "/opt"
	}

	// bucket where the payload is written to
	// this overrides the previous local directory approach
	gcsPayloadBucket, ok := os.LookupEnv("GCS_PAYLOAD_BUCKET")
	if !ok {
		gcsPayloadBucket = ""
	}

	// service account for writing into payload gcs bucket
	// sftpgo expects a base64 encoded key for the payload bucket
	gcsPayloadCredsB64, ok := os.LookupEnv("GCS_PAYLOAD_CREDS_B64")
	if !ok {
		gcsPayloadCredsB64 = ""
	}

	// local directory to fetch public keys
	keysDir, ok := os.LookupEnv("KEYS_DIR")
	if !ok {
		keysDir = "/mnt/keys"
	}

	// bucket where the public keys are accessed from
	// this overrides the previous local directory approach
	gcsKeysBucket, ok := os.LookupEnv("GCS_KEYS_BUCKET")
	if !ok {
		gcsKeysBucket = ""
	}

	// service account for accessing keys gcs bucket
	// google cloud sdk expects this to be in json
	gcsKeysCredsJSON, ok := os.LookupEnv("GCS_KEYS_CREDS_JSON")
	if !ok {
		gcsKeysCredsJSON = ""
	}

	var publicKeyFromFile string
	if len(gcsKeysBucket) > 0 {
		ctx := context.Background()
		ctx, cancel := context.WithTimeout(ctx, time.Second*50)
		defer cancel()
		client, err := storage.NewClient(ctx, option.WithCredentialsJSON([]byte(gcsKeysCredsJSON)))
		if err != nil {
			authFailure(username, err, "Failed to create cloud storage client.")
		}

		gcsObject := fmt.Sprintf("%s/%s.pub", username, username)
		reader, err := client.Bucket(gcsKeysBucket).Object(gcsObject).NewReader(ctx)
		if err != nil {
			authFailure(username, err, "Failed to create cloud storage reader.")
		}
		defer reader.Close()

		publicKeyFileBytes, err := ioutil.ReadAll(reader)
		if err != nil {
			authFailure(username, err, fmt.Sprintf("Failed to read from public key file: %s", gcsObject))
		}
		publicKeyFromFile = string(publicKeyFileBytes)
	} else {
		publicKeyFile := fmt.Sprintf("%s/%s/%s.pub", keysDir, username, username)

		f, err := os.Open(publicKeyFile)
		if err != nil {
			authFailure(username, err, fmt.Sprintf("cannot open public key file: %s", publicKeyFile))
		}

		publicKeyFileBuf := make([]byte, bufferSize)
		nBytes, err := f.Read(publicKeyFileBuf)
		if err != nil {
			authFailure(username, err, fmt.Sprintf("cannot read public key file: %s", publicKeyFile))
		}

		publicKeyFromFile = string(publicKeyFileBuf[:nBytes])
	}

	publicKeyFromFileFields := strings.Split(publicKeyFromFile, " ")
	if len(publicKeyFromFileFields) != 3 {
		authFailure(username, errors.New("Public key from file is invalid"), "public key file should have three fields")
	}

	if publicKeyFields[0] != publicKeyFromFileFields[0] {
		authFailure(username, errors.New("key alg mismatch"), "authentication failure")
	}

	if publicKeyFields[1] != publicKeyFromFileFields[1] {
		authFailure(username, errors.New("key mismatch"), "authentication failure")
	}

	var bucketDir string
	fInfo, err := os.Stat(payloadBaseDir)
	if err == nil && fInfo.IsDir() {
		// the following logic is only for a local bucket directory
		bucketDir = fmt.Sprintf("%s/%s", payloadBaseDir, username)
		if _, err := os.Stat(bucketDir); os.IsNotExist(err) {
			if err = os.Mkdir(bucketDir, 0644); err != nil {
				authFailure(username, err, "cannot create new bucket dir")
			}

			if err = os.Chown(bucketDir, uid, gid); err != nil {
				authFailure(username, err, "cannot chown new bucket dir")
			}
		}
	}

	authSuccess(username, uid, gid, bucketDir, publicKey, gcsPayloadBucket, gcsPayloadCredsB64)
}
