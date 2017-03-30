#!/bin/bash

# ---------------------------------- #
# >>>>> CONFIGURATION SETTINGS <<<<< #
# ---------------------------------- #

# Backups save location (FULL PATH)
backup_location="/wynZFS/Wynand/Backups"

# Backup folders (RELATIVE TO backup_location)
acm_save_location="/aconfmgr"
borg_save_location="/Antergos"
gmv_save_location="/Gmail"

# Folder(s) to backup (FULL PATH)(Comma seperated list)
backed_up_files="/home"

#Location of passwords file (FULL PATH)
password_file_location="/home/wynand/.passwords.asc"   ##Need to specify format

## >>>>>>>>>>>>>>>>>>>>>>>>>> BORG SETTINGS <<<<<<<<<<<<<<<<<<<<<<<<<<< ##

# Folder(s) to exclude from backups (Exlude folders based on PATTERN)(Comma seperated list)
excluded_folders="/home/wynand/Downloads, /home/wynand/wynZFS"
excluded_patterns="*cache*, *nohup*, *steam*, *Steam*"

# Borg (FULL PATH)(leave BLANK for default)
borg_path=""
borg_flags="-s -p -C lzma,9"
# Go to http://borgbackup.readthedocs.io/en/stable/usage.html#borg-create to see all possible flags

# Borg prune options
borg_keep_hourly="24"
borg_keep_daily="7"
borg_keep_weekly="4"
borg_keep_monthly="12"
borg_keep_yearly="10"


## >>>>>>>>>>>>>>>>>>>>>>>>>> ACONF SETTINGS <<<<<<<<<<<<<<<<<<<<<<<<<<< ##
# Aconfmgr (FULL PATH)(leave BLANK for default)
acm_path=""


## >>>>>>>>>>>>>>>>>>>>>>>>>> GMAIL SETTINGS <<<<<<<<<<<<<<<<<<<<<<<<<<< ##
# Gmail (FULL PATH)(leave BLANK for default)
gmv_path="/home/wynand/.virtualenv2/gmvault/bin/gmvault"
email_address="wynandgouwswg@gmail.com"

# --------------------------------- #
# >>>>>>> END CONFIGURATION <<<<<<< #
# --------------------------------- #



acm_save_location=$backup_location$acm_save_location
borg_save_location=$backup_location$borg_save_location
gmv_save_location=$backup_location$gmv_save_location

excluded_folders=${excluded_folders//,/\ }
excluded_patterns=${excluded_patterns//,/\ }
backed_up_files=${backed_up_files//,/\ }
backed_up_files=${backed_up_files//\"/ }
excluded=$excluded_patterns" "$excluded_folders
echo $excluded | xargs -n1 >> ./.excluded.tmp


set -a
source <(gpg -qd $password_file_location)
set +a

# if [$(borg list $borg_save_location)]

if [ -z $acm_path ]
then
    acm_path=$(which aconfmgr)
    if [ "$acm_path" = "aconfmgr not found" ]
    then
        echo "ERROR: aconfmgr not found"; exit 1;
    fi
fi

if [ -z $borg_path ]
then
    borg_path=$(which borg)
    if [ "$borg_path" = "borg not found" ]
    then
        echo "ERROR: borg not found"; exit 1;
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

# Check if borg repo exists at save location
borg list $borg_save_location &> .borgexiststest.tmp
if grep -Fq "does not exist" .borgexiststest.tmp
then
    borg init $borg_save_location
    rm .borgexiststest.tmp
else
    rm .borgexiststest.tmp
fi

# Create backups of save locations
borg create $borg_flags $borg_save_location::"{hostname}-{now:%Y%m%d-%H%M}" $backed_up_files --exclude-from ./.excluded.tmp

# Prune Backups
echo "Pruning........."
borg prune $borg_save_location --prefix "{hostname}-" --keep-hourly=$borg_keep_hourly --keep-daily=$borg_keep_daily --keep-weekly=$borg_keep_weekly --keep-monthly=$borg_keep_monthly --keep-yearly=$borg_keep_yearly

# Check backups and alert if issues
echo "Checking........"
borg check $borg_save_location &>> $borg_save_location/.tmp.txt

if grep -Fq "Completed repository check, errors found" $borg_save_location/.tmp.txt
then
    notify-send "Backup Error" "There was an error found in one of the Borg backups"
    mv $borg_save_location/.tmp.txt ~/BorgErrors.txt
else
    rm -rf $borg_save_location/.tmp.txt
    notify-send "Backups Checked" "All clear"
    # Only copy files to HDD and mega if no errors
fi

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
