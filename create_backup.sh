#!/bin/sh
# Backup planner running from crontab.
# ������ ��� ������� backup ���������� �� crontab.
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>
#
# ������ ������ ��� crontab:
#
#18 4 * * * /usr/local/fsbackup/create_backup.sh| mail -s "`uname -n` backup report" root

#--------------------------------------
# Path where fsbackup installed.
# ���������� ��� ����������� ���������.
#--------------------------------------

backup_path="/usr/local/fsbackup"


#--------------------------------------
# List of fsbackup configuration files, delimited by spaces.
# Directories for saving backup in each configuration file should differ 
# ($cfg_remote_path, $cfg_local_path).
#
# ������ ������ ������������, ����������� ��������.
# ���������� ��� ���������� ������ � ������ ���������������� �����
# ������ ���������� ($cfg_remote_path, $cfg_local_path), ���������� � ����� �
# ����� ���������� ����������, ��������� ������� .conf �������, ������� �� 
# ���������.

#--------------------------------------

config_files="cfg_example cfg_example_local cfg_example_users cfg_example_root"


#--------------------------------------
# 1 - run mysql_backup.sh script (you need edit mysql_backup.sh first!), 0 - not run.
# ���� ������ MySQL ������, ����������� ��������� ��������������� ���������
# ������ ./scripts/mysql_backup.sh, 1 - ���������, 0 - �� ���������. 
#--------------------------------------

backup_mysql=0

#--------------------------------------
# 1 - run pgsql_backup.sh script (you need edit pgsql_backup.sh first!), 0 - not run.
# ���� ������ PostgreSQL ������, ����������� ��������� ��������������� ���������
# ������ ./scripts/pgsql_backup.sh, 1 - ���������, 0 - �� ���������. 
#--------------------------------------

backup_pgsql=0

#--------------------------------------
# 1 - run sqlite_backup.sh script (you need edit sqlite_backup.sh first!), 0 - not run.
# ���� ������ SQLite ������, ����������� ��������� ��������������� ���������
# ������ ./scripts/sqlite_backup.sh, 1 - ���������, 0 - �� ���������. 
#--------------------------------------

backup_sqlite=0


#--------------------------------------
# 1 - run sysbackup.sh script (you need edit sysbackup.sh first!), 0 - not run.
# ���� ������ ���������� �������, ����������� ��������� ��������������� 
# ��������� ������ ./scripts/sysbackup.sh, 1 - ���������, 0 - �� ���������. 
#--------------------------------------

backup_sys=0



#############################################################################
# ������ �� ���������� ������� ���� ����� fsbackup.pl
IDLE=`ps -auxwww | grep fsbackup.pl | grep -v grep`
if [ "$IDLE" != "" ];  then
    echo "!!!!!!!!!!!!!!! `date` Backup dup"
    exit
fi
	

cd $backup_path

# ������� ulimit ����� ������������, �� ������ ������.
#ulimit -f 512000;ulimit -d 20000;ulimit -c 100;ulimit -m 25000;ulimit -l 15000

# ��������� MySQL ����
if [ $backup_mysql -eq 1 ]; then
    ./scripts/mysql_backup.sh 
fi

# ��������� PostgreSQL ����
if [ $backup_pgsql -eq 1 ]; then
    ./scripts/pgsql_backup.sh 
fi

# ��������� SQLite ����
if [ $backup_sqlite -eq 1 ]; then
    ./scripts/sqlite_backup.sh 
fi

# ��������� ��������� ���������
if [ $backup_sys -eq 1 ]; then
    ./scripts/sysbackup.sh
fi

# �����.
for cur_conf in $config_files; do
    ./fsbackup.pl ./$cur_conf
    next_iter=`echo "$config_files"| grep "$cur_conf "`
    if [ -n "$next_iter" ]; then
	sleep 600 # �������� �� 10 �����, ���� ���������� ������ :-)
    fi
done

