param(
    [string]$image = "sigwindowstools/kube-proxy",
    [switch]$push,
    [version]$minVersion = "1.17.0"
)

$output="docker"
if ($push.IsPresent) {
    $output="registry"
}

Import-Module "../buildx.psm1"
Set-Builder

function Build-KubeProxy([string]$version) 
{
    $config = Get-Content ".\buildconfig.json" | ConvertFrom-Json

    [string[]]$items = @()
    [string[]]$bases = @()
    foreach($tag in $config.tagsMap) 
    {
        $base = "$($config.baseimage):$($tag.source)"
        $current = "$($image):$($version)-$($tag.target)"
        $bases += $base
        $items += $current
        New-Build -name $current -output $output -args @("BASE=$base", "k8sVersion=$version")
    }

    if ($push.IsPresent)
    {
        Push-Manifest -name "$($image):$version-nanoserver" -items $items -bases $bases
    }
}

Build-KubeProxy -version "v1.22.0-alpha.1"