# Workaround for https://github.com/kubernetes/kubernetes/pull/68923 in < 1.14,
# and https://github.com/kubernetes/kubernetes/pull/78612 for <= 1.15
Import-Module $global:HNSModule
Get-HnsPolicyList | Remove-HnsPolicyList

$networkName = (Get-Content /etc/cni/net.d/* | ConvertFrom-Json).name
$sourceVip = ($env:POD_IP -split "\.")[0..2] + 0 -join "."

$arguements = "--v=6",
        "--hostname-override=$env:NODE_NAME",
        "--feature-gates=WinOverlay=true,IPv6DualStack=false",
        "--proxy-mode=kernelspace",
        "--network-name=$networkName",
        "--source-vip=$sourceVip"

$exe = "./kube-proxy.exe " + ($arguements -join " ")

Invoke-Expression $exe