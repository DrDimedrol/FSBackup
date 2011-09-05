#!/usr/bin/perl

# ������ ��� ������ ������ � ������� ��������� ���������� fsbackup             
# Copyright (c) 2001 by Alex Sokoloff. <sokoloff@mail.ru>   
#                                                           
# ������� ��� fsbackup                                      
# http://www.opennet.ru/dev/fsbackup/                       
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>       

#############################################

my $type="list";
my $extract=0;
$cfg_cache_dir = "./";
my $findfile;

# ��������� ���������� ��������� ������
while (@ARGV){
    $arg= shift (@ARGV);
    if 	  ($arg eq "-h" or $arg eq "--help") {&help}		
    elsif ($arg eq "-d" or $arg eq "--del")  { $type="del"}	
    elsif ($arg eq "-c" or $arg eq "--cfgfile")  {
	    $config = shift (@ARGV);
	    require "$config" if ( -f $config );
    	}
    elsif ($arg eq "-p" or $arg eq "--path")  {
	$cfg_cache_dir=shift (@ARGV);
	}
    elsif ($arg eq "-m" or $arg eq "--mask")  {	
	$cfg_backup_name = shift (@ARGV);
	}
    else {$findfile="$arg"}
}

if ($findfile eq '') {
    print "�� ������ ������� ����\n";
    &help;
}

if ( ! -d $cfg_cache_dir ) {print "�����������: $cfg_cache_dir �� �������\n"; &help}

@files=sort {$b cmp $a} glob("$cfg_cache_dir/$cfg_backup_name*.$type" );
if ($#files <0) {
    print "� ����������� $cfg_cache_dir �� ������ �� ���� ���� $cfg_backup_name.$type\n";
    exit;    
}

# ��������� ���������� ��������� 
$findfile=~ s/\./\\\./g;
$findfile=~ s/\*/\.\+/g;    
$findfile=~ s/\_/\./g;        

# ���������� ����� � ������ �����������    
foreach $f (@files){
    open (FILE, "$f");
    $tmp ="$f\n";

    while (<FILE>){
	chomp;
	if (/$findfile/i){ $tmp.="\t$_\n";}
    }
    
    if ($tmp ne "$f\n" ){ 
	$tmp=~ s/^$cfg_cache_dir\///;
    	print "$tmp\n"; 
    }		
}

exit;

sub help{
print qq|Usage: fsfind  [OPTION]...  FILE
���� FILE � ������� ��������� � fsbackup, � ����� ����� �����������
������������� ���������� ���������:
  *   ����� ���������� ����� ��������
  _   ����� ��������� ������

�����:
  -d, --del	      	������ ��������� �����
  -p, --path ����	���� � ����������� � ��������, ���� �� �������,
                         �� ����� ������� � ������� �����������
  -m, --mask            ����� ��� ���� ������ ������� � ������� ������������ 
                         �����
  -c, --cfgfile ����    ���� ������������ fsbackup � ������� ��������� 
			 ����������� � �������� � ��� ����� ������
  -h, --help	    	������� ��� ��������� � �����

|;
    exit;                                                                     
}

