#!/bin/sh
# Script for backup SQL tables from MySQL
# ������ ��� ������ ������ �������� � Mysql.
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>
#
# For restore data type:
# �������������� ������������ � ������� �������: mysql < backupfile
#

#-------------------
# Name of backup, single word.
# ��� ������.
#-------------------

backup_name="test_host"


#-------------------
# Backup method:
# full - backup full DB's structure and data.
# db   - backup full DB's structure and data only for 'backup_db_list' databases.
# notdb- backup full DB's structure and data for all DB's, except 
#        data of 'backup_db_list' databases.
#
# ����� ������:
# full	- ������ ����� ���� ��� (�������������), 
#	 ������ ������� pg_dumpall ��� mysqldump --all-databases --all
#
# db    - ����� ������ ��������� � backup_db_list ��� ������, ������ �� 
#	  ������������� ��� � ������ ������������ ��� ���� ��� �� SQL �������.
# notdb  - ����� ���� ���, ����� ��������� � backup_db_list, ������ �� 
#	   ������������� ��� � ������ ������������ ��� ���� ��� �� SQL �������.
#          �������� ���������� �� ������  ���������� ������, ����� ������ 
#	   ������ ����������� ������ �������� � ����: 
#	   "trash_db1 trash_db2:table1 trash_db2:table2"
#          - ���������� ����� ���� ���, ���� ���� trash_db1 � ������ table1 � 
#	   table2 ���� trash_db2.
#
#-------------------

backup_method="notdb"


#-------------------
# List of databases (delimited by spaces)
# ������ ���������� ��� ����������� �� ������ ���, ����� ������.
# ������� ����������� � ����: ���_����:���_�������
#-------------------

backup_db_list="aspseek trash:cache_table1 trash:cache_table2 mnogosearch"


#-------------------
# Auth information for MySQL.
# ��� ������������ � ������ ��� ���������� � Mysql, ��� PostgreSQL ������ 
# ������ ����������� ��-��� ������������ � ������� ������� ������� � ����� PostgreSQL.
#-------------------

backup_mysqluser=""
backup_mysqlpassword=""


#-------------------
# Directory to store SQL backup. You must have enought free disk space to store 
# all data from you SQL server.
# ���������� ���� ����� ������� ����� ������ � SQL �������. 
# �������� !!! ������ ���� ���������� ���������� ����� ��� ������ ���� 
# ��������� ��.
#-------------------

backup_path="/usr/local/fsbackup/sys_backup"


#-------------------
# Full path of mysql programs.
# ���� � ���������� mysql
#-------------------

backup_progdump_path="/usr/local/mysql/bin"

#-------------------
# Extra flags for mysqldump program. 
# -c (--complete-insert) - Use complete insert statements.
# �������������� ��������� ��� pg_dump
# -c - ����������� ����� ������ � ���� INSERT �������, � ��������� ��������
#      ��������. ���� �������� �������������� �� ������ � ������ ������
#      ����� �����, � �������������� � ������� ���� ����� ����������, 
#      �����������: extra_mysqldump_flag=""
#-------------------

extra_mysqldump_flag="--complete-insert"

############################################################################

if [ -n "$backup_progdump_path" ]; then
    backup_progdump_path="$backup_progdump_path/"
fi

#-------------------------------------------------------------------------
# ������ ����� ��� Mysql
if [ "_$backup_method" = "_full" ]; then
    echo "Creating full backup of all MySQL databases."
    ${backup_progdump_path}mysqldump --all --add-drop-table --all-databases --force --no-data $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser > $backup_path/$backup_name-struct-mysql
    ${backup_progdump_path}mysqldump --all-databases --all --add-drop-table --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser |gzip > $backup_path/$backup_name-mysql.gz
    exit
fi

#-------------------------------------------------------------------------
# ����� ��������� ��� ��� Mysql
if [ "_$backup_method" = "_db" ]; then
    echo "Creating full backup of $backup_db_list MySQL databases."
    ${backup_progdump_path}mysqldump --all --add-drop-table --all-databases --force --no-data $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser > $backup_path/$backup_name-struct-mysql
    cat /dev/null > $backup_path/$backup_name-mysql

    for cur_db in $backup_db_list; do
	echo "Dumping $cur_db..."
	cur_db=`echo "$cur_db" | awk -F':' '{if (\$2 != ""){print \$1, \$2}else{print \$1}}'`
	${backup_progdump_path}mysqldump --all --add-drop-table --databases --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser $cur_db	>> $backup_path/$backup_name-mysql
    done
    gzip -f $backup_path/$backup_name-mysql
    exit
fi

#-------------------------------------------------------------------------
# ����� ���� ��� ����� ��������� ��� Mysql
if [ "_$backup_method" = "_notdb" ]; then
    echo "Creating full backup of all MySQL databases except databases $backup_db_list."
    ${backup_progdump_path}mysqldump --all --add-drop-table --all-databases --force --no-data $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser > $backup_path/$backup_name-struct-mysql
    cat /dev/null > $backup_path/$backup_name-mysql
    
    for cur_db in `${backup_progdump_path}mysqlshow --password=$backup_mysqlpassword --user=$backup_mysqluser| tr -d ' |'|grep -v -E '^Databases$|^\+\-\-\-'`; do

	grep_flag=`echo " $backup_db_list"| grep " $cur_db:"`
	if [ -n "$grep_flag" ]; then
# ���������� ������ ��� ������ ����
	    ${backup_progdump_path}mysqldump --all --add-drop-table --databases --no-create-info --no-data --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser $cur_db >> $backup_path/$backup_name-mysql

	    for cur_db_table in `${backup_progdump_path}mysqlshow --password=$backup_mysqlpassword --user=$backup_mysqluser $cur_db| tr -d ' |'|grep -v -E '^Tables$|^Database\:|^\+\-\-\-'`; do

		flag=1
		for cur_ignore in $backup_db_list; do
		    if [ "_$cur_ignore" = "_$cur_db:$cur_db_table" ]; then
			flag=0
		    fi
    		done

		if [ $flag -gt 0 ]; then
		    echo "Dumping $cur_db:$cur_db_table..."
		    ${backup_progdump_path}mysqldump --all --add-drop-table --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser $cur_db $cur_db_table >> $backup_path/$backup_name-mysql

		else
		    echo "Skiping $cur_db:$cur_db_table..."
		fi
	    done
	else
# ���������� ����
	    flag=1
	    for cur_ignore in $backup_db_list; do
		if [ "_$cur_ignore" = "_$cur_db" ]; then
		    flag=0
		fi
	    done

	    if [ $flag -gt 0 ]; then
		echo "Dumping $cur_db..."
		${backup_progdump_path}mysqldump --all --add-drop-table --databases --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser $cur_db >> $backup_path/$backup_name-mysql
	    else
		echo "Skiping $cur_db..."
	    fi
	fi
    done
    gzip -f $backup_path/$backup_name-mysql
    exit
fi

echo "Configuration error. Not valid parameters in backup_method or backup_sqltype."


