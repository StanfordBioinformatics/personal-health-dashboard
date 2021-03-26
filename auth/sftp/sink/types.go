package main

import (
	"time"
)

type CustomTime struct {
	time.Time
}

type LogEntry struct {
	ClientIP  string     `json:"client_ip"`
	UserName  string     `json:"username"`
	LoginType string     `json:"login_type"`
	Sender    string     `json:"sender"`
	Time      CustomTime `json:"time"`
}

func (ct *CustomTime) UnmarshalJSON(b []byte) (err error) {
	s := string(b)
	if len(s) > 0 && s[0] == '"' {
		s = s[1 : len(s)-1] // strip quotes
	}

	t, err := time.Parse(SftpGoDateFormat, s)
	if err != nil {
		t = time.Now()
	}
	ct.Time = t
	return
}
