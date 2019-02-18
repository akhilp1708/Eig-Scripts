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
ERR_MSG=""
cat << "EOF" 
                           .-"``"-.
                          /______; \
                         {_______}\|
                         (/ a a \)(_)
                         (.-.).-.)
          _________ooo__(    ^    )_____________
         /               '-.___.-'              \
        |                                        |
        | SCRIPT: Reset cPanel                   |
        | VERSION: 1.0                           |
        | AUTHOR: Akhil P                        |
        | EMAIL: akhil.pra@endurance.com         |
        | MY REPO: https://github.com/akhilp1708 |
        | VISIT MROBOT.IN                        |
        | http://www.mrobot.online               |
         \__________________________ooo_________/
                         |_  |  _|  jgs
                         \___|___/
                         {___|___}
                          |_ | _|
                          /-'Y'-\
                         (__/ \__)

EOF
# These variables hold the counters.
red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'
ylw=$'\e[1;33'

RESTORE=`sudo /scripts/restorepkg`
PACKAGE=`sudo /scripts/pkgacct`
WHOOWNS=`sudo /scripts/whoowns`
FILE=$(echo $BACKUP | cut -d'/' -f3)

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
read -p "Enter your WSS username : " WSS
read -p "Enter the server IP : " SERVER
read -p "Enter the cPanel username : " USER
echo ""

sshtmp -l $WSS $SERVER /bin/bash << EOF

echo "Taking a backup of the account $USER for saftey ....."
sleep 1s
echo ""
sudo /scripts/pkgacct $USER
echo ""
echo "BACKUP COMPLETED"
echo "" ; echo "Backup stored in $SERVER /home/" ; echo ""
echo -e "Now creating a backup archive without $USER home files, MySQL data etc...."
echo ""
sleep 1s
sudo /usr/local/cpanel/scripts/pkgacct --skipacctdb --skipdnszones --skipdomains --skipftpusers --skiphomedir --skipintegrationlinks --skiplogs --skipmailconfig --skipmailman --skipmysql --skippgsql --skipssl --skipuserdata --skipshell $USER
echo ""
echo "ARCHIVE CREATED"
echo ""
echo "Enter the Backup archive file name including the path : " BACKUP
echo ""
echo "BACKUP PATH STORED" ; echo ""
echo "Now terminating the account $USER from the system......."
echo ""
echo "Note: Please note that all the user's data will be deleted. So, backup the user's data (like data under public_html), if required."
echo ""
read -p "Continue with removing the account? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo ""
sudo /usr/local/cpanel/scripts/removeacct  --force $USER
echo ""
echo -e "ACCOUNT REMOVAL COMPLETE"
echo ""
echo "Restoring the $USER cPanel account in $SERVER in DEFAULT STATE"
echo""
sudo /usr/local/cpanel/scripts/restorepkg /home/$FILE
echo ""
echo "Package Restored........RESET COMPLETE, ENJOY..!"
EOF

#Logging the use of the script.
echo "[`date`] [`whoami`] Executed the Migration_script" >> /home/akhil.pra/execution.log

















