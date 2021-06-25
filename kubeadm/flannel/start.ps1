$ErrorActionPreference = "Stop";

ipmo hns.psm1
$network = Get-HNSNetwork | ? Name -eq "External"
if ($network -eq $null) {
  New-HNSNetwork -Type Overlay -AddressPrefix "192.168.255.0/30" -Gateway `
    "192.168.255.1" -Name "External" -AdapterName "Ethernet 2" -SubnetPolicies @(@{Type = "VSID"; VSID = 9999; }); `+
} elseif ($network.Type -ne "Overlay") {
  Write-Warning "'External' network already exists but has wrong type: $($network.Type)." 
}

Set-Content -Path /etc/cni/net.d/10-flannel.conf -value "test"

& flanneld.exe --kube-subnet-mgr --kubeconfig-file /etc/flannel/kubeconfig.yml

# configure cni
# $cniJson = get-content /etc/kube-flannel-windows/cni-conf.json | ConvertFrom-Json
# $serviceSubnet = get-content /etc/kubeadm-config/ClusterConfiguration | ForEach-Object -Process {if($_.Contains("serviceSubnet:")) {$_.Trim().Split()[1]}}
# $podSubnet = get-content /etc/kubeadm-config/ClusterConfiguration | ForEach-Object -Process {if($_.Contains("podSubnet:")) {$_.Trim().Split()[1]}}
# $cniJson.delegate.policies[0].Value.ExceptionList = $serviceSubnet, $podSubnet
# $cniJson.delegate.policies[1].Value.DestinationPrefix = $serviceSubnet
# Set-Content -Path /etc/cni/net.d/10-flannel.conf ($cniJson | ConvertTo-Json -depth 100)

# get correct service account and kubeconfigs
# cp -force /kube-proxy/kubeconfig.conf /host-etc-flannel/kubeconfig.yml
# cp -force /var/run/secrets/kubernetes.io/serviceaccount/* /host-etc-flannel/var/run/secrets/kubernetes.io/serviceaccount/

# todo?
#wins cli route add --addresses 169.254.169.254
