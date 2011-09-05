#!/bin/sh
# ������������� �������� ���������� ������������ "user_name" � 
# ���� "database_name" �� ��������� ����.

CUR_PATH=/home/user/backup_rsync
date

# ������������� �������� ��������� ���� ������.
ulimit -v 200000

# ��������� ������������� ������ ���� rsync ���������.
IDLE=`ps -auxwww | grep "rsync" | grep -vE "grep|rsync_backup"`
if [ "$IDLE" != "" ];  then
    echo "FATAL DUP"| mail -s "FATAL RSYNC BACKUP DUP" admins@testhost.ru
exit
fi


/usr/local/pgsql/bin/pg_dump -c database_name |/usr/bin/gzip > ~/sql_dump.sql.gz

export RSYNC_RSH="ssh -c arcfour -o Compression=no -x"

# -n
/usr/local/bin/rsync -a -z -v --delete --max-delete=600 --bwlimit=50 \
  --backup --backup-dir=/home/backup_user/BACKUP_OLD_user_name \
  --exclude-from=$CUR_PATH/rsync.exclude \
  /home/user_name/ backup_user@backuphost.ru:/home/backup_user/BACKUP_user_name/
  
  
RETCODE=$?
if [ $RETCODE -ne 0 -a $RETCODE -ne 24 ]; then
	echo "Err code=$RETCODE"| mail -s "FATAL RSYNC BACKUP" admin@testhost.ru
fi
echo RET: $RETCODE
date
