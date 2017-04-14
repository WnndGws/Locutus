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
# rsync_path=""
# rsync_flags=""

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

# Backup using rsync
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
        echo "Too old"
        mv $folder $(echo "$folder" | sed -e 's/hourly/daily/g')
    fi
done

for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*daily*")
do
    folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
    if [ $folder_age -le $oldest_day_allowed ]; then
        echo "Too old"
        mv $folder $(echo "$folder" | sed -e 's/daily/weekly/g')
    fi
done

for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*weekly*")
do
    folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
    if [ $folder_age -le $oldest_week_allowed ]; then
        echo "Too old"
        mv $folder $(echo "$folder" | sed -e 's/weekly/monthly/g')
    fi
done

for folder in $(find $base_save_location -maxdepth 1 -mindepth 1 -type d -iname "*monthly*")
do
    folder_age=$(echo $folder | rev | cut -d'/' -f1 | rev | cut -c1-20 | rev | cut -c1-13 | rev | sed -e 's/_/\\\ /g' | xargs -i date -d {} +%s)
    if [ $folder_age -le $oldest_month_allowed ]; then
        echo "Too old"
        mv $folder $(echo "$folder" | sed -e 's/monthly/yearly/g')
    fi
done

## now have list of which folders qualify for each category, now need to prune them
## find folders that have the same hour and delete the older ones, count the amount of hourlies, trim to match


# Step 3: make a hardlink copy of latest backup, and move it down the line (cp -al backup.0 backup.1)
# Step 4: rsync newest backup (rsync -va --delete --delete-excluded --exclude-from .excluded.tmp $files_to_backup $backup_location)
# Step 5: touch backup.0 to update its creation time
# Step 6: Use 7z to compress and pw protect all
