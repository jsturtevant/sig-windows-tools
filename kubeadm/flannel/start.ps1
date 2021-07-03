$ErrorActionPreference = "Stop";

# # make sure external network exists to create switch for flannel otherwise it drops connection on 
# # https://github.com/coreos/flannel/issues/1359
# # https://github.com/kubernetes-sigs/sig-windows-tools/issues/103#issuecomment-709426828
# ipmo hns.psm1
# $network = Get-HNSNetwork | ? Name -eq "External"
# if ($network -eq $null) {
#   New-HNSNetwork -Type Overlay -AddressPrefix "192.168.255.0/30" -Gateway `
#     "192.168.255.1" -Name "External" -AdapterName "Ethernet 2" -SubnetPolicies @(@{Type = "VSID"; VSID = 9999; }); `+
# } elseif ($network.Type -ne "Overlay") {
#   Write-Warning "'External' network already exists but has wrong type: $($network.Type)." 
# }

# flannel uses host-local for ipam so copy that to the correct location
cp -force -recurse $env:CONTAINER_SANDBOX_MOUNT_POINT/cni/* c:/opt/cni/bin

# configure cni
# get info
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
route /p add 169.254.169.254 mask 255.255.255.255 0.0.0.0

& $env:CONTAINER_SANDBOX_MOUNT_POINT/flanneld.exe --kube-subnet-mgr --kubeconfig-file c:/k/kubeconfig.yml