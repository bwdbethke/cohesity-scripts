# Generate a Cluster Wide Capacity Report Using Python

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This script reports cluster-wide storage growth over time.

## Download the script

You can download the scripts using the following commands:

```bash
# download commands
curl -O https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/reports/python/storageGrowth/storageGrowth.py
curl -O https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/python/pyhesity.py
chmod +x storageGrowth.py
# end download commands
```

## Components

* storageGrowth.py: the main powershell script
* pyhesity.py: the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

```bash
./storageGrowth.py -v mycluster \
                   -u myusername \
                   -d mydomain.net
```

## Parameters

* -v, --vip: DNS or IP of the Cohesity cluster to connect to
* -u, --username: username to authenticate to Cohesity cluster
* -d, --domain: (optional) domain of username, defaults to local
* -i, --useApiKey: (optional) use API key for authentication
* -pwd: --password: (optional) use password from command line instead of stored password
* -of: --outfolder: (optional) where to write report html (default is current directory)
* -x: --days: (optional) limit report to the last X days (default is since cluster creation)
