#!/bin/bash
validateuser()
{
#sanitize
user=$(echo $1 | sed -e 's/[^a-z0-9]//g')
if [[ $user != $1 ]] || [[ ${#user} -gt 8 ]]; then
    msg="User value can be only [a-z0-9] and no more than 8 char"
    val="error"
else
for cpusers in system `ls /var/cpanel/users/ | grep $user`;do
    if [[ $user == $cpusers ]]; then
        msg="User Exist"
        val="yes"
    else
        msg="User Does not Exist"
        val="no"
    fi
done

for cpusers in root virtfs roundcube horde spamassassin eximstats cphulkd modsec all dovecot tomcat postgres mailman proftpd cpbackup files dirs tmp toor cpanel test virtfs munin latest git cpeasyapache system root nobody; do
    if [[ $user == $cpusers ]]; then
    msg="Invalid User"
    val="error"
    fi
done
fi
}
validateuser $1
echo "User: $user=$val: $msg"

#Note: this script not validate the users with numbers in the beginning, with the test word and finish with assword
