#! /bin/bash
# unset any variable which system may be using

###############################################################################
# Variables to hold the color counters.
###############################################################################

red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'
ylw=$'\e[1;33m'

# clear the screen
clear

unset  os architecture kernelrelease loadaverage

while getopts iv name
do
        case $name in
          i)iopt=1;;
          v)vopt=1;;
          *)echo "Invalid arg";;
        esac
done

if [[ ! -z $iopt ]]
then
{
wd=$(pwd)
basename "$(test -L "$0" && readlink "$0" || echo "$0")" > /tmp/loadmon
loadmon=$(echo -e -n $wd/ && cat /tmp/loadmon)
su -c "cp $loadmon /usr/bin/loadmon" root && echo "$grn Congratulations! Script Installed, now run loadmon Command" $white || echo "$red Installation failed" $white
}
fi

if [[ ! -z $vopt ]]
then
{
echo -e "loadmon version 1.0\nDesigned by akhil.pra@endurance.com\nReleased Under GNU License" 
}
fi

if [[ $# -eq 0 ]]
then
{



###############################################################################
# START USER CONFIGURABLE VARIABLES
###############################################################################

EMAIL="akhilp1708@gmail.com"
DIR="/var/log/loadmon"

MAX_LOAD=`grep pro /proc/cpuinfo -c`
ONE_MIN_LOADAVG=`cut -d . -f 1 /proc/loadavg`

MEM_TOTAL=`grep ^MemTotal: /proc/meminfo | awk '{print $2}'`
MEM_FREE=`grep ^MemFree: /proc/meminfo | awk '{print $2}'`
let "MEM_USED = (MEM_TOTAL - MEM_FREE)"

SWAP_TOTAL=`grep ^SwapTotal: /proc/meminfo | awk '{print $2}'`
SWAP_FREE=`grep ^SwapFree: /proc/meminfo | awk '{print $2}'`
let "SWAP_USED = (SWAP_TOTAL - SWAP_FREE)"

# Swap Percentage calculation

if [ ! "$SWAP_USED" == 0 ] ; then
    PERCENTAGE_SWAP_USED=`echo $SWAP_USED / $SWAP_TOTAL | bc -l`
    TOTAL_PERCENTAGE=`echo ${PERCENTAGE_SWAP_USED:1:2}%`
else
    TOTAL_PERCENTAGE='0%'
fi

# Starting functions:

fetchinfo_basic()
{

echo "### BASIC SERVER STATUS ###" ; echo ""

# Check Load Average

echo -e "Number of cores & the maximum allowed load on the server :" $MAX_LOAD
echo -e "The 1 minute load avg on the server is :" $ONE_MIN_LOADAVG


# Check System Uptime
tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e "System Uptime Days/(HH:MM) : " $tecuptime

# Check Logged In Users
who>/tmp/who
echo -e "Logged In users :"  && cat /tmp/who 

# Check if connected to Internet or not
ping -c 1 google.com &> /dev/null && echo -e "Internet: Connected" || echo -e "Internet: Disconnected"

# Check OS Type
os=$(uname -o)
echo -e "Operating System Type :" $os

# Check OS Release Version and Name
cat /etc/*release | grep 'NAME\|VERSION' | grep -v 'VERSION_ID' | grep -v 'PRETTY_NAME' > /tmp/osrelease

# Check Kernel Release
kernelrelease=$(uname -r)
echo -e "Kernel Release :" $kernelrelease

# Check hostname
echo -e "Hostname :" $HOSTNAME

# check processes
MAX_PROCS_CHECK=`ps aux | wc -l`
echo -e "Total process count :" $MAX_PROCS_CHECK

# Check RAM and SWAP Usages

echo -e "Memory Total : $MEM_TOTAL kb"
echo -e "Memory Used : $MEM_USED kb"
echo -e "Swap Total: $SWAP_TOTAL kB"
echo -e "Swap Ssed: $SWAP_USED kB"

}


echo "$blu #### STARTING LOAD MONITORING #### $white"

# Logo for script:

echo ""
cat << "EOF"
||       _ _          
L_]oad  //\/\on  v:1.0
EOF


#  Applying condition

if [[ $ONE_MIN_LOADAVG -eq $MAX_LOAD ]] || [[ $ONE_MIN_LOADAVG -lt $MAX_LOAD ]];
then
echo ""
echo -e "$grn The CPU Load is normal. So killing the Script LoadMon!" $white
exit 1
else
    echo -e "$red THE LOAD IS HIGH: " $white $ONE_MIN_LOADAVG
    echo "" ; echo "$grn Starting the investigation.. $white"
    echo -e "$grn The logs will placed under $DIR " $white
    if [[ -d "$DIR" ]]
    then
        cd $DIR
    else
        mkdir -p $DIR ; chmod 700 $DIR ; cd $DIR
    fi

echo "`date`" >> monitoring.log && echo ".........................." >> monitoring.log && echo "$(fetchinfo_basic)" >> monitoring.log && echo ".........................." >> monitoring.log



fetchinfo_MEM()
{

# Fetching the top result in arranged manner

TOPR=`nice top -c -n 1 -b | head -n 30`
echo ".........................."
echo "Showing the active running processes in server in sorted:" ; echo ""
echo "$TOPR"
echo ".........................."

# Fetching the most of active running processes

PSR=`ps auxwwwf`
echo ".........................."
echo "The most of active running processes:" ; echo ""
echo "$PSR"
echo ".........................."

# Disk usage statics 2times in 1 sec

DUS=`iostat -x 1 2`
echo ".........................."
echo "The active disk usage statics:" ; echo ""
echo "$DUS"
echo ".........................."

# Fetching the tabulated memory usage

PS_MEM=`ps -eo 'user,rss' --no-headers --sort=user | awk -v t=$(grep -oP "(?<=^MemTotal:).+(?=kB)" /proc/meminfo|awk '{print $1}') '{A[$1]+=$2;next} END {for(i in A){ printf "%s %.2fMB %.2f'%'\n", i,A[i]/1024,(A[i]/t)*100}}'|sort -nrk2|head|sed '1iUser Memory(MB) Percent\n'|column -t|sed '1i===================================\n     TABULATED MEMORY USAGE:\n==================================='|sed '5i--------------------------------'`

echo "$PS_MEM"
echo ".........................."

PS_CPU=`ps -e -o pcpu,pid,user,args|sort -k1 -nr|head -10`
echo "TOP 10 CPU usage process with user:" ; echo ""
echo "$PS_CPU"
echo ""
# Finding the culprit user responsible for most of the RAM usage.

PS_USER=`ps -eo uname,pid,ppid,time,cmd,%mem,%cpu --sort=-%mem | head -n 2 | tail -n 1 | awk '{print $1}'`


echo "Most of the Memory is used by user : $PS_USER" ; echo ""
echo ".........................."

# List the openfiles used by the culprit user. 

if [ -f /var/cpanel/users/$PS_USER ];
then
    lsof -p `ps -eo uname,pid,ppid,time,cmd,%mem,%cpu --sort=-%mem | head -n 2 | tail -n 1 | awk '{print $2}'` 
    echo ".........................."
exit 0
fi

}


# Run function 
echo "`date`" >> monitoring.log && echo ".........................." >> monitoring.log && echo "$(fetchinfo_MEM)" >> monitoring.log && echo ".........................." >> monitoring.log

fetchinfo_OOM()
{
TEST_OOM_INTERVAL=5;
LATEST_OOM="$(less /var/log/messages | grep -i "OOM-killer" | tail -n 1)";
LATEST_OOM_TIME=${LATEST_OOM:0:15};
echo $LATEST_OOM_TIME
echo "### OUT OF MEMORY STATUS ###" ; echo ""
if [ -n "${LATEST_OOM_TIME}" ]
then
    if [[ $(($((`date +%s` - `date --date="${LATEST_OOM_TIME}" +%s`)) / 60 )) -le ${LATEST_OOM_INTERVAL} ]]
        then
        echo "CRITICAL: OOM within last ${LATEST_OOM_INTERVAL} minutes!"
        echo ${LATEST_OOM}
        exit 2
    else
        echo "OK: Recent OOM but outside last ${LATEST_OOM_INTERVAL} minutes"
        echo "LATEST_OOM: ${LATEST_OOM}"
        exit 0
    fi
else
    echo "OK: No recent OOM"
    exit 0
fi
}

echo "`date`" >> monitoring.log && echo ".........................." >> monitoring.log && echo "$(fetchinfo_OOM)" >> monitoring.log && echo ".........................." >> monitoring.log

fetchinfo_MYSQL()
{
echo "Reported at `date`"
echo "### MYSQL STATUS ###" ; echo ""
mysqladmin extended-status | grep -i "max_used" | awk '{print $2,$4}' 
mysqladmin extended-status | grep  "Connections" | awk '{print $2,$4}' 
mysqladmin proc stat 
}


#Report the MYSQL usage in the server
echo "`date`" >> monitoring.log && echo ".........................." >> monitoring.log && echo "$(fetchinfo_MYSQL)" >> monitoring.log && echo ".........................." >> monitoring.log


fetchinfo_WEB()
{
WEB=`/usr/local/apache/bin/apachectl fullstatus`
echo "+----------------------------------------------+" 
echo " Displaying the current Apache detailed status:" 
echo "+----------------------------------------------+" 
cat "$WEB"

WEBP=`grep POST /home/*/access-logs/* | awk '{print $1}' | sort | uniq -c| sort -n | tail -n 20`
WEBG=`grep GET /home/*/access-logs/* | awk '{print $1}' | sort | uniq -c| sort -n | tail -n 20`
DOML=`find /usr/local/apache/domlogs/*/ -type f -mtime -1| grep -v -E 'ftp.|bytes_log|ssl_log' | xargs cat | grep `date +%d/%b/%Y` | awk '{print "times --> "$1,$7}' | sort | uniq -c | sort -n | tail -n 50`
echo "The total number of POST requests to accounts with orgin IP addresses:"
cat "$WEBP"
echo ""
echo "The total number of GET requests to accounts with orgin IP addresses:"
cat "$WEBG"
echo ""
echo "The total number accesses to account files from remote IP's:"
cat "$DOML"
}
 
#The connections to different ports in the server

fetchinfo_NW()
{
echo "+++++++++++++++++++++++++++++++++++" 
echo "Reported at `date`" 
echo "+++++++++++++++++++++++++++++++++++" 
echo "### NETWORK CONNECTION STATUS ###" ; echo ""
echo "+----------------------------------------------+" 
echo " Listening Ports/IP with the list of services:" 
echo "+----------------------------------------------+" 
echo "`netstat -plant | head |egrep -v '^(Active|Proto)' | awk '{ip=$5; sub(/:[^:]+/,"",ip); service=$7; sub(/[^:][^:][^:][^:]/,"",service); print ip,service}'`" 
echo "+----------------------------------------------+" 
echo " The number of connections from different IPs" 
echo "+----------------------------------------------+" 
echo "`netstat -plane | head | egrep -v '^(Active|Proto)' | awk '{print $5}' | rev | cut -d":" -f2 | rev | sort | uniq -c | sort -n`" 
}
 
# Reporting the connections in the server
echo "`date`" >> monitoring.log && echo ".........................." >> monitoring.log && echo "$(fetchinfo_NW)" >> monitoring.log && echo ".........................." >> monitoring.log

fi

# EMAIL ALERT

send_alert()
{
    SUBJECTLINE="`hostname` [CPU Load is high : $ONE_MIN_LOADAVG] [RAM used : $MEM_USED ] [Swap Use: $TOTAL_PERCENTAGE ] [Total Process: $MAX_PROCS_CHECK ]"
    cat /var/log/loadmon/monitoring.log | mail -s "$SUBJECTLINE" $EMAIL 
    echo -e "$ylw Notification email sent to $EMAIL $white"
    echo -e "$ylw HAPPY TROUBLESHOOTING ! $white"
    exit
}


if   [ $ONE_MIN_LOADAVG -gt $MAX_LOAD      ] ; then send_alert
fi


# Unset Variables
unset  os architecture kernelrelease loadaverage

# Remove Temporary Files
rm -rf /tmp/osrelease /tmp/who /tmp/loadmon

}
fi
shift $(($OPTIND -1))
