#!/bin/sh
#Author: Akhil P
max_cpu="80" # Set to max cpu.

# Set to apache restart command.
httpd_restart() {
/sbin/service httpd restart
}

# Set to mysqld restart command.
mysql_restart() {
/sbin/service mysqld restart
}

################## DONT TOUCH ##################

cpu_usage_apache=$(ps xua | grep -i apache | awk '{print $3}' | sed -e '/%CPU/d' | sort -nr)
cpu_usage_mysql=$(ps xua | grep -i mysql | awk '{print $3}' | sed -e '/%CPU/d' | sort -nr)

for i in $cpu_usage_apache; do

if [ "$i" > "$max_cpu" ]; then
$httpd_restart
else
echo >/dev/null
fi
done

for i in $cpu_usage_mysql; do

if [ "$i" > "$max_cpu" ]; then
$mysql_restart
else
echo >/dev/null
fi
done
