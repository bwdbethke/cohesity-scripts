# general params
$mcm = 'bseltz-mcm'
$sourceCluster = 'VE66b'
$targetCluster = 'VE66a'
$userName = 'admin'
$userDomain = 'local'
$policyName = 'replicate'

# DFS params
$dfsNameSpace = '\\sa.corp.cohesity.com\HA'

# DNS params
$cname = 'nas'
$cnameDomain = 'sa.corp.cohesity.com'

# using helios
# .\viewDR.ps1 -helios -targetCluster $targetCluster -username $userName -domain $userDomain -viewList .\myviews.txt -unplannedFailover
# using cluster direct
# .\viewDR.ps1 -targetCluster $targetCluster -username $userName -domain $userDomain -viewList .\myviews.txt -unplannedFailover
# using mcm
.\viewDR.ps1 -mcm $mcm -targetCluster $targetCluster -username $userName -domain $userDomain -viewList .\myviews.txt -unplannedFailover

# toggle dfs folder targets and/or cnames and SPNs
if(Test-Path -Path migratedShares.txt -PathType Leaf){
    .\dfsFailover.ps1 -nameSpace $dfsNameSpace -shareList .\migratedShares.txt -disableTarget "\\$sourceCluster" -enableTarget "\\$targetCluster"
    .\cnameFailover.ps1 -cname $cname -oldHost $sourceCluster -newHost $targetCluster -domain $cnameDomain
}

