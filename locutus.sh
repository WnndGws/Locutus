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

# Backup my crontab
# crontab -l > /home/wynand/GoogleDrive/01_Personal/05_Software/Antergos/wyntergos_crontab

## http://www.mikerubel.org/computers/rsync_snapshots/#Appendix
## folder format "backup.hourly.20170405_2200"
## date -d "20170405 2200" +%s gives time since epoch, change the +%s for other info

# Backup using rsync (initial if statement tests if folder is empty)
if [ "$(ls -A $base_save_location)" ]; then
    # Step 1: remove oldest backup that doesn't meet config requirements (IF IT EXISTS)
    oldest_hour_allowed=$(( $(date +%s) - $(echo "$base_keep_hourly*3600" | bc ) ))
    oldest_day_allowed=$(( $(date +%s) - $(echo "$base_keep_daily*3600*24" | bc ) ))
    oldest_week_allowed=$(( $(date +%s) - $(echo "$base_keep_weekly*3600*24*7" | bc ) ))
    oldest_month_allowed=$(( $(date +%s) - $(echo "$base_keep_monthly*3600*24*31" | bc ) ))
    oldest_year_allowed=$(( $(date +%s) - $(echo "$base_keep_yearly*3600*24*366" | bc ) ))

    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*hourly*")
    do
        folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
        if [ $folder_age -le $oldest_hour_allowed ]; then
            mv $folder $(echo "$folder" | sed -e 's/hourly/daily/g')
        fi
    done

    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*daily*")
    do
        folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
        if [ $folder_age -le $oldest_day_allowed ]; then
            mv $folder $(echo "$folder" | sed -e 's/daily/weekly/g')
        fi
    done

    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*weekly*")
    do
        folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
        if [ $folder_age -le $oldest_week_allowed ]; then
            mv $folder $(echo "$folder" | sed -e 's/weekly/monthly/g')
        fi
    done

    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*monthly*")
    do
        folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
        if [ $folder_age -le $oldest_month_allowed ]; then
            mv $folder $(echo "$folder" | sed -e 's/monthly/yearly/g')
        fi
    done

    # Now only have the folders which are the correct age, need to trim them next

    touch .saved_folders.tmp
    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*hourly*" )
    do
        folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | cut -c 1-11 | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%H)
        if grep -Fxq $folder_age .saved_folders.tmp; then
            rm -rf $folder
        else
            echo $folder_age >> .saved_folders.tmp
        fi
    done
    rm .saved_folders.tmp

    touch .saved_folders.tmp
    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*daily*" )
    do
        folder_age=$(echo $folder |rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | cut -d'_' -f1)
        if grep -Fxq $folder_age .saved_folders.tmp; then
            rm -rf $folder
        else
            echo $folder_age >> .saved_folders.tmp
        fi
    done
    rm .saved_folders.tmp

    touch .saved_folders.tmp
    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*weekly*" )
    do
        folder_age=$(echo $folder |rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | cut -d'_' -f1 | xargs -i date -d {} +%U)
        if grep -Fxq $folder_age .saved_folders.tmp; then
            rm -rf $folder
        else
            echo $folder_age >> .saved_folders.tmp
        fi
    done
    rm .saved_folders.tmp

    touch .saved_folders.tmp
    for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*monthly*" )
    do
        folder_age=$(echo $folder |rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | cut -d'_' -f1 | xargs -i date -d {} +%m)
        if grep -Fxq $folder_age .saved_folders.tmp; then
            rm -rf $folder
        else
            echo $folder_age >> .saved_folders.tmp
        fi
    done
    rm .saved_folders.tmp

    # Step 2: make a hardlink copy of latest backup, and move it down the line (cp -al backup.0 backup.1)
    latest_backup=$(ls -t $base_save_location | head -1 )
    cp -la $base_save_location/$latest_backup $base_save_location/$latest_backup.linked
    mv $base_save_location/$latest_backup $base_save_location/"backup.$(date +'%Y%m%d_%H%M').hourly"
    mv $base_save_location/$latest_backup.linked $base_save_location/$latest_backup

    # Step 3: rsync newest backup (rsync -va --delete --delete-excluded --exclude-from .excluded.tmp $files_to_backup $backup_location)
    rsync -va --delete --delete-excluded --exclude-from .excluded.tmp $backed_up_files $base_save_location/"backup.$(date +'%Y%m%d_%H%M').hourly"

    # Step 4: Use 7z to compress and pw protect all

else
    rsync -va --delete --delete-excluded --exclude-from .excluded.tmp $backed_up_files $base_save_location/"backup.$(date +'%Y%m%d_%H%M').hourly"
fi
rm -rf ./.excluded.tmp

set -a
source <(gpg -qd $password_file_location)
set +a

# Backup Gmail using gmvault
expect <<- DONE
    set timeout -1
    spawn $gmv_path sync -e -d $gmv_save_location $email_address -p
    match_max 100000
    expect -re {Please enter gmail password for }
    send "$GOOGLE_PASSPHRASE"
    GOOGLE_PASSPHRASE=""
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
    SUDO_PASSPHRASE=""
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
