#!/bin/bash

# ---------------------------------- #
# >>>>> CONFIGURATION SETTINGS <<<<< #
# ---------------------------------- #

# Backups save location (FULL PATH)
backup_location="/wynZFS/Wynand/Backups"

# Backup folders (RELATIVE TO backup_location)
acm_save_location="/aconfmgr"
base_save_location="/Antergos_base"
gmv_save_location="/Gmail"

# Folder(s) to backup (FULL PATH)(Comma seperated list)
backed_up_files="/home"

#Location of passwords file (FULL PATH)
password_file_location="/home/wynand/.dotfiles/.passwords.asc"

#Path to cloud upload application (I prefer to use the official apps instead of a cli, as these apps have been optimised for the OS, and allows you to set up where to back the data up etc.)
cloud_path="/usr/bin/megasync"

## >>>>>>>>>>>>>>>>>>>>>>>>>>>> RSYNC SETTINGS <<<<<<<<<<<<<<<<<<<<<<<<<<<<< ##

# Folder(s) to exclude from backups (Exlude folders based on PATTERN)(Comma seperated list)
excluded_folders="/home/wynand/Downloads, /home/wynand/wynZFS"
excluded_patterns="*log*, *cache*, *Cache*, *nohup*, *steam*, *Steam*"
## Need to add capitals etc to this list so user doesn't have to

# rsync (FULL PATH)(leave BLANK for default)
rsync_path=""
rsync_flags=""

# Base prune options
base_keep_hourly="24"
base_keep_daily="7"
base_keep_weekly="4"
base_keep_monthly="12"
base_keep_yearly="10"

## >>>>>>>>>>>>>>>>>>>>>>>>>> ACONF SETTINGS <<<<<<<<<<<<<<<<<<<<<<<<<<< ##
# Aconfmgr (FULL PATH)(leave BLANK for default)
acm_path=""
acm_flags=""

## >>>>>>>>>>>>>>>>>>>>>>>>>> GMAIL SETTINGS <<<<<<<<<<<<<<<<<<<<<<<<<<< ##
# Gmail (FULL PATH)(leave BLANK for default)
gmv_path="/home/wynand/.virtualenvs/gmvault/bin/gmvault"
email_address="wynandgouwswg@gmail.com"

# --------------------------------- #
# >>>>>>> END CONFIGURATION <<<<<<< #
# --------------------------------- #



acm_save_location=$backup_location$acm_save_location
base_save_location=$backup_location$base_save_location
gmv_save_location=$backup_location$gmv_save_location

## need to fix this up first, can exlcude using -xr@.excluded.tmp
excluded=$excluded_patterns", "$excluded_folders
excluded=${excluded//\,/}
echo $excluded | tr " " "\n" > ./.excluded.tmp

expect_path=$(which expect)
if [ "$expect_path" = "expect not found" ]
then
    echo "ERROR: expect not found"; exit 1;
fi

if [ -z $acm_path ]
then
    acm_path=$(which aconfmgr)
    if [ "$acm_path" = "aconfmgr not found" ]
    then
        echo "ERROR: aconfmgr not found"; exit 1;
    fi
fi

if [ -z $base_path ]
then
    base_path=$(which rsync)
    if [ "$base_path" = "rsync not found" ]
    then
        echo "ERROR: rsync not found"; exit 1;
    fi
fi

if [ -z $gmv_path ]
then
    gmv_path=$(which gmvault)
    if [ "$gmv_path" = "gmvault not found" ]
    then
        echo "ERROR: gmv not found"; exit 1;
    fi
fi

notify-send "Backup Started"""

set -a
source <(gpg -qd $password_file_location)
set +a

# Backup my crontab
crontab -l > /home/wynand/GoogleDrive/01_Personal/05_Software/Antergos/wyntergos_crontab

# Need to change the way backup is done, by creating base folder and referencing it.
## How will we trim the base?
## Step 01) test is base exists
    ## a) if doesn't exist create
    ## b) if does exist, extract and diff backup folder and create backup
## Step 02) Trim as per locutus v0.4

if [ ! -d $base_save_location/"backup.base" ];
then
    rsync -va --delete --delete-excluded --exclude-from .excluded.tmp $backed_up_files $base_save_location/"backup.base"
    cp -r $base_save_location/"backup.base" $base_save_location/".backup.base.bak"
    7z a -y -m0=lzma -mx=9 $base_save_location/"backup.base.7z" $base_save_location/"backup.base"
    echo "Uploading......."
else
    ## need to copy all files recursively so that it compares to latest update
    echo "Uploading......."
fi


# Backup Gmail using gmvault
expect <<- DONE
    set timeout -1
    spawn $gmv_path sync --emails-only -e -d $gmv_save_location $email_address -p
    match_max 100000
    expect -re {Please enter gmail password for }
    send "$GOOGLE_PASSPHRASE"
    set GOOGLE_PASSPHRASE ""
    send -- "\r"
    expect eof
DONE

rm -rf "$acm_save_location"/files
rm -f "$acm_save_location"/04-AddFiles.sh
# Save packages and configurations using aconfmgr
expect <<- DONE
    set timeout -1
    spawn aconfmgr -c $acm_save_location save
    match_max 100000
    expect -re {\[0m\[sudo\] password for }
    send "$SUDO_PASSPHRASE"
    set SUDO_PASSPHRASE ""
    send -- "\r"
    expect eof
DONE

if [ -f "$acm_save_location"/99-unsorted.sh ];
then
    cat "$acm_save_location"/99-unsorted.sh | grep 'C.*File ' >> 98.tmp; cat "$acm_save_location"/99-unsorted.sh | grep 'C.*Link ' >> 98.tmp; sort 98.tmp | uniq -u >> "$acm_save_location"/04-AddFiles.sh; rm -f 98.tmp
    cat "$acm_save_location"/99-unsorted.sh | grep 'AddPackage ' >> 98.tmp; sort 98.tmp | uniq -u >> "$acm_save_location"/02-Packages.sh; rm -f 98.tmp
    cat "$acm_save_location"/99-unsorted.sh | grep 'RemovePackage ' >> 98.tmp; sort 98.tmp | uniq -u >> "$acm_save_location"/05-RemovePackages.sh; rm -f 98.tmp
    cat "$acm_save_location"/02-Packages.sh | grep 'foreign' >> 98.tmp; sort 98.tmp | uniq -u >> "$acm_save_location"/03-ForeignPackages.sh; rm -f 98.tmp
    sed -i '/--foreign/d' "$acm_save_location"/02-Packages.sh
    rm -f "$acm_save_location"/99-unsorted.sh
fi

# Copy to External Drive
echo "Copying........."
#     cp -Lruv /home/wynand/wynZFS/Wynand/Backups /run/media/wynand/Wyntergos_Backups

find -iname "*.tmp" -delete

# to clear imported variables when script quits, to attempt to prevent passwords being taken
exec bash 2>&1 /dev/null
exec $SHELL
