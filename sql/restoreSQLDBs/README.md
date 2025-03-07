# Restore Multiple SQL Databases Using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This script restores one or more (or all) databases from the specified SQL server (not including the system databases).  

## Warning

This script can overwrite production data if you ask it to. Make sure you know what you are doing and test thoroughly before using in production!!!

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Download Commands
$scriptName = 'restoreSQLDBs'
$repoURL = 'https://raw.githubusercontent.com/bseltz-cohesity/scripts/master'
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/sql/$scriptName/$scriptName.ps1").content | Out-File "$scriptName.ps1"; (Get-Content "$scriptName.ps1") | Set-Content "$scriptName.ps1"
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/powershell/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands
```

## Components

* restoreSQLDBs.ps1: the main powershell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

```powershell
./restoreSQLDBs.ps1 -vip mycluster `
                    -username myusername `
                    -domain mydomain.net `
                    -sourceServer sqlserver1.mydomain.net `
                    -allDBs `
                    -overWrite `
                    -latest
```

## Authentication Parameters

* -vip: (optional) name or IP of Cohesity cluster (defaults to helios.cohesity.com)
* -username: (optional) name of user to connect to Cohesity (defaults to helios)
* -domain: (optional) your AD domain (defaults to local)
* -useApiKey: (optional) use API key for authentication
* -password: (optional) will use cached password or will be prompted
* -noPrompt: (optional) do not prompt for password
* -tenant: (optional) organization to impersonate
* -mcm: (optional) connect through MCM
* -mfaCode: (optional) TOTP MFA code
* -emailMfaCode: (optional) send MFA code via email
* -clusterName: (optional) cluster to connect to when connecting through Helios or MCM

## Basic Parameters

* -sourceServer: Server name (or AAG name) where the database was backed up

## Source DB Selections

* -sourceDBnames: (optional) Databases to restore (e.g. MyDB or MYINSTANCE/MyDB) comma separated list
* -sourceDBList: (optional) Text file containing databases to restore (e.g. MyDB or MYINSTANCE/MyDB)
* -sourceInstance: (optional) Name of source SQL instance to restore from
* -allDBs: (optional) restore all databases from specified server/instance
* -includeSystemDBs: (optional) also restore system DBs (master, model, msdb)

## Point in Time Selections

* -logTime: Point in time to replay the logs to during the restore (e.g. '2019-04-10 22:31:05')
* -latest: Replay the logs to the latest log backup date
* -noStop: Replay the logs to the last transaction available

## Target Parameters

* -prefix: (optional) Prefix to apply to database names (e.g. 'Dev-')
* -suffix: (optional) Suffix to apply to database names (e.g. '-Dev')
* -targetServer: (optional) Server name to restore to (defaults to same as sourceServer)
* -targetInstance: (optional) SQL instance to restore to (defaults to MSSQLSERVER)
* -mdfFolder: (optional) Location to place the primary data file (e.g. C:\SQLData)
* -ldfFolder: Location to place the log files (defaults to same as mdfFolder)
* -ndfFolders: Locations to place various ndf files (see below)
* -overwrite: Overwrites an existing database (default is no overwrite)
* -noRecovery: Restore the DB with NORECOVER option (default is to recover)
* -showPaths: show data/log file paths and exit
* -useSourcePaths: use same paths to restore to target server
* -exportFileInfo: export DB file path info and exit (file name is sourceserver.json)
* -importFileInfo: import DB file path info (use in conjunction with -useSourcePaths)
* -forceAlternateLocation: populate alternate location params even when target server name is the same

## Misc Parameters

* -wait: Wait for the restore to complete and report end status (e.g. kSuccess)
* -progress: (optional) display percent complete

## Always On Availability Groups

Use the **AAG name** as the **-sourceServer** when restoring from an AAG backup (e.g. -sourceServer myAAG1)

## Overwrite Warning

Including the **-overwrite** parameter will overwrite an existing database. Use this parameter with extreme caution.

## Multiple Folders for Secondary NDF Files

```powershell
-ndfFolders @{'*1.ndf'='E:\sqlrestore\ndf1'; '*2.ndf'='E:\sqlrestore\ndf2'}
```

## Point in Time Recovery

If you want to replay the logs to the very latest available point in time, use the **-latest** parameter.

Or, if you want to replay logs to a specific point in time, use the **-logTime** parameter and specify a date and time in military format like so:

```powershell
-logTime '2019-01-20 23:47:02'
```

Note that when the -logTime parameter is used with databases where no log backups exist, the full/incremental backup that occured at or before the specified log time will be used.
