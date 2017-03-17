#!/bin/bash

# ---------------------------------- #
# >>>>> CONFIGURATION SETTINGS <<<<< #
# ---------------------------------- #

# Backups save location (FULL PATH)
backup_location="/wynZFS/Wynand/TestBackups"

# Backup folders (RELATIVE TO backup_location)
acm_save_location="/aconfmgr"
borg_save_location="/Antergos"
gmv_save_location="/Gmail"

# Folder(s) to backup (FULL PATH)(Comma seperated list)
backed_up_files="/home"

# Folder(s) to exclude from backups (Exlude folders based on PATTERN)(Comma seperated list)
excluded_folders="/home/wynand/Downloads, /home/wynand/wynZFS"
excluded_patterns="*cache*, *nohup*, *steam*, *Steam*"

#Location of passwords file (FULL PATH)
password_file_location="/home/wynand/.passwords.asc"   ##Need to specify format

# Aconfmgr (FULL PATH)(leave BLANK for default)
acm_path=""

# Borg (FULL PATH)(leave BLANK for default)
borg_path=""

# Borg prune options
borg_keep_hourly="24"
borg_keep_daily="7"
borg_keep_weekly="4"
borg_keep_monthly="12"
borg_keep_yearly="10"

# Gmail (FULL PATH)(leave BLANK for default)
gmv_path="/home/wynand/.virtualenv2/gmvault/bin/gmvault"
email_address="wynandgouwswg@gmail.com"

# --------------------------------- #
# >>>>>>> END CONFIGURATION <<<<<<< #
# --------------------------------- #



acm_save_location=$backup_location$acm_save_location
borg_save_location=$backup_location$borg_save_location
gmv_save_location=$backup_location$gmv_save_location

excluded_folders="--exclude "${excluded_folders//,/\ --exclude}
excluded_folders=${excluded_folders//\"/ }
excluded_patterns=${excluded_patterns//\ /}
excluded_patterns="--exclude "${excluded_patterns//,/\ --exclude }
backed_up_files=${backed_up_files//,/\ }
backed_up_files=${backed_up_files//\"/ }

set -a
source <(gpg -qd $password_file_location)
set +a

if [ -z $acm_path ]
then
    acm_path=$(which aconfmgr)
    if [ $acm_path = "aconfmgr not found" ]
    then
        echo "ERROR: aconfmgr not found"; exit 1;
    fi
fi

if [ -z $borg_path ]
then
    borg_path=$(which borg)
    if [ $borg_path = "borg not found" ]
    then
        echo "ERROR: borg not found"; exit 1;
    fi
fi

if [ -z $gmv_path ]
then
    gmv_path=$(which gmvault)
    if [ $gmv_path = "gmvault not found" ]
    then
        echo "ERROR: gmv not found"; exit 1;
    fi
fi

notify-send "Backup Started"""

# Backup my crontab
# crontab -l > /home/wynand/GoogleDrive/01_Personal/05_Software/Antergos/wyntergos_crontab

# Create backups of save locations
borg init $borg_save_location
borg create $excluded_folders $excluded_patterns -p -C lz4 $borg_save_location::"{hostname}-{now:%Y%m%d-%H%M}" $backed_up_files

# Backup Gmail using gmvault
#expect <<- DONE
    #set timeout -1
    #spawn $gmv_path sync -e -d $gmv_save_location $email_address -p
    #match_max 100000
    #expect -re {Please enter gmail password for }
    #send "$GOOGLE_PASSPHRASE"
    #send -- "\r"
    #expect eof
#DONE

# Save packages and configurations using aconfmgr
#expect <<- DONE
    #set timeout -1
    #spawn aconfmgr -c $acm_save_location save
    #match_max 100000
    #expect -re {\[0m\[sudo\] password for }
    #send "$SUDO_PASSPHRASE"
    #send -- "\r"
    #expect eof
#DONE

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

echo "Copying........."
    # Copy to External Drive
#     cp -Lruv /home/wynand/wynZFS/Wynand/Backups /run/media/wynand/Wyntergos_Backups

    #Upload to mega.nz
#     echo "Uploading......."
#   nocorrect megacopy -u ${mega_user} -p ${mega_password} -r /Root/Backups -l  /wynZFS/Wynand/Backups
#     megasync
fi

# kill $(pgrep megasync)

# to clear imported variables when script quits, to attempt to prevent passwords being taken
exec bash
