#!/bin/zsh

# Recovery process
# 1) Download aconfmgr files from mega
# 2) Install and restore aconfmgr
# 3) Restore Antergos
# 4) Restore GoogleDrive

# >>>>> CONFIGURATION SETTINGS <<<<< #

# Aconfmgr save location (must be full path)
acm_save="/home/wynand/wynZFS/Wynand/Backups/aconfmgr"

# Gmail save location (must be full path)
gmv_path="/home/wynand/.virtualenv2/gmvault/bin/gmvault"
gmv_save="/home/wynand/wynZFS/Wynand/Backups/Gmail"
email_address="wynandgouwswg@gmail.com"

#Location of passwords file (must be full path)
pwf_loc="/home/wynand/.passwords.asc"   ##Need to specify format

#Borg/aconf/gmvault/megasync bin location(need to set defualt paths)
#Path to Gmvault (needs to be full path, leave blank if default)

#location(s) to back up
#ignored files/folders

# >>>>>>> END CONFIGURATION <<<<<<< #

source <(gpg -qd $pwf_loc)
export BORG_PASSPHRASE
export SUDO_PASSPHRASE
export MEGA_USER
export MEGA_PASSPHRASE
export GOOGLE_PASSPHRASE

notify-send "Backup Started"""

# Backup my crontab
# crontab -l > /home/wynand/GoogleDrive/01_Personal/05_Software/Antergos/wyntergos_crontab

#Create daily update of GoogleDrive
# borg create -p -C lz4 /wynZFS/Wynand/Backups/Antergos/::"{hostname}-{now:%Y%m%d-%H%M}" /home --exclude "*cache*" --exclude /home/wynand/Downloads --exclude /home/wynand/wynZFS --exclude "*.nohup*" --exclude "*steam*" --exclude "*Steam*"

# Backup Gmail using gmvault
expect <<- DONE
    set timeout -1
    spawn $gmv_path sync -e -d $gmv_save $email_address -p
    match_max 100000
    expect -re {Please enter gmail password for }
    send "$GOOGLE_PASSPHRASE"
    send -- "\r"
    expect eof
DONE

# Save packages and configurations using aconfmgr
expect <<- DONE
    set timeout -1
    spawn aconfmgr -c $acm_save save
    match_max 100000
    expect -re {\[0m\[sudo\] password for }
    send "$SUDO_PASSPHRASE"
    send -- "\r"
    expect eof
DONE

 #Prune Backups
# echo "Pruning........."
# borg prune /wynZFS/Wynand/Backups/Antergos/ --prefix "{hostname}-" --keep-hourly=24 --keep-daily=7 --keep-weekly=4 --keep-monthly=12 --keep-yearly=10

# Check backups and alert if issues
# echo "Checking........"
# borg check /wynZFS/Wynand/Backups/Antergos/ &>> /home/wynand/wynZFS/Wynand/Backups/.tmp.txt

# if grep -Fq "Completed repository check, errors found" /home/wynand/wynZFS/Wynand/Backups/.tmp.txt
# then
#     notify-send "Backup Error" "There was an error found in one of the Borg backups"
#   rm -rf /home/wynand/wynZFS/Wynand/Backups/.tmp.txt
#     mv /home/wynand/wynZFS/Wynand/Backups/.tmp.txt /home/wynand/BorgCheck.txt
# else
#     rm -rf /home/wynand/wynZFS/Wynand/Backups/.tmp.txt
#     notify-send "Backups Checked" "All clear"
    # Only copy files to HDD and mega if no errors
   
#   echo "Finding changed files..."
#   # Need to see if any files changed, and delete them from mega so that the new files can be uploaded
#   diff -qrN /wynZFS/Wynand/Backups /run/media/wynand/Wyntergos_Backups/Backups | cut -d \  -f 4 >/home/wynand/wynZFS/Wynand/Backups/.tmp.txt
#   cut -d \  -f 2 /home/wynand/wynZFS/Wynand/Backups/.changes >/home/wynand/wynZFS/Wynand/Backups/.tmp.txt
#   rm -rf /home/wynand/wynZFS/Wynand/Backups/.changes
#   sed -i 's/\/home\/wynand\/wynZFS\/Wynand\//\/run\/media\/wynand\/Wyntergos_Backups\//g' /home/wynand/wynZFS/Wynand/Backups/.tmp.txt
#   cat /home/wynand/wynZFS/Wynand/Backups/.tmp.txt | xargs -i rm -rf {}
#   sed -i 's/\/run\/media\/wynand\/Wyntergos_Backups\//\/Root\//g' /home/wynand/wynZFS/Wynand/Backups/.tmp.txt
#   cat /home/wynand/wynZFS/Wynand/Backups/.tmp.txt | xargs -i megarm -u ${mega_user} -p ${mega_password} {}
#   rm -rf /home/wynand/wynZFS/Wynand/Backups/.tmp.txt

# finding changes seems to cause integrity issues, will try just using the official mega app and closing it when done


    echo "Copying........."
    # Copy to External Drive
#     cp -Lruv /home/wynand/wynZFS/Wynand/Backups /run/media/wynand/Wyntergos_Backups

    #Upload to mega.nz
#     echo "Uploading......."
#   nocorrect megacopy -u ${mega_user} -p ${mega_password} -r /Root/Backups -l  /wynZFS/Wynand/Backups
#     megasync
# fi

# kill $(pgrep megasync)
