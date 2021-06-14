package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"strings"

	"github.com/google/gopacket/routing"
)

func main() {
	ips := os.Args[1:]
	switch {
	case len(ips) == 0:
		log.Fatal("Expect exactly one argument")
	case len(ips) >= 2:
		log.Fatal("Expect only one argument")
	}

	rawIP := strings.Split(ips[0], "/")[0]

	ip := net.ParseIP(rawIP)
	if ip == nil {
		log.Fatal("failed to parse raw ip")
	}

	router, err := routing.New()
	if err != nil {
		log.Fatalf("failed to get new routing instance: %v", err.Error())
	}

	_, _, prefferedSrc, err := router.Route(ip)
	if err != nil {
		log.Fatalf("failed to find gateway for ip: %v", err.Error())
	}

	fmt.Fprintln(os.Stdout, prefferedSrc.String())
}
