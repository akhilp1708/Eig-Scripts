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
ylw=$'\e[1;33'

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

echo " $mag

Note:

Kindly make a note of the following before starting the migration on shared hosting.

1. Make sure that you are migrating the domain to a normal server or branded one which hosts the corresponding brand domains.
2. Do not migrate to a cross-branded server. You can check the branding details here.
   Ex: If the hosting is with HGI, then migrate the domain to the server which has HGI orders or HGI branded servers.
3. While updating BLL, make sure you specify the correct hostname. This is important as the BLL script will check the tempURL to verify the server hostname. There are 2 types of hostnames: *.webhostbox.net which is a normal server. *.brandservers.com which is a branded hostname.
If the server is a branded server, we should use the branded server hostname only. If you use  *.webhostbox.net for a branded server, the query to update BLL won't work.
$white
"

#Get the WSS username

#WSS=`whoami`
WSS=root
#Step 1: Get the inputs from the user

read -p "$blu Enter the Source server IP $white: " SOURCE
read -p "$blu Enter the Destination server IP $white: " DEST
read -p "$blu Enter the Main username $white: " USER
read -p "$blu Enter the Primary domain name $white: " DOMAIN
echo ""
sleep 2s
read -p "$red Please cross-check the Source/Destination server IP and other informations and procceed? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1


#Step 2: Generating and copying SSH keys for source and remote server

echo ""
yes "y" | ssh-keygen -t rsa -N "" -f source.key 2> /dev/null
echo""

echo "$blu Copying the key to source server $SOURCE .....$white"
echo ""

scp -o StrictHostKeyChecking=no -r source.key $WSS@$SOURCE:/$WSS/ 2> /dev/null
sshtmp -q -l $WSS $SOURCE /bin/bash  <<'EOF'
    sudo chmod 600 source.key
EOF

sleep 1s
echo "$blu Copying the public key to destination server $DEST .... $white"
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
echo "$mag Starting the backup generation of account $USER in source server $SOURCE... $white"
echo ""
ssh -o StrictHostKeyChecking=no -q $WSS@$SOURCE "sudo touch /var/log/execution.log ; sudo /scripts/pkgacct $USER  &>> /var/log/execution.log ; sudo tail /var/log/execution.log "
echo ""
sleep 1s 
echo "$grn Now copying the backup to destination server, please hold on.... $white" 

echo ""

ssh -o StrictHostKeyChecking=no -q $WSS@$SOURCE "rsync --stats -avz -e 'ssh -o StrictHostKeyChecking=no -q -i source.key' /home/cpmove-$USER.tar.gz $WSS@$DEST:/$WSS/"
echo ""
echo "$grn Copying of backup file completed. Now starting the restore process in destination server.. $white"
echo ""
ssh -o StrictHostKeyChecking=no -q $WSS@$DEST "sudo /usr/local/cpanel/scripts/restorepkg --force cpmove-$USER.tar.gz &>> /var/log/execution.log ; sudo tail /var/log/execution.log "

echo ""

echo  "$grn Restore completed in destination server! $white"

echo ""

echo "$grn Verifying, $white $mag if account $USER is migrated to destination server $DEST $white"
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

echo "$red Now suspending account in source server $SOURCE $white" ; echo ""
ssh -o StrictHostKeyChecking=no -q $WSS@$SOURCE "sudo /scripts/suspendacct $USER &>> /var/log/execution.log ; sudo tail /var/log/execution.log "
echo ""
echo "$grn Details of the migrated account $USER in new server $DEST: $white"
echo ""
ssh -o StrictHostKeyChecking=no -q $WSS@$DEST "echo "" ; sudo whmapi1 listaccts search=$USER searchtype=user | egrep 'domain: | shell: | ip' | grep -v ipv6"
echo ""
