#!bin/bash
#Author: Akhil P
#Script to migrate single cpanel account to remote server by exchanging the ssh keys
/usr/bin/clear
ERR_MSG=""
PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/`whoami`/bin
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
 #  ssh + scp without storing or prompting for keys.
 #
 function sshtmp
 {
     ssh -o "ConnectTimeout 3" \
         -o "StrictHostKeyChecking no" \
         -o "UserKnownHostsFile /dev/null" \
              "$@"
 }
 
echo "
Note:

Kindly make a note of the following before starting the migration on shared hosting. 
 
1. Make sure that you are migrating the domain to a normal server or branded one which hosts the corresponding brand domains. 
 
2. Do not migrate to a cross-branded server. You can check the branding details here.
   Ex: If the hosting is with HGI, then migrate the domain to the server which has HGI orders or HGI branded servers. 
 
3. While updating BLL, make sure you specify the correct hostname. This is important as the BLL script will check the tempURL to verify the server hostname. There are 2 types of hostnames: *.webhostbox.net which is a normal server. *.brandservers.com which is a branded hostname. 
 
If the server is a branded server, we should use the branded server hostname only. If you use  *.webhostbox.net for a branded server, the query to update BLL won't work.
"

#Get the WSS username

WSS=`whoami`

#Step 1: Get the inputs from the user

read -p "$blu Enter the Source server IP $white: " SOURCE
read -p "$blu Enter the Destination server IP $white: " DEST
read -p "$blu Enter the Main username $white: " USER
read -p "$blu Enter the Primary domain name $white: " DOMAIN
read -p "$blu Enter the Ticket-ID $white: " TICKET
echo ""
sleep 2s
read -p "$red Please cross-check the Source/Destination server IP and other informations and procceed? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
sleep 4s

#Step 2: Generating and copying SSH keys between the source and remote server

KEY="cat /home/$WSS/.ssh/id_dsa.pub"

ssh -q -l $WSS $SOURCE 'bash -s' <<'ENDSSH'
    echo "Generating SSH keys : "
    echo "Please press 'ENTER' and keep the default location"
    sudo ssh-keygen   
    echo "`cat $KEY`" >> KEYCODE.txt
    VAR="$(sudo cat KEYCODE.txt)"                                                                    
ENDSSH

sleep 4s
echo ""
echo "Putting your key on $DEST... "   
echo ""

ssh -q -l $WSS $DEST 'bash -s' <<'ENDSSH'
    echo $VAR >> ~/.ssh/authorized_keys
ENDSSH

ssh -q -l $WSS $SOURCE 'bash -s' <<'ENDSSH'
    sudo ssh -q $WSS@$DEST  && echo SUCCESS || echo Failed
ENDSSH

#Step 3: Login to source server and take a pkgacct and do the rsync

echo ""
echo "Now generating the backup of the account $USER "
echo ""

ssh -q -l $WSS $SOURCE 'bash -s' <<'ENDSSH'
sudo touch /var/log/temp.log
sudo /scripts/pkgacct $USER &>> /var/log/temp.log 
sudo tail /var/log/temp.log
sleep 4s
echo "Backup generation complete..!"
echo ""
echo "Copying backup to $DEST server, using rsync...."
sudo rsync -avzP /home/cpmove-$USER.tar.gz -e "ssh -i .ssh/id_rsa" $WSS@$DEST:/home/$WSS/
echo ""
sleep 2s
echo "Copying complete"
echo ""
ENDSSH

#Step 4:  Now login to the destination server and restore the package there

ssh -q -l $WSS $DEST 'bash -s' <<'ENDSSH'
sudo touch /var/log/temp.log
echo "Restore in progress..."
sleep 2s
sudo /scripts/restorepkg /home/cpmove-$USER.tar.gz &>> /var/log/temp.log 
sleep 2s
sudo tail /var/log/temp.log.log
echo "Restoring the backup in destination server $DEST completed"
echo ""
sleep 2s
echo "Verifying...."
echo ""

#Step 5: Verification of restoration. Checking if the domain exists after termination.

sudo /scripts/whoowns $DOMAIN &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS, VERFICATION OK! $white"
    echo ""
else
    echo -e "$red VERFICATION FAILED!!!!  CONTACT HPS!!!! $white"
    echo ""
    read -p "$red If verification failed then input 'N' $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi
ENDSSH

#Step 6: suspend the user on the source server. Make sure to specify the reason for suspension.

ssh -q -l $WSS $SOURCE 'bash -s' <<'ENDSSH'
echo ""
sudo /scripts/suspendacct $USER "Migrated to a different server - $TICKET"
echo ""
sleep 4s
echo "ACCOUNT SUSPENDED IN SOURCE SERVER"
echo ""
ENDSSH

# Step 7: delete the public key from the target server after finishing the migration

# The below loop removes the key containing some unique string or just deletes the authorized_keys file when no other key remains

ssh -q $DEST
if test -f $HOME/.ssh/authorized_keys; then
  if grep -v "some unique string" $HOME/.ssh/authorized_keys > $HOME/.ssh/tmp; then
    cat $HOME/.ssh/tmp > $HOME/.ssh/authorized_keys && rm $HOME/.ssh/tmp;
  else
    rm $HOME/.ssh/authorized_keys && rm $HOME/.ssh/tmp;
  fi;
fi

sleep 3s
echo "Public key removed from destination server $DEST"
sleep 3s
echo ""
echo "Now please update the new server details in OBEE using the HOSTING SYNC TOOL in support account according to the brand"
echo ""
#END
