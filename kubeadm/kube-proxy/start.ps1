# # Workaround for https://github.com/kubernetes/kubernetes/pull/68923 in < 1.14,
# # and https://github.com/kubernetes/kubernetes/pull/78612 for <= 1.15
# Import-Module $global:HNSModule
# Get-HnsPolicyList | Remove-HnsPolicyList
$ErrorActionPreference = "Stop";

function GetSourceVip($NetworkName)
{
        mkdir -force c:/sourcevip | Out-Null
        $sourceVipJson = [io.Path]::Combine("c:/", "sourcevip",  "sourceVip.json")
        $sourceVipRequest = [io.Path]::Combine("c:/", "sourcevip", "sourceVipRequest.json")

        if (Test-Path $sourceVipJson) {
                $sourceVipJSONData = Get-Content $sourceVipJson | ConvertFrom-Json
                $vip = $sourceVipJSONData.ip4.ip.Split("/")[0]
                return $vip
        }

        $hnsNetwork = Get-HnsNetwork | ? Name -EQ $NetworkName.ToLower()
        $subnet = $hnsNetwork.Subnets[0].AddressPrefix

        $ipamConfig = @"
        {"cniVersion": "0.2.0", "name": "flannel.4096", "ipam":{"type":"host-local","ranges":[[{"subnet":"$subnet"}]],"dataDir":"/var/lib/cni/networks"}}
"@

        Write-Host "ipam sourcevip request: $ipamConfig"
        $ipamConfig | Out-File $sourceVipRequest

        $env:CNI_COMMAND="ADD"
        $env:CNI_CONTAINERID="dummy"
        $env:CNI_NETNS="dummy"
        $env:CNI_IFNAME="dummy"
        $env:CNI_PATH="c:\opt\cni\bin" #path to host-local.exe

        Get-Content $sourceVipRequest | c:/opt/cni/bin/host-local.exe | Out-File $sourceVipJson

        
        Remove-Item env:CNI_COMMAND
        Remove-Item env:CNI_CONTAINERID
        Remove-Item env:CNI_NETNS
        Remove-Item env:CNI_IFNAME
        Remove-Item env:CNI_PATH
        
        $sourceVipJSONData = Get-Content $sourceVipJson | ConvertFrom-Json
        $vip = $sourceVipJSONData.ip4.ip.Split("/")[0]
        return $vip
}

Write-Host "Write files so the kubeconfig points to correct locations"
mkdir -force /var/lib/kube-proxy/
((Get-Content -path $env:CONTAINER_SANDBOX_MOUNT_POINT/var/lib/kube-proxy/kubeconfig.conf -Raw) -replace '/var',"$($env:CONTAINER_SANDBOX_MOUNT_POINT)/var") | Set-Content -Path $env:CONTAINER_SANDBOX_MOUNT_POINT/var/lib/kube-proxy/kubeconfig.conf
cp $env:CONTAINER_SANDBOX_MOUNT_POINT/var/lib/kube-proxy/kubeconfig.conf /var/lib/kube-proxy/kubeconfig.conf

Write-Host "Finding Network and sourcevip"
$networkName = (Get-Content c:/etc/cni/net.d/* | ConvertFrom-Json).name
$vip = GetSourceVip -NetworkName $networkName
Write-Host "sourceip: $vip"

$arguements = "--v=6",
        "--hostname-override=$env:NODE_NAME",
        "--feature-gates=WinOverlay=true,IPv6DualStack=false",
        "--proxy-mode=kernelspace",
        "--network-name=$networkName",
        "--source-vip=$vip",
        "--kubeconfig=$env:CONTAINER_SANDBOX_MOUNT_POINT/var/lib/kube-proxy/kubeconfig.conf"

$exe = "$env:CONTAINER_SANDBOX_MOUNT_POINT/kube-proxy/kube-proxy.exe " + ($arguements -join " ")

Write-Host "Starting $exe"
Invoke-Expression $exe


