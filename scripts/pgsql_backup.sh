#!/bin/sh
# Script for backup SQL tables from PostreSQL
# ������ ��� ������ ������ �������� � PostgreSQL
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>
#
# For restore data type:
# �������������� ������������ � ������� �������: psql -d template1 -f backupfile
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
# Full path of postgresql programs.
# ���� � ���������� postgresql 
#-------------------

backup_progdump_path="/usr/local/pgsql/bin"

#-------------------
# Extra flags for pg_dump program. 
# -D - Dump data as INSERT commands with  explicit  column names
# �������������� ��������� ��� pg_dump
# -D - ����������� ����� ������ � ���� INSERT �������, � ��������� ��������
#      ��������. ���� �������� �������������� �� ������ � ������ ������
#      ����� �����, � �������������� � ������� ���� ����� ����������, 
#      �����������: extra_pg_dump_flag=""
#-------------------

extra_pg_dump_flag="-D"

############################################################################

if [ -n "$backup_progdump_path" ]; then
    backup_progdump_path="$backup_progdump_path/"
fi

#-------------------------------------------------------------------------
# ������ ����� ��� Postgresql
if [ "_$backup_method" = "_full" ]; then
    echo "Creating full backup of all PostgreSQL databases."
#    ${backup_progdump_path}pg_dumpall -s > $backup_path/$backup_name-struct-pgsql
    ${backup_progdump_path}pg_dumpall $extra_pg_dump_flag|gzip > $backup_path/$backup_name-pgsql.gz
    exit

fi

#-------------------------------------------------------------------------
# ����� ��������� ��� ��� Postgresql
if [ "_$backup_method" = "_db" ]; then
    echo "Creating full backup of $backup_db_list PostgreSQL databases."
#    ${backup_progdump_path}pg_dumpall -s > $backup_path/$backup_name-struct-pgsql
    cat /dev/null > $backup_path/$backup_name-pgsql

    for cur_db in $backup_db_list; do
	echo "Dumping $cur_db..."
	cur_db=`echo "$cur_db" | awk -F':' '{if (\$2 != ""){print "-t", \$2, \$1}else{print \$1}}'`
	${backup_progdump_path}pg_dump $extra_pg_dump_flag $cur_db >> $backup_path/$backup_name-pgsql
    done
    gzip -f $backup_path/$backup_name-pgsql

    exit

fi

#-------------------------------------------------------------------------
# ����� ���� ��� ����� ��������� ��� Postgresql
if [ "_$backup_method" = "_notdb" ]; then
    echo "Creating full backup of all PostgreSQL databases except databases $backup_db_list."
#    ${backup_progdump_path}pg_dumpall -s > $backup_path/$backup_name-struct-pgsql
    cat /dev/null > $backup_path/$backup_name-pgsql

    for cur_db in `${backup_progdump_path}psql -A -q -t -c "select datname from pg_database" template1 | grep -v '^template[01]$' `; do

	grep_flag=`echo " $backup_db_list"| grep " $cur_db:"`
	if [ -n "$grep_flag" ]; then
# ���������� ������ ��� ������ ����
	    for cur_db_table in `${backup_progdump_path}psql -A -q -t -c "select tablename from pg_tables WHERE tablename NOT LIKE 'pg\_%' AND tablename NOT LIKE 'sql\_%';" $cur_db`; do

		flag=1
		for cur_ignore in $backup_db_list; do
		    if [ "_$cur_ignore" = "_$cur_db:$cur_db_table" ]; then
			flag=0
		    fi
    		done

		if [ $flag -gt 0 ]; then
		    echo "Dumping $cur_db:$cur_db_table..."
		    ${backup_progdump_path}pg_dump $extra_pg_dump_flag -t $cur_db_table $cur_db >> $backup_path/$backup_name-pgsql
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
		${backup_progdump_path}pg_dump $extra_pg_dump_flag $cur_db >> $backup_path/$backup_name-pgsql
	    else
		echo "Skiping $cur_db..."
	    fi
	fi
    done
    gzip -f $backup_path/$backup_name-pgsql
    exit
fi

echo "Configuration error. Not valid parameters in backup_method or backup_sqltype."


