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

RESTORE="sudo /scripts/restorepkg"
PACKAGE="sudo /scripts/pkgacct"
WHOOWNS="sudo /scripts/whoowns"
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

read -p "$blu Enter your WSS username $white: " WSS
read -p "$blu Enter the server IP $white: " SERVER
read -p "$blu Enter the cPanel username $white: " USER
echo ""

sshtmp -l $WSS $SERVER /bin/bash << EOF
echo ""
sleep 3s
echo "$grn Taking a Full backup of the account $USER for saftey .....$white"
sleep 5s
echo ""
sudo /scripts/pkgacct $USER
echo ""
sleep 5s
echo "$grn FULL BACKUP COMPLETED $white" ; echo "" ; echo ""
sleep 5s
echo "$mag Moving the Full backup to /home/$WSS ..... $white"
sudo mv /home/cpmove-$USER.tar.gz /home/$WSS/
sleep 6s
echo "" ; echo "$grn The Full Backup stored in server $SERVER in location /home/$WSS/cpmove-$USER.tar.gz  $white" ; echo ""
sleep 6s
echo -e "$cyn Now creating a backup archive without $USER home files, MySQL data etc....  $white"
echo ""
sleep 5s
sudo /usr/local/cpanel/scripts/pkgacct --skipacctdb --skipdnszones --skipdomains --skipftpusers --skiphomedir --skipintegrationlinks --skiplogs --skipmailconfig --skipmailman --skipmysql --skippgsql --skipssl --skipuserdata --skipshell $USER
echo ""
sleep 4s
echo "$grn Archive Created without the user home files $white"
EOF


echo "" ; sleep 5s 
read -p "$blu Enter the pkgacctfile $white: " BACKUP
echo "" ; sleep 5s ; echo ""
echo "$cyn BACKUP PATH STORED, THANK FOR YOUR INPUT...!! $white" ; echo "" ; echo "" ; sleep 5s
echo "$red Now terminating the account $USER from the system....... $white"
echo "" ; echo "" ; sleep 5s
echo "$red Note: Please note that all the user's data will be deleted..!! $white"
echo "" ; echo "" ; sleep 5s


read -p "$red Continue with removing the account? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo "" ; echo "" ; sleep 5s

sshtmp -l $WSS $SERVER /bin/bash << EOF
sudo /usr/local/cpanel/scripts/removeacct  --force $USER
echo "" ; echo "" ; sleep 5s
echo -e "$grn ACCOUNT REMOVAL COMPLETE $white"
echo "" ;echo "" ; sleep 5s
echo "$mag Restoring the $USER cPanel account in $SERVER in DEFAULT STATE $white"
echo"" ; echo "" ; sleep 4s 
sudo /usr/local/cpanel/scripts/restorepkg $BACKUP
echo "" ; echo "" ; sleep 5s
echo "$grn Package Restored........RESET COMPLETE, ENJOY.. $white!" ; echo ""
EOF

#Logging the use of the script.
echo "[`date`] [`whoami`] Executed the Migration_script" >> /home/akhil.pra/execution.log
