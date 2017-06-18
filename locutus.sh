#!/bin/bash
export DISPLAY=:0.0

# ---------------------------------- #
# >>>>> CONFIGURATION SETTINGS <<<<< #
# ---------------------------------- #

# Backups save location (FULL PATH)
backup_location="/wynZFS/Wynand/Backups"

# Backup folders (RELATIVE TO backup_location)
acm_save_location="/aconfmgr"
dup_save_location="/Duplicity"
gmv_save_location="/Gmail"

# Folder(s) to backup (FULL PATH)(Comma seperated list)
backed_up_files="/home"

# Exluded pattern(s) during backup
excluded_list="**[Ss]team**, **[Cc]ache**, **wynZFS**"

#Location of passwords file (FULL PATH)
password_file_location="/home/wynand/.dotfiles/.passwords.asc"

#Path to cloud upload application (I prefer to use the official apps instead of a cli, as these apps have been optimised for the OS, and allows you to set up where to back the data up etc.)
cloud_path="/usr/bin/megasync"
mega_user="wynand.gouws.wg@gmail.com"

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
gmv_save_location=$backup_location$gmv_save_location

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

base_path=$(which duplicity)
if [ "$base_path" = "duplicity not found" ]
then
    echo "ERROR: duplicity not found"; exit 1;
fi

if [ -z $gmv_path ]
then
    gmv_path=$(which gmvault)
    if [ "$gmv_path" = "gmvault not found" ]
    then
        echo "ERROR: gmv not found"; exit 1;
    fi
fi

notify-send "Backup Started"

# Backup my crontab
crontab -l > /home/wynand/GoogleDrive/01_Personal/05_Software/Antergos/wyntergos_crontab

# Backup using duplicity
excluded_list=${excluded_list//\,/}
echo $excluded_list | tr " " "\n" > ./.excluded.tmp

duplicity_backup () {
set -a
source <(gpg -qd $password_file_location)
set +a
unset GOOGLE_PASSPHRASE
unset SUDO_PASSPHRASE

PASSPHRASE="$BACKUP_PASSPHRASE" duplicity --exclude-filelist ./.excluded.tmp $backed_up_files file://$backup_location$dup_save_location &> ./.backupcheck.tmp
unset PASSPHRASE
unset BACKUP_PASSPHRASE

if grep 'Errors.*[1-]' ./.backupcheck.tmp
then
    find $backup_location$dup_save_location/* -cmin -60 -delete
    duplicity_backup
fi
}

duplicity_backup

# Backup Gmail using gmvault
set -a
source <(gpg -qd $password_file_location)
set +a
unset SUDO_PASSPHRASE
unset BACKUP_PASSPHRASE
expect <<- DONE
    set timeout -1
    spawn $gmv_path sync --emails-only -e -d $gmv_save_location $email_address -p
    match_max 100000
    expect -re {Please enter gmail password for }
    send "$GOOGLE_PASSPHRASE"
    send -- "\r"
    expect eof
DONE

rm -rf "$acm_save_location"/files
rm -f "$acm_save_location"/04-AddFiles.sh

# Save packages and configurations using aconfmgr
set -a
source <(gpg -qd $password_file_location)
set +a
unset GOOGLE_PASSPHRASE
unset BACKUP_PASSPHRASE
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
#
find . -iname "*.tmp" -delete

# Upload to whatever cloud using the linux gui for whatever it is. In my case it's Mega
megasync

# To clear imported variables when script quits, to attempt to prevent passwords being taken
exec bash 2>&1 /dev/null
exec $SHELL
