#!bin/bash
#Author: Akhil P
#Script to migrate single cpanel account to remote server by exchanging the ssh keys

PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/`whoami`/bin
/usr/bin/clear

#Logging the execution of this script

LOG_FILE=execution.log.$(date +%F_%R)
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)
echo "[`date`] [`whoami`] Executed the cPanelReset_script" >> /home/akhil.pra/execution.log

cat << "EOF"
 __  __ _                 _   _                _____           _       _
|  \/  (_)               | | (_)              / ____|         (_)     | |
| \  / |_  __ _ _ __ __ _| |_ _  ___  _ __   | (___   ___ _ __ _ _ __ | |_
| |\/| | |/ _` | '__/ _` | __| |/ _ \| '_ \   \___ \ / __| '__| | '_ \| __|
| |  | | | (_| | | | (_| | |_| | (_) | | | |  ____) | (__| |  | | |_) | |_
|_|  |_|_|\__, |_|  \__,_|\__|_|\___/|_| |_| |_____/ \___|_|  |_| .__/ \__|
           __/ |                                                | |
          |___/                                                 |_|
EOF

# These variables hold the color counters.

red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'
ylw=$'\e[1;33m'

#Auto accept rsa key fingerprint from command line
 #  ssh without storing or prompting for keys.
 #
 function sshtmp
 {
     ssh -o "ConnectTimeout 3" \
         -o "StrictHostKeyChecking no" \
         -o "UserKnownHostsFile /dev/null" \
              "$@"
 }

echo "" ; echo "" ; echo "$grn Welcome $(whoami) ! $white" ; echo ""
echo -e "$ylw :::::: PLEASE READ THIS ! ::::::$white"
echo -e "$ylw ======================================================================================================================================== $white"
echo "" ; echo -e "$red This script works only for Single/Multi-Domain Servers $white" ; echo ""
cat << "EOF"
*  Make sure that you are migrating the domain to a normal server or branded one which hosts the corresponding brand domains.
*  Do not migrate to a cross-branded server. You can check the branding details here.

   Ex: If the hosting is with HGI, then migrate the domain to the server which has HGI orders or HGI branded servers.

*  While updating BLL, make sure you specify the correct hostname. This is important as the BLL script will check the tempURL to verify the serv   er hostname. There are 2 types of hostnames: *.webhostbox.net which is a normal server. *.brandservers.com which is a branded hostname.
   If the server is a branded server, we should use the branded server hostname only. If you use  *.webhostbox.net for a branded server, the que   ry to update BLL won't work.
EOF
echo -e "$ylw ======================================================================================================================================== $white"

#Get the WSS username

#WSS=`whoami`
WSS=root

#Step 1: Get the inputs from the user

echo ""
read -p "$blu Enter the Source server IP $white: " SOURCE
read -p "$blu Enter the Destination server IP $white: " DEST
read -p "$blu Enter the Main username $white: " USER
read -p "$blu Enter the Primary domain name $white: " DOMAIN
echo ""

SHOSTIP=`host $SOURCE | awk '{print $NF}'`;
DHOSTIP=`host $DEST | awk '{print $NF}'`;

#Verifying the inputs

WHO="sudo /scripts/whoowns $DOMAIN"

echo -e "$ylw Checking if the domain exists in source server '$SHOSTIP' ... ! $white"

sshtmp -q  $WSS@$SOURCE "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn Success, verification OK! The domain exists in source server '$SHOSTIP' $white"
    echo ""
else
    echo -e "$red VERIFICATION FAILED!!!!  PLEASE INPUT CORRECT INFO ! $white"
    echo ""
    exit 0
fi


echo -e "$ylw Checking if the domain exists in destination server '$DHOSTIP' ... ! $white"

sshtmp -q  $WSS@$DEST "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$red Verfication complete: The domain exists in destinaton server '$DHOSTIP', hence aborting script! $white"
    echo ""
    exit 0
else
    echo -e "$grn Verification complete: The domain does not exist in destination server and you are good to procceed with the migration ! $white"
    echo ""
fi


echo -e "$ylw ************** $white"
echo -e "$blu Domain name :$white $DOMAIN\n$blu Source server :$white $SHOSTIP\n$blu Destination server  :$white $DHOSTIP\n$blu cPanel User :$white $USER"
echo -e "$ylw ************** $white"
echo "" ; echo ""

sleep 1s
read -p "$red Please cross-check the Source/Destination server IP and other informations and procceed? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1


#Step 2: Generating and copying SSH keys for source and remote server

echo ""
echo "$blu Generating SSH keys.... $white"
echo ""
echo -e "$ylw ======================================================================================================================================== $white"
yes "y" | ssh-keygen -t rsa -N "" -f source.key 2> /dev/null
echo -e "$ylw ======================================================================================================================================== $white"
echo""

echo "$blu Copying the key to source server '$SHOSTIP' .....$white"
echo ""

scp -o StrictHostKeyChecking=no -r source.key $WSS@$SOURCE:/$WSS/ 2> /dev/null
sshtmp -q -l $WSS $SOURCE /bin/bash  <<'EOF'
    sudo chmod 600 source.key
EOF

sleep 1s
echo "$blu Copying the public key to destination server '$DHOSTIP' .... $white"
echo ""

# Echo the public key to the destination server, Also we are taking a backup of authorised_keys

scp -o StrictHostKeyChecking=no -r source.key.pub $WSS@$DEST:/$WSS/ 2> /dev/null

sshtmp -q -l $WSS $DEST /bin/bash  <<'EOF'
    sudo yes |cp -r ~/.ssh/authorized_keys ~/.ssh/authorized_keys_bak
    sudo cat source.key.pub >>  ~/.ssh/authorized_keys
EOF

sleep 1s
echo "$grn Keys exchanged ! $white"
echo ""
echo "$blu Starting the backup generation of account $USER in source server '$SHOSTIP'... $white"
echo ""
echo -e "$ylw ======================================================================================================================================= $white"
ssh -o StrictHostKeyChecking=no -q $WSS@$SOURCE "sudo touch /var/log/execution.log ; sudo /scripts/pkgacct $USER  &>> /var/log/execution.log ; sudo tail /var/log/execution.log "
echo -e "$ylw ======================================================================================================================================= $white"
echo ""
sleep 1s
echo "$blu Now copying the backup to destination server, please hold on.... $white"

echo ""
echo -e "$ylw ======================================================================================================================================== $white"
ssh -o StrictHostKeyChecking=no -q $WSS@$SOURCE "rsync --stats -avz -e 'ssh -o StrictHostKeyChecking=no -q -i source.key' /home/cpmove-$USER.tar.gz $WSS@$DEST:/$WSS/"
echo -e "$ylw ======================================================================================================================================== $white"
echo ""
echo "$blu Copying of backup file completed. Now starting the restore process in destination server '$DHOSTIP'.. $white"
echo ""
echo -e "$ylw ======================================================================================================================================== $white"
ssh -o StrictHostKeyChecking=no -q $WSS@$DEST "sudo /usr/local/cpanel/scripts/restorepkg --force cpmove-$USER.tar.gz &>> /var/log/execution.log ; sudo tail /var/log/execution.log "
echo -e "$ylw ======================================================================================================================================== $white"
echo ""

echo  "$blu Restore completed in destination server! $white"

echo ""

echo "$blu Verifying, if account '$USER' is migrated to destination server '$DHOSTIP' $white"
echo ""

#Assigning variable to find the domain owner after restoring account.

WHO="sudo /scripts/whoowns $DOMAIN"

#Step 4: Verification of restoration. Checking if the domain exists after termination.

sshtmp -q $WSS@$DEST "$WHO" &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS, VERFICATION OK! $white"
    echo ""
else
    echo -e "$red VERFICATION FAILED!!!!  CONTACT HPS!!!! $white"
    echo ""
    exit 1
fi

#Step 5: Now, since the migration is completed, need to remove the ssh keys from source and destination server.

ssh -o StrictHostKeyChecking=no -q $WSS@$DEST "sudo yes | mv ~/.ssh/authorized_keys_bak ~/.ssh/authorized_keys"

#Step 6: Suspending account in source server

echo "$blu Now suspending account in source server '$SHOSTIP' $white" ; echo ""
echo -e "$ylw ========================================================================================================================================= $white"
ssh -o StrictHostKeyChecking=no -q $WSS@$SOURCE "sudo /scripts/suspendacct $USER &>> /var/log/execution.log ; sudo tail /var/log/execution.log "
echo -e "$ylw ========================================================================================================================================= $white"
echo ""
echo "$grn Details of the migrated account '$USER' in server '$DHOSTIP': $white"
echo ""
echo -e "$ylw ======================================================================================================================================== $white"
echo ""
sshtmp -q $WSS@$DEST "sudo touch domaininfo.txt ; echo $DOMAIN > domaininfo.txt ; sudo /scripts/ipusage | grep $DOMAIN | cut -d ' ' -f 1  >> domaininfo.txt ; sudo egrep 'ns1|ns2' /etc/wwwacct.conf | head -n2 | awk '{print $2}' >> domaininfo.txt ; echo "http://$DOMAIN.$DHOSTIP" >> domaininfo.txt ; sudo cat domaininfo.txt ; sudo cat /dev/null > domaininfo.txt ; sudo mv domaininfo.txt /tmp/"
echo ""
echo -e "$ylw ======================================================================================================================================== $white"
echo ""

#END
