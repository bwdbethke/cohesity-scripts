# Manage Global White List using Python

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This python script adds, removes and lists global white list entries

## Download the script

Run these commands to download the scripts into your current directory

```bash
curl -O https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/python/globalWhiteList/globalWhiteList.py
curl -O https://raw.githubusercontent.com/bseltz-cohesity/scripts/master/python/pyhesity.py
chmod +x globalWhiteList.py
```

## Components

* globalWhiteList.py: the main python script
* pyhesity.py: the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

To list the global white list:

```bash
#example
./globalWhiteList.py -v mycluster \
                     -u myusername \
                     -d mydomain.net
#end example
```

To add a new whitelist entry:

```bash
#example
./globalWhiteList.py -v mycluster \
                     -u myusername \
                     -d mydomain.net \
                     -a \
                     -c 192.168.1.0/24
#end example
```

To remove an entry:

```bash
#example
./globalWhiteList.py -v mycluster \
                     -u myusername \
                     -d mydomain.net \
                     -r \
                     -c 192.168.1.0/24
#end example
```

## Parameters

* -v, --vip: Cohesity cluster to connect to
* -u, --username: Cohesity username
* -d, --domain: (optional) Active Directory domain (defaults to 'local')
* -a, --addentry: (optional) add an entry to the whitelist
* -r, --removeentry: (optional) remove an entry to the whitelist
* -c, --cidr: (optional) cidr to add/remove, e.g. '192.168.1.0/24'
* -n, --nfsaccess: (optional) readwrite, readonly, or none (default is readwrite)
* -s, --smbaccess: (optional) readwrite, readonly, or none (default is readwrite)
* -x, --squash: (optional) all, root or none (default is none)
* -i, --description: (optional) description for entry
