#!/bin/bash
#Akhil P
#Add your backup dir location, password, mysql location and mysqldump location
DATE=$(date +%d-%m-%Y)
BACKUP_DIR="/backup/test-backup"
MYSQL_USER="root"
MYSQL_PASSWORD="***"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

# To create a new directory into backup directory location
mkdir -p $BACKUP_DIR/$DATE

# get a list of databases
databases=`$MYSQL -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"`

# dump each database in separate name
for db in $databases; do
echo $db
$MYSQLDUMP --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | gzip > "$BACKUP_DIR/$DATE/$db.sql.gz"
done
