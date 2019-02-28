#!/bin/bash
#Author Akhil P
#ABOUT THIS SCRIPT
#CPANEL BASH SCRIPT TO RESET THE CPANEL ACCOUNT TO DEFAULT STATE
/usr/bin/clear
ERR_MSG=""
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
         ) Script: cPanelReset.sh              (
        (  Version: 2.0                         )
         ) Author: Akhil P                     (
        (  Email: akhil.pra@endurance.com       )
         ) https://github.com/akhilp1708       (
        (  http://www.mrobot.online             )
         )                                     (
        '---------------------------------------'
EOF

#Variables to hold the color counters.

red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'
ylw=$'\e[1;33'

#Function to auto accept rsa key fingerprint from command line

 function sshtmp
 {
     ssh -o "ConnectTimeout 3" \
         -o "StrictHostKeyChecking no" \
         -o "UserKnownHostsFile /dev/null" \
              "$@"
 }

# use sshtmp in place of ssh

#Get the WSS username

#WSS=`whoami`
WSS=root

#Get the inputs from the user

read -p "$blu Enter the server IP $white: " SERVER
read -p "$blu Enter the primary domain name $white: " DOMAIN
read -p "$blu Enter the account username to reset $white: " USER
echo ""

WHO="sudo /scripts/whoowns $DOMAIN"

sshtmp -q  $WSS@$SERVER "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS, VERFICATION OK! $white"
    echo ""
else
    echo -e "$red VERFICATION FAILED!!!!  PLEASE INPUT CORRECT INFO ! $white"
    echo ""
fi

read -p "$red Please verify the inputs 'username, domainname, server IP address' and continue with the account reset? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo ""
sleep 2s

#Logging the use of the script.

echo -e "$mag The execution of this script is logged :-) $white"
echo "[`date`] [`whoami`] Executed the cPanelReset_script" >> /home/akhil.pra/execution.log
echo ""

sshtmp -q -l $WSS $SERVER /bin/bash << EOF
sleep 2s
echo ""
echo -e "$grn Taking package account without user home files... $white"
echo ""

#Touching temporary log paths for redirecting the output of cpanel scripts.

sudo touch /var/log/execution.log

#Step 1: Taking the backup of cpanel account skipping the user home directory files, databases, zone, logs..etc

sudo /usr/local/cpanel/scripts/pkgacct --skipacctdb --skipdnszones --skipdomains --skipftpusers --skiphomedir --skipintegrationlinks --skiplogs --skipmailconfig --skipmailman --skipmysql --skippgsql --skipssl --skipuserdata --skipshell $USER &> /var/log/execution.log ; sudo tail /var/log/execution.log

sleep 2s
echo "" ; echo ""
echo -e "$red Removing account $USER from server $SERVER $white"
echo ""

#Step 2: Removing the cpanel account completely

sudo /usr/local/cpanel/scripts/removeacct  --force $USER &>> /var/log/execution.log ; sudo tail /var/log/execution.log

sleep 2s
echo "" ; echo ""
echo -e "$mag Restoring the account without user home files.... $white"
echo ""

#Step 3: Restoring the cpanel account from the backup generated in Step 1

sudo /usr/local/cpanel/scripts/restorepkg /home/cpmove-$USER.tar.gz  &>> /var/log/execution.log ; sudo tail /var/log/execution.log

sleep 2s
echo "" ;echo ""
echo "$grn Restore complete...... $white!"
echo ""
echo -e "$mag Verifying.... $white"
echo ""
echo -ne '#####                     (33%)\r'
sleep 2
echo -ne '#############             (66%)\r'
sleep 3
echo -ne '#######################   (100%)\r'
echo -ne '\n'
echo ""
EOF


sshtmp -q  $WSS@$SERVER "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS, DOMAIN EXIST ! RESET COMPLETED ! $white"
    echo ""
else
    echo -e "$red VERFICATION FAILED!!!!  CONTACT HPS!!!! $white"
    echo ""
fi

#END
