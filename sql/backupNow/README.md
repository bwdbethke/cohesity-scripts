# Backup Now Using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This PowerShell script performs a runNow on a protection job and optionally replicates and/or archives the backup to the specified targets. Also, the script will optionally enable a disabled job to run it, and disable it when done. The script will wait for the job to fimish and report the end status of the job.

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Download Commands
$scriptName = 'backupNow'
$repoURL = 'https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/powershell'
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/$scriptName/$scriptName.ps1").content | Out-File "$scriptName.ps1"; (Get-Content "$scriptName.ps1") | Set-Content "$scriptName.ps1"
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands
```

## Components

* backupNow.ps1: the main PowerShell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place all files in a folder together. then, run the main script like so:

```powershell
./backupNow.ps1 -vip mycluster `
                -username myusername `
                -domain mydomain.net `
                -jobName 'My Job'
```

## Authentication Parameters

* -vip: (optional) name or IP of Cohesity cluster (defaults to helios.cohesity.com)
* -username: (optional) name of user to connect to Cohesity (defaults to helios)
* -domain: (optional) your AD domain (defaults to local)
* -useApiKey: (optional) use API key for authentication
* -password: (optional) will use cached password or will be prompted
* -noPrompt: (optional) do not prompt for password
* -mcm: (optional) connect through MCM
* -mfaCode: (optional) TOTP MFA code
* -emailMfaCode: (optional) send MFA code via email
* -clusterName: (optional) cluster to connect to when connecting through Helios or MCM
* -tenant: (optional) org tenant to impersonate

## Job Run Parameters

* -jobName: name of protection job to run
* -backupType: (optional) choose one of kRegular, kFull, kLog or kSystem backup types. Default is kRegular (incremental)
* -metaDataFile: (optional) path of directive file to use on server
* -objects: (optional) comma separated list of object names to include in the job run. For VMs, simply include the VM name. For SQL databases, object names should be in the form of server.mydomain.net/instanceName/dbName. For Oracle databases, object names should be in the form of server.mydomain.net/dbName

## Copy Retention Parameters

* -localOnly: (optional) skip replicas and archivals
* -keepLocalFor: (optional) days to keep local snapshot (default is to use policy setting)
* -noArchive: (optional) skip archive tasks
* -archiveTo: (optional) name of archival target to archive to (default is to use policy setting)
* -keepArchiveFor: (optional) days to keep in archive (default is to use policy setting)
* -noReplica: (optional) skip replication tasks
* -replicateTo: (optional) name of remote cluster to replicate to (default is to use policy setting)
* -keepReplicaFor: (optional) days to keep replica for (default is to use policy setting)

## Other Runtime Parameters

* -sleepTimeSecs: (optional) seconds to sleep between status queries (default is 30)
* -progress: (optional) display percent complete
* -wait: (optional) wait for job to complete and return exit code, otherwise exit immediately after starting the job
* -abortIfRunning: (optional) exit if job is already running (default is to wait and run when existing run is finished)
* -outputlog: (optional) enable output logging
* -logfile: (optional) path/name of log file (default is ./log-backupNow.log)
* -waitMinutesIfRunning: (optional) exit after X minutes if job is already running (default is 60)
* -waitForNewRunMinutes: (optional) exit after X minutes if new run fails to appear (Default is 10)
* -cancelPreviousRunMinutes: (optional) cancel previous job run if it has been running for X minutes
* -statusRetries: (optional) quit script with failure if unable to get status X times (default is 10)
* -extendedErrorCodes: (optional) return extended set of exit codes (see below) by default 0 = successful, 1 = not successful

## Extended Error Codes

* 0: Successful (no error to report)
* 1: Unsuccessful (backup ended in failure or warning)
* 2: authentication error (failed to authenticate)
* 3: Syntax Error (incorrect command line)
* 4: Timed out waiting for existing run to finish (existing run still running)
* 5: Timed out waiting for status update (failed to get status updates)
