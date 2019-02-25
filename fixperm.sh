# Main workhorse, fix perms per account passed to it
fixperms () {

  #Get account from what is passed to the function
  account=$1

  #Check account against cPanel users file
  if ! grep $account /var/cpanel/users/*
  then
    tput bold
    tput setaf 1
    echo "Invalid cPanel account"
    tput sgr0
    exit 0
  fi

  #Make sure account isn't blank
  if [ -z $account ]
  then
    tput bold
    tput setaf 1
    echo "Need an account name!"
    tput sgr0
    helptext
  #Else, start doing work
  else

#Get the account's homedir
