# version 2022.06.08
# usage: ./backedUpFileList.ps1 -vip mycluster \
#                               -username myuser \
#                               -domain mydomain.net \
#                               -sourceServer server1.mydomain.net \
#                               -jobName myjob \
#                               [ -showVersions ]
#                               [ -runId 123456 ] 
#                               [ -fileDate '2020-06-29 12:00:00' ]

### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$vip, # the cluster to connect to (DNS name or IP)
    [Parameter()][string]$username='helios', # username (local or AD)
    [Parameter()][string]$domain = 'local', # local or AD domain
    [Parameter()][switch]$useApiKey, # use API key for authentication
    [Parameter()][string]$password = $null,
    [Parameter(Mandatory = $True)][string]$sourceServer, # source server
    [Parameter(Mandatory = $True)][string]$jobName, # narrow search by job name
    [Parameter()][switch]$showVersions,
    [Parameter()][switch]$listFiles,
    [Parameter()][datetime]$start,
    [Parameter()][datetime]$end,
    [Parameter()][Int64]$runId,
    [Parameter()][datetime]$fileDate,
    [Parameter()][string]$startPath = '/',
    [Parameter()][switch]$noIndex,
    [Parameter()][switch]$showStats,
    [Parameter()][Int64]$newerThan = 0
)

if($noIndex){
    $useLibrarian = $False
}else{
    $useLibrarian = $True
}

if($showStats -or $newerThan -gt 0){
    $statfile = $True
}else{
    $statfile = $False
}

$daysAgo = (get-Date).AddDays(-$newerThan)

$volumeTypes = @(1, 6)

### source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

### authenticate
if($useApiKey){
    apiauth -vip $vip -username $username -domain $domain -useApiKey -password $password
}else{
    apiauth -vip $vip -username $username -domain $domain -password $password
}

function listdir($dirPath, $instance, $volumeInfoCookie=$null, $volumeName=$null, $cookie=$null){
    $thisDirPath = [System.Web.HttpUtility]::UrlEncode($dirPath).Replace('%2f%2f','%2F')
    if($cookie){
        if($null -ne $volumeName){
            $dirList = api get "/vm/directoryList?$instance&useLibrarian=$useLibrarian&statFileEntries=$statfile&volumeInfoCookie=$volumeInfoCookie&cookie=$cookie&volumeName=$volumeName&dirPath=$thisDirPath"
        }else{
            $dirList = api get "/vm/directoryList?$instance&useLibrarian=$useLibrarian&statFileEntries=$statfile&cookie=$cookie&dirPath=$thisDirPath"
        }
    }else{
        if($null -ne $volumeName){
            $dirList = api get "/vm/directoryList?$instance&useLibrarian=$useLibrarian&statFileEntries=$statfile&volumeInfoCookie=$volumeInfoCookie&volumeName=$volumeName&dirPath=$thisDirPath"
        }else{
            $dirList = api get "/vm/directoryList?$instance&useLibrarian=$useLibrarian&statFileEntries=$statfile&dirPath=$thisDirPath"
        }
    }
    if($dirList.PSObject.Properties['entries'] -and $dirList.entries.Count -gt 0){
        $Global:filesFound = $True
        foreach($entry in $dirList.entries | Sort-Object -Property name){
            if($entry.type -eq 'kDirectory'){
                listdir "$dirPath/$($entry.name)" $instance $volumeInfoCookie $volumeName
            }else{
                if($statfile){
                    $filesize = $entry.fstatInfo.size
                    $mtime = usecsToDate $entry.fstatInfo.mtimeUsecs
                    if($mtime -ge $daysAgo -or $newerThan -eq 0){
                        "{0} ({1}) [{2} bytes]" -f $entry.fullPath, $mtime, $filesize | Tee-Object -FilePath $outputfile -Append
                    }
                }else{
                    "{0}" -f $entry.fullPath | Tee-Object -FilePath $outputfile -Append  
                }
            }
        }
    }
    if($dirlist.PSObject.Properties['cookie']){
        listdir "$dirPath" $instance $volumeInfoCookie $volumeName $dirlist.cookie
    }
}

