#!/bin/bash

# ---------------------------------- #
# >>>>> CONFIGURATION SETTINGS <<<<< #
# ---------------------------------- #

# Backups save location (FULL PATH)
backup_location="/wynZFS/Wynand/Backups"

# Backup folders (RELATIVE TO backup_location)
acm_save_location="/aconfmgr"
base_save_location="/Antergos"
gmv_save_location="/Gmail"

# Folder(s) to backup (FULL PATH)(Comma seperated list)
backed_up_files="/home"

#Location of passwords file (FULL PATH)
password_file_location="/home/wynand/.passwords.asc"   ##Need to specify format

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
gmv_path="/home/wynand/.virtualenv2/gmvault/bin/gmvault"
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

set -a
source <(gpg -qd $password_file_location)
set +a

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

# Backup my crontab
# crontab -l > /home/wynand/GoogleDrive/01_Personal/05_Software/Antergos/wyntergos_crontab

## http://www.mikerubel.org/computers/rsync_snapshots/#Appendix
# Backup using rsync
# Step 1: remove oldest backup that doesn't meet config requirements (IF IT EXISTS)
# Step 2: move each of the middle backups down the line
# Step 3: make a hardlink copy of latest backup, and move it down the line (cp -al backup.0 backup.1)
# Step 4: rsync newest backup (rsync -va --delete --delete-excluded --exclude-from .excluded.tmp $files_to_backup $backup_location)
# Step 5: touch backup.0 to update its creation time

# Prune rsync

# Backup Gmail using gmvault
expect <<- DONE
    set timeout -1
    spawn $gmv_path sync -e -d $gmv_save_location $email_address -p
    match_max 100000
    expect -re {Please enter gmail password for }
    send "$GOOGLE_PASSPHRASE"
    send -- "\r"
    expect eof
DONE

# Save packages and configurations using aconfmgr
expect <<- DONE
    set timeout -1
    spawn aconfmgr -c $acm_save_location save
    match_max 100000
    expect -re {\[0m\[sudo\] password for }
    send "$SUDO_PASSPHRASE"
    send -- "\r"
    expect eof
DONE

if [ -f "$acm_save_location"/99-unsorted.sh ];
then
    notify-send "The file 99-unsorted exists in your aconfmgr folder" "You should sort the entries of it into individual files"
fi

# Copy to External Drive
echo "Copying........."
#     cp -Lruv /home/wynand/wynZFS/Wynand/Backups /run/media/wynand/Wyntergos_Backups

#Upload to mega.nz
echo "Uploading......."
megasync

kill $(pgrep megasync)
find -iname "*.tmp" -delete

# to clear imported variables when script quits, to attempt to prevent passwords being takenI
exec bash
exec zsh
