# process commandline arguments
[CmdletBinding()]
param (
    [Parameter()][string]$vip='helios.cohesity.com',
    [Parameter()][string]$username = 'helios',
    [Parameter()][string]$domain = 'local',
    [Parameter()][string]$tenant,
    [Parameter()][switch]$useApiKey,
    [Parameter()][string]$password,
    [Parameter()][switch]$noPrompt,
    [Parameter()][switch]$mcm,
    [Parameter()][string]$mfaCode,
    [Parameter()][switch]$emailMfaCode,
    [Parameter()][string]$clusterName,
    [Parameter(Mandatory = $True)][string]$jobName,
    [Parameter()][array]$serverName,
    [Parameter()][string]$serverList,  # optional textfile of servers to protect
    [Parameter()][array]$instanceName,
    [Parameter()][ValidateSet('File','Volume','VDI')][string]$backupType = 'File',
    [Parameter()][switch]$instancesOnly,
    [Parameter()][switch]$systemDBsOnly,
    [Parameter()][string]$policyname,
    [Parameter()][string]$startTime = '20:00', # e.g. 23:30 for 11:30 PM
    [Parameter()][string]$timeZone = 'America/Los_Angeles', # e.g. 'America/New_York'
    [Parameter()][int]$incrementalProtectionSlaTimeMins = 60,
    [Parameter()][int]$fullProtectionSlaTimeMins = 120,
    [Parameter()][string]$storageDomainName = 'DefaultStorageDomain', #storage domain you want the new job to write to
    [Parameter()][switch]$paused,
    [Parameter()][int]$numStreams = 3,
    [Parameter()][string]$withClause = ''
)

# gather list from command line params and file
function gatherList($Param=$null, $FilePath=$null, $Required=$True, $Name='items'){
    $items = @()
    if($Param){
        $Param | ForEach-Object {$items += $_}
    }
    if($FilePath){
        if(Test-Path -Path $FilePath -PathType Leaf){
            Get-Content $FilePath | ForEach-Object {$items += [string]$_}
        }else{
            Write-Host "Text file $FilePath not found!" -ForegroundColor Yellow
            exit
        }
    }
    if($Required -eq $True -and $items.Count -eq 0){
        Write-Host "No $Name specified" -ForegroundColor Yellow
        exit
    }
    return ($items | Sort-Object -Unique)
}

$serversToAdd = @(gatherList -Param $serverName -FilePath $serverList -Name 'sources' -Required $True)

# source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

# authenticate
apiauth -vip $vip -username $username -domain $domain -passwd $password -apiKeyAuthentication $useApiKey -mfaCode $mfaCode -sendMfaCode $emailMfaCode -heliosAuthentication $mcm -regionid $region -tenant $tenant -noPromptForPassword $noPrompt

# select helios/mcm managed cluster
if($USING_HELIOS -and !$region){
    if($clusterName){
        $thisCluster = heliosCluster $clusterName
    }else{
        write-host "Please provide -clusterName when connecting through helios" -ForegroundColor Yellow
        exit 1
    }
}

if(!$cohesity_api.authorized){
    Write-Host "Not authenticated"
    exit 1
}

$systemDBs = @('master', 'model', 'msdb')

# root SQL source
$sources = api get protectionSources?environments=kSQL

# get the protectionJob
$job = (api get -v2 data-protect/protection-groups).protectionGroups | Where-Object name -eq $jobName
$newJob = $false

