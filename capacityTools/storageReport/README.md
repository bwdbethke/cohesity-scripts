# Report Storage Consumption using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This PowerShell script reports per-job and per-view storage consumption. The script will generate an html report and send it to email recipients. Per-job abd per-view storage statistics are available in Cohesity 6.4 and later.

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Download Commands
$scriptName = 'storageReport'
$repoURL = 'https://raw.githubusercontent.com/bseltz-cohesity/scripts/master'
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/reports/powershell/$scriptName/$scriptName.ps1").content | Out-File "$scriptName.ps1"; (Get-Content "$scriptName.ps1") | Set-Content "$scriptName.ps1"
(Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/powershell/cohesity-api/cohesity-api.ps1").content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End Download Commands
```

## Components

* storageReport.ps1: the main PowerShell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place the files in a folder together and run the script like so:

```powershell
./storageReport.ps1 -vip mycluster `
                    -username myusername `
                    -domain mydomain.net `
                    -smtpServer 192.168.1.95 `
                    -sendTo myusername@mydomain.net `
                    -sendFrom mycluster@mydomain.net
```

## Parameters

* -vip: name or IP of Cohesity cluster
* -username: name of user to connect to Cohesity
* -domain: your AD domain (defaults to local)
* -useApiKey: (optional) Use API key for authentication
* -password: (optional) password or API key (will use stored password by default)
* -mfaCode: (optional) multi-factor authentication code
* -emailMfaCode: (optional) send mfaCode via email
* -unit: TiB, GiB, MiB or KiB
* -smtpServer: SMTP gateway to forward email through
* -smtpPort: SMTP port to use (default is 25)
* -sendTo: email addresses to send report to (comma separated)
* -sendFrom: email address to show in the from field
