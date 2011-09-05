#!/bin/sh

# ������ ����������� ������� ��� ������� ������ �� FTP ���������� curl
# ������������ ��� ������������� ���������� �� ������ Perl (��������, ����� �� Flash).

hour=`date +%H`
ftp_host=192.168.1.1
ftp_auth="�����:������"
ftp_backup_store_path="/var/backups"

backup_dirs="/etc /usr/local/fsbackup"
backup_name="backup_router1"

tar czf - $backup_dirs | curl --upload-file - --user $ftp_auth ftp://$ftp_host/$ftp_backup_path/$backup_name-$hour.tar.gz
