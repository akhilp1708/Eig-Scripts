PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/`whoami`/bin
# These variables hold the counters.
red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'
ylw=$'\e[1;33'


#FILE=$(echo $BACKUP | cut -d'/' -f3)

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
 
#Get the WSS username

WSS=`whoami`

#Step 1: Get the inputs from the user

read -p "$blu Enter the source server IP $white: " SOURCE
read -p "$blu Enter the destination server IP $white: " DEST
read -p "$blu Enter the cPanel username $white: " USER
echo ""
sleep 2s
read -p "$red Please verify the Source/Destination server IP and procceed? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
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

# Now login to the destination server and restore the package there

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

#Step 4: Verification of restoration. Checking if the domain exists after termination.

sudo /scripts/whoowns $DOMAIN &> temp.txt
RESULT="$(cat temp.txt)"
if [[  $RESULT == $USER ]]; then
    echo -e "$grn SUCCESS, VERFICATION OK! $white"
    echo ""
else
    echo -e "$red VERFICATION FAILED!!!!  CONTACT HPS!!!! $white"
    echo ""
fi
ENDSSH
#END
