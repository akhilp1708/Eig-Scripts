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
 function scptmp
 {
     exec scp -o "ConnectTimeout 3" \
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
read -p "$blu Enter the Ticket-ID $white: " TICKET
echo ""
sleep 2s
read -p "$red Please cross-check the Source/Destination server IP and other informations and procceed? $white (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
sleep 2s

#Step 2: Generating and copying SSH keys for source and remote server
echo ""
yes "y" | ssh-keygen -t rsa -N "" -f source.key
echo""

#String

#cat source.key.pub | awk '{print $2}' > string.txt
STRING=$(cat string1.txt)

echo "Copying the key to source server $SOURCE ....."
echo ""

scp -r source.key $WSS@$SOURCE:/$WSS/
sshtmp -q -l $WSS $SOURCE /bin/bash  <<'EOF'
    sudo chmod 600 source.key
EOF

sleep 2s
echo "Copying the public key to destination server $DEST ...."
echo ""

# Echo the public key to the destination server, also using uniq and sort we get the uniq entries only from authorised_keys, this is to avoid duplicate entries.

scp -r source.key.pub $WSS@$DEST:/$WSS/


sshtmp -q -l $WSS $DEST /bin/bash  <<'EOF'
    cat source.key.pub >>  ~/.ssh/authorized_keys
    sort ~/.ssh/authorized_keys | uniq > ~/.ssh/authorized_keys.uniq
    yes | mv ~/.ssh/authorized_keys{.uniq,}
EOF

sleep 2s
echo "Keys exchanged !"
echo ""
echo "Verifying the working of keys !"
echo ""

scp -r string.txt $WSS@$DEST:/$WSS/
sshtmp -tt -q -l $DEST /bin/bash <<'EOF'
echo "$(cat string.txt | awk '{print $2}' > string1.txt)"
STRING=$(cat string1.txt)
echo \$STRING
sed -i.bak '/$STRING/d' ~/.ssh/authorized_keys
EOF


#sshtmp -n -q -l $WSS $SOURCE /bin/bash "ssh -i source.key $WSS@$DEST 'echo success'"
