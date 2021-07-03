$ErrorActionPreference = "Stop";

# # make sure external network exists to create switch for flannel otherwise it drops connection on 
# https://github.com/coreos/flannel/issues/1359
# https://github.com/kubernetes-sigs/sig-windows-tools/issues/103#issuecomment-709426828
ipmo $env:CONTAINER_SANDBOX_MOUNT_POINT/flannel/hns.psm1
$network = Get-HNSNetwork | ? Name -eq "External"
if ($network -eq $null) {
  New-HNSNetwork -Type Overlay -AddressPrefix "192.168.255.0/30" -Gateway "192.168.255.1" -Name "External" -AdapterName "Ethernet 3" -SubnetPolicies @(@{Type = "VSID"; VSID = 9999; });
} elseif ($network.Type -ne "Overlay") {
  Write-Warning "'External' network already exists but has wrong type: $($network.Type)." 
}

# flannel uses host-local for ipam so copy that to the correct location
Write-Host "copy cni bins"
cp -force -recurse $env:CONTAINER_SANDBOX_MOUNT_POINT/cni/* c:/opt/cni/bin

Write-Host "copy flannel config"
mkdir -force C:\etc\kube-flannel\
ls C:\etc\kube-flannel\
ls $env:CONTAINER_SANDBOX_MOUNT_POINT/etc/kube-flannel/
cp -force $env:CONTAINER_SANDBOX_MOUNT_POINT/etc/kube-flannel/net-conf.json  C:\etc\kube-flannel\net-conf.json

# configure cni
# get info
Write-Host "update cni config"
$cniJson = get-content $env:CONTAINER_SANDBOX_MOUNT_POINT/etc/kube-flannel-windows/cni-conf-containerd.json | ConvertFrom-Json
$serviceSubnet = get-content $env:CONTAINER_SANDBOX_MOUNT_POINT/etc/kubeadm-config/ClusterConfiguration | ForEach-Object -Process {if($_.Contains("serviceSubnet:")) {$_.Trim().Split()[1]}}
$podSubnet = get-content $env:CONTAINER_SANDBOX_MOUNT_POINT/etc/kubeadm-config/ClusterConfiguration | ForEach-Object -Process {if($_.Contains("podSubnet:")) {$_.Trim().Split()[1]}}
$na = @(Get-NetAdapter -Physical)
$managementIP = (Get-NetIPAddress -ifIndex $na[0].ifIndex -AddressFamily IPv4).IPAddress

#set info and save
$cniJson.delegate.AdditionalArgs[0].Value.Settings.Exceptions = $serviceSubnet, $podSubnet
$cniJson.delegate.AdditionalArgs[1].Value.Settings.DestinationPrefix = $serviceSubnet
$cniJson.delegate.AdditionalArgs[2].Value.Settings.ProviderAddress = $managementIP
Set-Content -Path c:/etc/cni/net.d/10-flannel.conf ($cniJson | ConvertTo-Json -depth 100)

# set route for metadata servers in clouds
# https://github.com/kubernetes-sigs/sig-windows-tools/issues/36
Write-Host "add route"
route /p add 169.254.169.254 mask 255.255.255.255 0.0.0.0

write-host "copy sa info (should be able to do this with a change to go client"
mkdir -force $env:CONTAINER_SANDBOX_MOUNT_POINT/flannel-config-file/var/run/secrets/kubernetes.io/serviceaccount/
cp -force $env:CONTAINER_SANDBOX_MOUNT_POINT/var/run/secrets/kubernetes.io/serviceaccount/* $env:CONTAINER_SANDBOX_MOUNT_POINT/flannel-config-file/var/run/secrets/kubernetes.io/serviceaccount/

Write-Host "Starting flannel"
& $env:CONTAINER_SANDBOX_MOUNT_POINT/flannel/flanneld.exe --kube-subnet-mgr --kubeconfig-file $env:CONTAINER_SANDBOX_MOUNT_POINT/flannel-config-file/kubeconfig.conf --iface "Ethernet 3"