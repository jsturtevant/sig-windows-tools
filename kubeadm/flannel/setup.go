package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"os/exec"
	"text/template"
)

type externalNetworkTemplate struct {
	AdapterName string
}

func setupOverlay(interfaceName string) {
	i, _ := url.QueryUnescape(interfaceName)
	externalNetworkTemplate := externalNetworkTemplate{AdapterName: i}
	t := template.Must(template.ParseFiles("CreateExternalNetwork.tmpl"))

	var templateBuffer bytes.Buffer
	err := t.Execute(&templateBuffer, &externalNetworkTemplate)
	if err != nil {
		log.Fatalf("Error generating template: %v", err)
	}

	run(templateBuffer.String())
}

func setupL2bridge(interfaceName string) {
	run(fmt.Sprintf(`ipmo C:\k\flannel\hns.psm1; New-HNSNetwork -Type Overlay -AddressPrefix "192.168.255.0/30"`+
		`-Gateway "192.168.255.1" -Name "External" -AdapterName "%s"`,
		interfaceName),
	)
}

func run(command string) {
	cmd := exec.Command("powershell", "-Command", command)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("Error running command: %v", err)
	}
}

func main() {
	mode := flag.String("mode", "", "Network mode: overlay or l2bridge")
	interfaceName := flag.String("interface", "", "Name of the network interface to use for Kubernetes networking")
	flag.Parse()

	switch *mode {
	case "overlay":
		setupOverlay(*interfaceName)
	case "l2bridge":
		setupL2bridge(*interfaceName)
	default:
		log.Fatalf("invalid mode %q. Options are 'overlay' and 'l2bridge'", *mode)
	}
}
