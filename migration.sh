#!/bin/bash -       
#title           :migrate.sh
#description     :This script is used for migrating accounts.
#author		 :Akhil P
#date            :20190220
#version         :1.0   
#usage		 :bash migrate.sh
#notes           :Install Vim and Emacs to use this script.
#bash_version    :4.1.5(1)-release
#==============================================================================

today=$(date +%Y%m%d)
div=======================================

/usr/bin/clear
cat << "EOF" 
                  __   _,--="=--,_   __
                 /  \."    .-.    "./  \
                /  ,/  _   : :   _  \/` \
                \  `| /o\  :_:  /o\ |\__/
                 `-'| :="~` _ `~"=: |
                    \`     (_)     `/
             .-"-.   \      |      /   .-"-.
        .---{     }--|  /,.-'-.,\  |--{     }---.
         )  (_)_)_)  \_/`~-===-~`\_/  (_(_(_)  (
        (                                       )
         ) MIGRATION SCRIPT                    (
        (  Author Akhil P                       )
         ) akhil.pra@endurance.com             (
        (  VISIT MROBOT.IN                      )
         ) http://www.mrobot.online            (
        '---------------------------------------'

EOF
# These variables hold the counters.
red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'
ylw=$'\e[1;33'
ERR_MSG=""

RESTORE="$(/scripts/restorepkg)"
PACKAGE="$(/scripts/pkgacct)"
WHOOWNS="$(/scripts/whoowns)"
USER="$WHOOWNS $DOMAIN"

#Auto accept rsa key fingerprint from command line
 #  ssh + scp without storing or prompting for keys.
 #
 function sshtmp
 {
     ssh -o "ConnectTimeout 3" \
         -o "StrictHostKeyChecking no" \
         -o "UserKnownHostsFile /dev/null" \
              "$@"
 }
 function scptmp
 {
     exec scp -o "ConnectTimeout 3" \
         -o "StrictHostKeyChecking no" \
         -o "UserKnownHostsFile /dev/null" \
         "$@"
 }
# use sshtmp, or scptmp in place of ssh and scp
echo ""
# Get the Jira user name
read -p "$blu Enter your wss username $white: " WSS
# Get the source server IP address
read -p "$blu Enter source server address $white: " SOURCE
# Get the destination server IP address
read -p "$blu Enter destination server address $white: " DESTINATION
Read -p "$blu Enter Domain name $white: " DOMAIN
read -p "Are the information correct? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo ""

read -p "To add SSH keys between $SOURCE and $DESTINATION , Please confirm with option (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

echo ""
echo "Note: Only press $red ENTER $white option and keep the default settings for generating SSH keys"
sleep 1s

echo ""
sshtmp -l $WSS $SOURCE "ssh-keygen"
sshtmp -l $WSS $SOURCE "cat ~/.ssh/id_rsa.pub | ssh $WSS@$DESTINATION "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys""

echo ""
sleep 1s
echo "$grn KEYS ADDED SUCCESS $white"
echo ""
read -p "$mag READY FOR MIGRATION? $white $red PRESS 'Y' TO START AND 'N' TO QUIT (Y/N) $white: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo ""

OWNER=$(sshtmp -l $WSS $SOURCE "$USER") 

echo "The $DOMAIN is owned by account $OWNER, Now taking the backup of this account "
sleep 1s

# Taking the package account
sshtmp -l $WSS $SOURCE "$PACKAGE $USER"

echo ""
read -p "Enter the backup file path : " BACKUP


#  Now, login to source server and use rsync command to move the backup file from source to the target server :-

sshtmp -A $SOURCE rsync -vaur $BACKUP -e "sshtmp -i .ssh/id_rsa" $WSS@$DESTINATION

echo ""

echo "Now restoring the $BACKUP ....\n Restoring the account $OWNER in server $DESTINATION ....."

echo ""

sshtmp -l $WSS $DESTINATION "$RESTORE $BACKUP"	

echo ""
Sleep 1s
echo "$grn RESTORATION COMPLETED SUCCESSFULLY $white"
echo ""
echo "$red Now please update the new server details in OBEE using the HOSTING SYNC TOOL in support account according to the brand. $white"
echo ""
echo "Please find the below details to update in $red HOSTING SYNC TOOL $white"

sshtmp -l $WSS $DESTINATION /bin/bash << EOF
sudo /scripts/ipusage | grep $DOMAIN
sudo /scripts/whoowns $DOMAIN
EOF  