if(! $job){
    # create new job
    Write-Host "Creating job $jobName..."
    $newJob = $True

    if($paused){
        $isPaused = $True
    }else{
        $isPaused = $false
    }

    $backupTypeEnum = @{'File' = 'kFile'; 'Volume' = 'kVolume'; 'VDI' = 'kNative'}

    # get policy
    if(! $policyname){
        Write-Host "-policyname required when creating a new job" -ForegroundColor Yellow
        exit 1
    }
    $policy = (api get -v2 "data-protect/policies").policies | Where-Object name -eq $policyName
    if(! $policy){
        Write-Host "Policy $policyname not found!" -ForegroundColor Yellow
        exit 1
    }

    # parse startTime
    $hour, $minute = $startTime.split(':')
    $tempInt = ''
    if(! (($hour -and $minute) -or ([int]::TryParse($hour,[ref]$tempInt) -and [int]::TryParse($minute,[ref]$tempInt)))){
        Write-Host "Please provide a valid start time" -ForegroundColor Yellow
        exit
    }

    # get storageDomain
    $viewBoxes = api get viewBoxes
    if($viewBoxes -is [array]){
        $viewBox = $viewBoxes | Where-Object { $_.name -ieq $storageDomainName }
        if (!$viewBox) { 
            write-host "Storage domain $storageDomainName not Found" -ForegroundColor Yellow
            exit
        }
    }else{
        $viewBox = $viewBoxes[0]
    }

    $job = @{

        "name" = $jobName;
        "policyId" = $policy.id;
        "priority" = "kMedium";
        "storageDomainId" = $viewBox.id;
        "description" = "";
        "startTime" = @{
            "hour" = [int]$hour;
            "minute" = [int]$minute;
            "timeZone" = $timeZone
        };
        "alertPolicy" = @{
            "backupRunStatus" = @(
                "kFailure"
            );
            "alertTargets" = @()
        };
        "sla" = @(
            @{
                "backupRunType" = "kIncremental";
                "slaMinutes" = $incrementalProtectionSlaTimeMins
            };
            @{
                "backupRunType" = "kFull";
                "slaMinutes" = $fullProtectionSlaTimeMins
            }
        );
        "qosPolicy" = "kBackupHDD";
        "abortInBlackouts" = $false;
        "isActive" = $true;
        "isPaused" = $isPaused;
        "environment" = "kSQL";
        "permissions" = @();
        "missingEntities" = $null;
        "mssqlParams" = @{
            "protectionType" = $backupTypeEnum[$backupType];
        }
    }
    
    if($backupType -eq 'File'){
        $job.mssqlParams['fileProtectionTypeParams'] = @{
            "objects" = @();
            "performSourceSideDeduplication" = $false;
            "additionalHostParams" = @();
            "userDbBackupPreferenceType" = "kBackupAllDatabases";
            "backupSystemDbs" = $true;
            "useAagPreferencesFromServer" = $true;
            "fullBackupsCopyOnly" = $false;
            "excludeFilters" = $null
        }
        $params = $job.mssqlParams.fileProtectionTypeParams
    }

    if($backupType -eq 'VDI'){
        $job.mssqlParams['nativeProtectionTypeParams'] = @{
            "objects" = @();
            "numStreams" = $numStreams;
            "withClause" = $withClause;
            "userDbBackupPreferenceType" = "kBackupAllDatabases";
            "backupSystemDbs" = $true;
            "useAagPreferencesFromServer" = $true;
            "fullBackupsCopyOnly" = $false;
            "excludeFilters" = $null
        }
        $params = $job.mssqlParams.nativeProtectionTypeParams
    }

    if($backupType -eq 'Volume'){
        $job.mssqlParams['volumeProtectionTypeParams'] = @{
            "objects" = @();
            "incrementalBackupAfterRestart" = $true;
            "indexingPolicy" = @{
                "enableIndexing" = $true;
                "includePaths" = @(
                    "/"
                );
                "excludePaths" = @(
                    '/$Recycle.Bin';
                    "/Windows";
                    "/Program Files";
                    "/Program Files (x86)";
                    "/ProgramData";
                    "/System Volume Information";
                    "/Users/*/AppData";
                    "/Recovery";
                    "/var";
                    "/usr";
                    "/sys";
                    "/proc";
                    "/lib";
                    "/grub";
                    "/grub2";
                    "/opt/splunk";
                    "/splunk"
                )
            };
            "backupDbVolumesOnly" = $false;
            "additionalHostParams" = @();
            "userDbBackupPreferenceType" = "kBackupAllDatabases";
            "backupSystemDbs" = $true;
            "useAagPreferencesFromServer" = $true;
            "fullBackupsCopyOnly" = $false;
            "excludeFilters" = $null
        }
        $params = $job.mssqlParams.volumeProtectionTypeParams
    }
}else{
    Write-Host "Updating job $jobname..."
    if($job.mssqlParams.protectionType -eq 'kFile'){
        $params = $job.mssqlParams.fileProtectionTypeParams
    }

    if($job.mssqlParams.protectionType -eq 'kNative'){
        $params = $job.mssqlParams.nativeProtectionTypeParams
    }

    if($job.mssqlParams.protectionType -eq 'kVolume'){
        $params = $job.mssqlParams.volumeProtectionTypeParams
    }
}

# server source
foreach($servername in $serversToAdd){
    $serverSource = $sources[0].nodes | Where-Object {$_.protectionSource.name -eq $servername}
    if(! $serverSource){
        Write-Host "Server $servername not found!" -ForegroundColor Yellow
        Write-Host "Make sure to enter the server name exactly as listed in Cohesity" -ForegroundColor Yellow
        exit 1
    }
    
    if($instanceName.Count -eq 0 -and $instancesOnly){
        foreach($instanceId in $serverSource.applicationNodes.protectionSource.id){
            $params.objects = @($params.objects + @{ 'id' = $instanceId})
        }
    }elseif($instanceName.Count -gt 0){
        foreach($instance in $instanceName){
            $instanceSource = $serverSource.applicationNodes | Where-Object {$_.protectionSource.name -eq $instance}
            if(! $instanceSource){
                Write-Host "Instance $instance not found on server $servername"
                exit
            }else{
                if($systemDBsOnly){
                    foreach($node in $instanceSource.nodes){
                        if(($node.protectionSource.name -split '/')[1] -in $systemDBs){
                            $params.objects = @($params.objects + @{ 'id' = $node.protectionSource.id})
                        }
                    }
                }else{
                    $params.objects = @($params.objects + @{ 'id' = $instanceSource.protectionSource.id})
                }
            }
        }
    }else{
        if($systemDBsOnly){
            foreach($instanceSource in $serverSource.applicationNodes){
                foreach($node in $instanceSource.nodes){
                    if(($node.protectionSource.name -split '/')[1] -in $systemDBs){
                        $params.objects = @($params.objects + @{ 'id' = $node.protectionSource.id})
                    }
                }
            }
        }else{
            $params.objects = @($params.objects + @{ 'id' = $serverSource.protectionSource.id})
        }
    }
    Write-Host "Protecting $servername..."
}

if($newJob -eq $True){
    $createdJob = api post -v2 data-protect/protection-groups $job
}else{
    $null = api put -v2 data-protect/protection-groups/$($job.id) $job 
}
