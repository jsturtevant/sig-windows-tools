$ErrorActionPreference = "Stop";

$sourcevip = get-content c:/sourcevip/sourcevip.txt
Write-Host "sourceip: $sourcevip"
Write-Host "Running kub-proxy service $args"

$exe = ".\kube-proxy.exe $args --source-vip=$sourcevip"
write-host "Running $exe"
Invoke-Expression $exe