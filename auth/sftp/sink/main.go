package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"time"

	"github.com/hpcloud/tail"
)

const ConnectionFailed = "connection_failed"
const LogSinceThreshold = -1 * time.Minute // If a pod restarts, we don't want the attached volume logs to be reprocessed
const SftpGoDateFormat = "2006-01-02T15:04:05.999"
const Fail2BanDateFormat = "2006-01-02 15:04:05"

func main() {
	t, err := tail.TailFile(getLogPath(), tail.Config{Follow: true, ReOpen: true, Poll: true})
	if err != nil {
		fmt.Errorf("%v", err)
		os.Exit(1)
	}
	defer t.Cleanup()

	writer := setupFileLogger(os.Getenv("CONSOLIDATED_FAILED_AUTH_LOGFILE"))
	defer writer.Flush()

	go flushPeriodically(writer)

	for line := range t.Lines {
		if line != nil {
			go processLogLine(line.Text, writer)
		}
	}
}

func flushPeriodically(writer *bufio.Writer) {
	flushTicker := time.NewTicker(5 * time.Second)
	for {
		select {
		case <-flushTicker.C:
			if writer.Buffered() > 0 {
				writer.Flush()
			}
		}
	}
}

func processLogLine(line string, writer io.Writer) {
	var logEntry LogEntry
	if err := json.Unmarshal([]byte(line), &logEntry); err != nil {
		fmt.Errorf("%v", err)
		return
	}

	aMinuteGo := time.Now().UTC().Add(LogSinceThreshold)
	if logEntry.Sender == ConnectionFailed && logEntry.UserName != "" && logEntry.Time.UTC().After(aMinuteGo) {
		fmt.Fprintln(writer, fmt.Sprintf(
			"%s Connection failed with error %s from: %s",
			logEntry.Time.Format(Fail2BanDateFormat),
			logEntry.LoginType,
			logEntry.ClientIP,
		))
	}
}

func getLogPath() string {
	path, ok := os.LookupEnv("SFTPGO_LOG_FILE_PATH")
	if !ok {
		path = "/logs/sftpgo.log"
	}

	return path
}

func setupFileLogger(logFileName string) *bufio.Writer {
	if logFileName == "" {
		panic(fmt.Sprintln("Log file name is missing"))
	}

	logFile, err := os.OpenFile(logFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic(fmt.Sprintf("error when opening log file: %s; err: %s", logFileName, err.Error()))
	}

	return bufio.NewWriter(logFile)
}
