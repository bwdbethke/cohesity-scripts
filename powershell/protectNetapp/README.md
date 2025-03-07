# Protect Netapp Volumes using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This PowerShell script creates a new protection job for Netapp volumes.

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Download Commands
$scriptName = 'protectNetapp'
$repoURL = 'https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/powershell'
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/$scriptName/$scriptName.ps1").content | Out-File "$scriptName.ps1"; (Get-Content "$scriptName.ps1") | Set-Content "$scriptName.ps1"
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands
```

## Components

* protectNetapp.ps1: the main PowerShell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place all files in a folder together. And run the script like so:

```powershell
# example
./protectNetapp.ps1 -vip mycluster `
                    -username myuser `
                    -domain mydomain.net `
                    -policyName 'My Policy' `
                    -jobName 'My New Job' `
                    -timeZone 'America/New_York' `
                    -enableIndexing `
                    -netappSource mynetapp `
                    -volumeName SVM0:vol1, SVM1:vol3 `
                    -cloudArchiveDirect
# end example
```

## Parameters

* -vip: name or IP of Cohesity cluster
* -username: name of user to connect to Cohesity
* -domain: your AD domain (defaults to local)
* -policyName: name of the protection policy to use
* -jobName: name of protection job
* -netappSource: name of registered Netapp source to protect

## Optional Prameters

* -startTime: (optional) e.g. '18:30' (defaults to 8PM)
* -volumeName: (optional) one or more volumes to protect (comma separated, default is all volumes)
* -volumeList: (optional) text file list of volumes to protect
* -inclusions: (optional) one or more inclusion paths (comma separated)
* -inclusionList: (optional) text file list of paths to include
* -exclusions: (optional) one or more exclusion paths (comma separated)
* -exclusionList: (optional) text file list of exclusion paths
* -timeZone: (optional) e.g. 'America/New_York' (default is 'America/Los_Angeles')
* -incrementalProtectionSlaTimeMins: (optional) default 60
* -fullProtectionSlaTimeMins: (optional) default is 120
* -enableIndexing: (optional) default is disabled
* -cloudArchiveDirect: (optional) default is false
* -storageDomainName: (optional) default is 'DefaultStorageDomain' (or 'Direct_Archive_Viewbox' for cloud archive direct jobs)

## Selecting Volumes

In the absense of any volume names or volume list provided in the command line, the entire netapp will be auto protected.

You can auto protect all volumes of an SVM by including it in the list of volumes to protect (e.g. `-volumeName SVM0`).

You can protect individual volumes by specifying SVM:volume (e.g. `-volumeName SVM0:vol1`)
