[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip,
    [Parameter(Mandatory = $True)][string]$username,
    [Parameter()][string]$domain = 'local',
    [Parameter()][int64]$pageSize = 100
)

### source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

### authenticate
apiauth -vip $vip -username $username -domain $domain

$dateString = (get-date).ToString().Replace(' ','_').Replace('/','-').Replace(':','-')
$outfileName = "RecoveryPoints-$dateString.csv"
"Job Name,Job Type,Protected Object,Recovery Date,Local Expiry,Archival Expiry,Archive Target,Run URL" | Out-File -FilePath $outfileName

### find recoverable objects
$from = 0
$ro = api get "/searchvms?size=$pageSize&from=$from"

$environments = @('kUnknown', 'kVMware', 'kHyperV', 'kSQL', 'kView', 'kPuppeteer',
                'kPhysical', 'kPure', 'kAzure', 'kNetapp', 'kAgent', 'kGenericNas',
                'kAcropolis', 'kPhysicalFiles', 'kIsilon', 'kKVM', 'kAWS', 'kExchange',
                'kHyperVVSS', 'kOracle', 'kGCP', 'kFlashBlade', 'kAWSNative', 'kVCD',
                'kO365', 'kO365Outlook', 'kHyperFlex', 'kGCPNative', 'kAzureNative', 
                'kAD', 'kAWSSnapshotManager', 'kGPFS', 'kRDSSnapshotManager', 'kUnknown', 'kKubernetes',
                'kNimble', 'kAzureSnapshotManager', 'kElastifile', 'kCassandra', 'kMongoDB',
                'kHBase', 'kHive', 'kHdfs', 'kCouchbase', 'kUnknown', 'kUnknown', 'kUnknown')

if($ro.count -gt 0){

    while($True){
        $ro.vms | Sort-Object -Property {$_.vmDocument.jobName}, {$_.vmDocument.objectName } | ForEach-Object {
            $doc = $_.vmDocument
            $jobId = $doc.objectId.jobId
            $jobName = $doc.jobName
            $objName = $doc.objectName
            $objType = $environments[$doc.registeredSource.type]
            $objAlias = ''
            if('objectAliases' -in $doc.PSobject.Properties.Name){
                $objAlias = $doc.objectAliases[0]
                if($objAlias -eq "$objName.vmx" -or $objType -eq 'VMware'){
                    $objAlias = ''
                }
            }
            if($objAlias -ne ''){
                $objName = "$objName on $objAlias"
            }
            write-host ("`n{0} ({1}) {2}" -f $jobName, $objType, $objName) -ForegroundColor Green 
            $versionList = @()
            foreach($version in $doc.versions){
            # $doc.versions | ForEach-Object {  
                # $version = $_
                $runId = $version.instanceId.jobInstanceId
                $startTime = $version.instanceId.jobStartTimeUsecs
                $local = 0
                $remote = 0
                $remoteCluster = ''
                $archive = 0
                $archiveTarget = ''
                foreach($replica in $version.replicaInfo.replicaVec){
                    if($replica.target.type -eq 1){
                        $local = $replica.expiryTimeUsecs
                    }elseif($replica.target.type -eq 3) {
                        if($replica.expiryTimeUsecs -gt $archive){
                            $archive = $replica.expiryTimeUsecs
                            $archiveTarget = $replica.target.archivalTarget.name
                        }
                    }
                }
                $versionList += @{'RunDate' = $startTime; 'local' = $local; 'archive' = $archive; 'archiveTarget' = $archiveTarget; 'runId' = $runId; 'startTime' = $startTime}
            }
            write-host "`n`t             RunDate           SnapExpires        ArchiveExpires" -ForegroundColor Blue
            foreach($version in $versionList){
                if($version['local'] -eq 0){
                    $local = '-'
                }else{
                    $local = usecsToDate $version['local']
                }
                if($version['archive'] -eq 0){
                    $archive = '-'
                }else{
                    $archive = usecsToDate $version['archive']
                }
                $runDate = usecsToDate $version['RunDate']
                "`t{0,20}  {1,20}  {2,20}" -f $runDate, $local, $archive
                
                $runURL = "https://$vip/protection/job/$jobId/run/$($version['runId'])/$($version['startTime'])/protection"
                "$jobName,$objType,$objName,$runDate,$local,$archive,$($version['archiveTarget']),$runURL" | Out-File -FilePath $outfileName -Append
            }
        }
        if($ro.count -gt ($pageSize + $from)){
            $from += $pageSize
            $ro = api get "/searchvms?size=$pageSize&from=$from"
        }else{
            break
        }
    }
    write-host "`nReport Saved to $outFileName`n" -ForegroundColor Blue
}