function showFiles($doc, $version){
    if($newerThan -gt 0){
        Write-Host "`nSearching for files added/modified in the past $newerThan days...`n"
    }
    $Global:filesFound = $False
    $versionDate = (usecsToDate $version.instanceId.jobStartTimeUsecs).ToString('yyyy-MM-dd_hh-mm-ss')
    $sourceServerString = $sourceServer.Replace('\','-').Replace('/','-')
    $outputfile = $(Join-Path -Path $PSScriptRoot -ChildPath "backedUpFiles-$($version.instanceId.jobInstanceId)-$($sourceServerString)-$versionDate.txt")
    $null = Remove-Item -Path $outputfile -Force -ErrorAction SilentlyContinue
    
    $instance = "attemptNum={0}&clusterId={1}&clusterIncarnationId={2}&entityId={3}&jobId={4}&jobInstanceId={5}&jobStartTimeUsecs={6}&jobUidObjectId={7}" -f
                $version.instanceId.attemptNum,
                $doc.objectId.jobUid.clusterId,
                $doc.objectId.jobUid.clusterIncarnationId,
                $doc.objectId.entity.id,
                $doc.objectId.jobId,
                $version.instanceId.jobInstanceId,
                $version.instanceId.jobStartTimeUsecs,
                $doc.objectId.jobUid.objectId
    
    $backupType = $doc.backupType
    if($backupType -in $volumeTypes){
        $volumeList = api get "/vm/volumeInfo?$instance&statFileEntries=$statfile"
        if($volumeList.PSObject.Properties['volumeInfos']){
            $volumeInfoCookie = $volumeList.volumeInfoCookie
            foreach($volume in $volumeList.volumeInfos | Sort-Object -Property name){
                $volumeName = [System.Web.HttpUtility]::UrlEncode($volume.name)
                listdir $startPath $instance $volumeInfoCookie $volumeName
            }
        }
    }else{
        listdir $startPath $instance
    }
    if($Global:filesFound -eq $False){
        "No Files Found" | Tee-Object -FilePath $outputfile -Append
    }
}

$searchResults = api get "/searchvms?entityTypes=kView&entityTypes=kAcropolis&entityTypes=kAWS&entityTypes=kAWSNative&entityTypes=kAWSSnapshotManager&entityTypes=kAzure&entityTypes=kAzureNative&entityTypes=kFlashBlade&entityTypes=kGCP&entityTypes=kGenericNas&entityTypes=kHyperV&entityTypes=kHyperVVSS&entityTypes=kIsilon&entityTypes=kKVM&entityTypes=kNetapp&entityTypes=kPhysical&entityTypes=kVMware&vmName=$sourceserver"
$searchResults = $searchResults.vms | Where-Object {$_.vmDocument.objectName -eq $sourceServer}

if(!$searchResults){
    Write-Host "no backups found for $sourceServer" -ForegroundColor Yellow
    exit 1
}

# narrow search by job name
$altJobName = "Old Name: $jobName"
$altJobName2 = "$jobName \(Old Name:"
$searchResults = $searchResults | Where-Object {($_.vmDocument.jobName -eq $jobName) -or ($_.vmDocument.jobName -match $altJobName) -or ($_.vmDocument.jobName -match $altJobName2)}

if(!$searchResults){
    Write-Host "$sourceServer is not protected by $jobName" -ForegroundColor Yellow
    exit 1
}

$searchResult = ($searchResults | sort-object -property @{Expression={$_.vmDocument.versions[0].snapshotTimestampUsecs}; Ascending = $False})[0]

$doc = $searchResult.vmDocument

# show versions
if($showVersions -or $start -or $end -or $listFiles){
    if($start){
        $doc.versions = $doc.versions | Where-Object {$start -le (usecsToDate ($_.snapshotTimestampUsecs))}
    }
    if($end){
        $doc.versions = $doc.versions | Where-Object {$end -ge (usecsToDate ($_.snapshotTimestampUsecs))}
    }
    if($listFiles){
        foreach($version in $doc.versions){
            Write-Host "`n=============================="
            Write-Host "   runId: $($version.instanceId.jobInstanceId)"
            write-host " runDate: $(usecsToDate $version.instanceId.jobStartTimeUsecs)"
            Write-Host "==============================`n"
            if($version.numEntriesIndexed -eq 0){
                $useLibrarian = $False
            }
            showFiles $doc $version
        }
    }else{
        $doc.versions | Select-Object -Property @{label='runId'; expression={$_.instanceId.jobInstanceId}}, @{label='runDate'; expression={usecsToDate $_.instanceId.jobStartTimeUsecs}}
    }
    exit 0
}

$Global:filesFound = $False

# select version
if($runId){
    # select version with matching runId
    $version = ($doc.versions | Where-Object {$_.instanceId.jobInstanceId -eq $runId})
    if(! $version){
        Write-Host "Job run ID $runId not found" -ForegroundColor Yellow
        exit 1
    }
    if($version.numEntriesIndexed -eq 0){
        $useLibrarian = $False
    }
    showFiles $doc $version
}elseif($fileDate){
    # select version just after requested date
    $version = ($doc.versions | Where-Object {$fileDate -le (usecsToDate ($_.snapshotTimestampUsecs))})[-1]
    if(! $version){
        $version = $doc.versions[0]
    }
    if($version.numEntriesIndexed -eq 0){
        $useLibrarian = $False
    }
    showFiles $doc $version
}else{
    # just use latest version
    $version = $doc.versions[0]
    if($version.numEntriesIndexed -eq 0){
        $useLibrarian = $False
    }
    showFiles $doc $version
}
