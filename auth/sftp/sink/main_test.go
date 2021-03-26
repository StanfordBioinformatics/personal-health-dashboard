package main

import (
	"bytes"
	"fmt"
	"testing"
	"time"
)

func TestProcessLogLine_New_ConnectionFailedSender_LogsEntry(t *testing.T) {
	var buffer bytes.Buffer
	time := time.Now().UTC().Add(LogSinceThreshold + 10 * time.Second)
	logEntry := getLogEntry(time, ConnectionFailed)
	processLogLine(logEntry, &buffer)

	expectedLogEntry := fmt.Sprintf("%s Connection failed with error password from: 1.1.1.1\n", time.Format(Fail2BanDateFormat))
	actualLogEntry := buffer.String()
	if actualLogEntry != expectedLogEntry {
		t.Errorf("Expected %s and got %s", expectedLogEntry, actualLogEntry)
	}
}

func TestProcessLogLine_Old_ConnectionFailedSender_NoEntry(t *testing.T) {
	var buffer bytes.Buffer
	logEntry := getLogEntry(time.Now().UTC().Add(LogSinceThreshold), ConnectionFailed)
	processLogLine(logEntry, &buffer)

	if buffer.String() != "" {
		t.Errorf("Should not have written an entry for old log")
	}
}

func TestProcessLogLine_New_SftpdSender_NoEntry(t *testing.T) {
	var buffer bytes.Buffer
	logEntry := getLogEntry(time.Now().UTC().Add(LogSinceThreshold), "sftpd")
	processLogLine(logEntry, &buffer)

	if buffer.String() != "" {
		t.Errorf("Should not have written an entry for old log")
	}
}


func getLogEntry(time time.Time, sender string) string {
	return fmt.Sprintf(`{
		"level":"debug",
		"time":"%s",
		"sender":"%s",
		"client_ip":"1.1.1.1",
		"username":"random_attacker",
		"login_type":"password",
		"error":"EOF"
	}`, time.Format(SftpGoDateFormat), sender)
}