### usage: .\viewDRcollect.ps1 -vip mycluster -username myusername [ -domain mydomain.net ] -inPath \\myserver\mypath

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip,
    [Parameter(Mandatory = $True)][string]$username,
    [Parameter()][string]$domain = 'local',
    [Parameter(Mandatory = $True)][string]$outPath
)

### source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

### authenticate
apiauth -vip $vip -username $username -domain $domain

### cluster info
$clusterName = (api get cluster).name

### get views
$views = api get views

if(test-path $outPath){
    $clusterOutPath = Join-Path -Path $outPath -ChildPath $clusterName
    if(! (Test-Path -PathType Container -Path $clusterOutPath)){
        $null = New-Item -ItemType Directory -Path $clusterOutPath -Force
    }
    write-host "Saving view metadata to $clusterOutPath"
}else{
    Write-Warning "$outPath not accessible"
    exit
}

foreach($view in $views.views){
    $filePath = Join-Path -Path $clusterOutPath -ChildPath $view.name
    $view | ConvertTo-Json -Depth 99 | Out-File $filePath
}
