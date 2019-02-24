#!/bin/bash
# Author: Akhil P
# Script to fix permissions of cPanel accounts
# http://mrobot.online
# Usage: ./fixperm.sh cpaneluser

if [ "$#" -lt "1" ];then
  echo "Please input the user name: "
  exit;
fi

USER=$@

for user in $USER
do

  PATH=$(egrep "^${user}:" /etc/passwd | cut -d: -f6)

  if [ ! -f /var/cpanel/users/$user ]; then
    echo "$user user file missing, likely an invalid user"
  elif [ "$PATH" == "" ];then
    echo "Home directory not found for $user"
  else
    echo "Updating the ownership for $user"
    chown -R $user:$user $PATH
    chmod 711 $PATH
    chown $user:nobody $PATH/public_html $PATH/.htpasswds
    chown $user:mail $PATH/etc $PATH/etc/*/shadow $PATH/etc/*/passwd

    echo "Updating permission for $USER"
    
    find $PATH -type d -name cgi-bin -exec chmod 755 {} ; -print
    find $PATH -type f -exec chmod 644 {} ; -print
    find $PATH -type d -exec chmod 755 {} ; -print
  fi

done

chmod 750 $PATH/public_html

if [ -d "$PATH/.cagefs" ]; then
  chmod 775 $PATH/.cagefs
  chmod 700 $PATH/.cagefs/tmp
  chmod 700 $PATH/.cagefs/var
  chmod 777 $PATH/.cagefs/cache
  chmod 777 $PATH/.cagefs/run
  chmod 700 $PATH/.cagefs/opt
fi
