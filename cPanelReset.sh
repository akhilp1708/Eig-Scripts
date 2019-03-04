#!/bin/bash
#Author Akhil P
#About this Script
#cPanel Bash script to reset a cPanel account to default state

PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/`whoami`/bin

/usr/bin/clear

#Logging the execution of this script

LOG_FILE=execution.log.$(date +%F_%R)
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)
echo "[`date`] [`whoami`] Executed the cPanelReset_script" >> /home/akhil.pra/execution.log

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
ylw=$'\e[1;33m'

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

echo ""
read -p "$blu Enter the server IP $white: " SERVER
read -p "$blu Enter the primary domain name $white: " DOMAIN
read -p "$blu Enter the account username to reset $white: " USER
echo ""

# Checking the host IP for making sure the input IP is not bulk hosting server.

HOSTIP=`host $SERVER | awk '{print $NF}'`;
HOSTCHK=`echo $HOSTIP | grep -ic "amazon"`;

if [ $HOSTCHK -eq 1 ]
then
echo -e "$red Your input is a BH server ! Please enter a SD or MD server IP !  $white"

echo ""

echo -e  "$blu Please recheck and enter the information again ! $white "

echo ""

exit 0
fi

#Verifying the inputs

WHO="sudo /scripts/whoowns $DOMAIN"

sshtmp -q  $WSS@$SERVER "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS, VERIFICATION OK! $white"
    echo ""
else
    echo -e "$red VERIFICATION FAILED!!!!  PLEASE INPUT CORRECT INFO ! $white"
    echo ""
    exit 0
fi

echo -e "$ylw ************* $white"
echo -e "$blu Domain name :$white $DOMAIN\n$blu Server name :$white $HOSTIP\n$blu Hosting IP  :$white $SERVER\n$blu cPanel User :$white $RESULT"
echo -e "$ylw ************* $white"
echo "" ; echo ""
read -p "$red Please verify the inputs 'username, domainname, server IP address' and press 'y' to continue with the account reset? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo ""
sleep 2s

#Logging into Server

sshtmp -q -l $WSS $SERVER /bin/bash << EOF
sleep 2s
echo ""
echo -e "$grn Taking package account without user home files... $white"
echo ""
#Touching temporary log paths for redirecting the output of cpanel scripts. This is created to tail the output of cpanel scripts.
sudo touch /var/log/execution.log
#Step 1: Taking the backup of cpanel account skipping the user home directory files, databases, zone, logs..etc
echo -e "$ylw ------------------------------------ $white"
sudo /usr/local/cpanel/scripts/pkgacct --skipacctdb --skipdnszones --skipdomains --skipftpusers --skiphomedir --skipintegrationlinks --skiplogs --skipmailconfig --skipmailman --skipmysql --skippgsql --skipssl --skipuserdata --skipshell $USER &> /var/log/execution.log ; sudo tail /var/log/execution.log
sleep 2s
echo "" ;
echo -e "$ylw ------------------------------------ $white"
echo ""
echo -e "$red Removing account $USER from server $SERVER $white"
echo ""
#Step 2: Removing the cpanel account completely
echo -e "$ylw ------------------------------------ $white"
sudo /usr/local/cpanel/scripts/removeacct  --force $USER &>> /var/log/execution.log ; sudo tail /var/log/execution.log
sleep 2s
echo "" ;
echo -e "$ylw ------------------------------------ $white"
echo ""
echo -e "$mag Restoring the account without user home files.... $white"
echo ""
#Step 3: Restoring the cpanel account from the backup generated in Step 1
echo -e "$ylw ------------------------------------ $white"
sudo /usr/local/cpanel/scripts/restorepkg /home/cpmove-$USER.tar.gz  &>> /var/log/execution.log ; sudo tail /var/log/execution.log
sleep 2s
echo "" ;
echo -e "$ylw ------------------------------------ $white"
echo ""
echo ""
echo "$grn Restore completed ...... $white!"
echo ""
echo ""

echo -ne '$blu Verifying #########                                   (33%) $white\r'
sleep 2
echo -ne '$blu Verifying ########################                    (66%) $white\r'
sleep 3
echo -ne '$blu Verifying #########################################   (100%) $white\r'
echo -ne '\n'
echo ""
echo ""
EOF

#Step 4: Verifying

sshtmp -q  $WSS@$SERVER "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS! RESET COMPLETED! $white"
    echo ""
else
    echo -e "$red VERIFICATION FAILED!!!!  CONTACT HPS!!!! $white"
    echo ""
fi

#Step 5: Removing the temporary log files created

sshtmp -q $WSS@$SERVER "sudo mv /var/log/execution.log /tmp/"

#END
