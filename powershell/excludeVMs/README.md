# Exclude VMs froma Cohesity Protection Job using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This powershell script excludes one or more VMs from an existing protection job where parent containers are autoprotected.

Note: This script is to be used with Cohesity versions 6.5.1 or later. For versions prior to 6.5.1, please use this version: <https://github.com/bseltz-cohesity/scripts/tree/master/powershell/excludeVMsV1>

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Download Commands
$scriptName = 'excludeVMs'
$repoURL = 'https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/powershell'
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/$scriptName/$scriptName.ps1").content | Out-File "$scriptName.ps1"; (Get-Content "$scriptName.ps1") | Set-Content "$scriptName.ps1"
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands
```

## Components

* excludeVMs.ps1: the main powershell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

```powershell
./excludeVMs.ps1 -vip mycluster -username admin -jobName 'vm backup' -vmName mongodb
```

## Parameters

* -vip: name or IP of Cohesity cluster
* -username: name of user to connect to Cohesity
* -domain: (optional) your AD domain (defaults to local)
* -vmName: (optional) one or more VMs to exclude the proctection job (comma separated)
* -vmList: (optional) text file containing list of VMs to exclude (one per line)
* -jobName: (optional) one or more protection jobs to process (default is all VMware jobs)
