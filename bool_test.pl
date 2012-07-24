#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use POSIX qw(strftime);
use Switch;
use Time::HiRes qw ( time );

use threads;
use threads::shared;

my $user='root';
my $password='XXXXX';
my $datadir='/mysql/';
my @threads;
my @tables = ('t_char_boolean', 't_tinyint_boolean', 't_bool_boolean', 't_enum_boolean');

my $dbh = DBI->connect("dbi:mysql:booltest;host=localhost;mysql_socket=$datadir/mysql.sock", 'root', $password) or die('Cannot connect');

# Check the tables to ensure we have enough data in them
foreach my $table (@tables) {
	while (is_insert($table)) {
		my $bool = int(rand(1)+0.5);
		switch ( $table ) {
			# Different inserts based on table name
			case 't_char_boolean' {
				my $stmt;
				if ($bool) {
					$stmt = $dbh->prepare("INSERT INTO $table (bool_col, some_char) VALUES('', ?)");
				} else {
					# NULL so it meanse false
					$stmt = $dbh->prepare("INSERT INTO $table (some_char) VALUES(?)");
				}
				$stmt->execute(md5_hex(int(rand(65536)) . localtime ));
			}
			case 't_tinyint_boolean' {
				my $stmt = $dbh->prepare("INSERT INTO $table (bool_col, some_char) VALUES(?, ?)");
				$stmt->execute($bool, md5_hex(int(rand(65536)) . localtime ));
			}
            case 't_bool_boolean' {
				my $stmt = $dbh->prepare("INSERT INTO $table (bool_col, some_char) VALUES(?, ?)");
				$stmt->execute($bool, md5_hex(int(rand(65536)) . localtime ));
            }
            case 't_enum_boolean' {
				my $stmt;
				if ($bool) {
					$stmt = $dbh->prepare("INSERT INTO $table (bool_col, some_char) VALUES('true', ?)");
				} else {
					$stmt = $dbh->prepare("INSERT INTO $table (bool_col, some_char) VALUES('false', ?)");
				}
				$stmt->execute(md5_hex(int(rand(65536)) . localtime ));
        	}
		}
	}
}

# Now the tables are all full. 
# Starting the query threads.
# We have 8 CPU cores in the test box so we will spawn 16 threads.
for ( my $count = 1; $count <= 16; $count++) {
        my $t = threads->new(\&slap, $count);
        push(@threads,$t);
}
foreach (@threads) {
        my $num = $_->join;
        print "done with $num \n";
}

sub slap {
	my $tdbh = DBI->connect("dbi:mysql:knagy;host=localhost;mysql_socket=$datadir/mysql.sock", 'root', $password) or die('Cannot connect');
	while (1) {
		my $query = int(rand(8));
		my $table;
		my $condition; 
		switch ($query) {
			case 0 {$table = 't_char_boolean'; $condition = 'bool_col IS NULL';}
			case 1 {$table = 't_char_boolean'; $condition = 'bool_col LIKE ""';}
			case 2 {$table = 't_tinyint_boolean'; $condition = 'bool_col = 0';}
			case 3 {$table = 't_tinyint_boolean'; $condition = 'bool_col = 1';}
			case 4 {$table = 't_bool_boolean'; $condition = 'bool_col = 0';}
			case 5 {$table = 't_bool_boolean'; $condition = 'bool_col = 1';}
			case 6 {$table = 't_enum_boolean'; $condition = 'bool_col = "false"';}
			case 7 {$table = 't_enum_boolean'; $condition = 'bool_col = "true"';}
		} 
		my $stmt = $tdbh->prepare("select count(*) from $table where $condition;");
		my $start = time;
		$stmt->execute();
		my $delta = time - $start;
		log_time($tdbh, $query, $condition, $delta * 10000);
		# To avoid stampede we use random sleep time.
		sleep rand(3) + 1;
	}
}

sub log_time {
 	# Logging the query time the database
	my ($con, $qtype, $cond, $time) = @_;
	my $stmt = $con->prepare('INSERT INTO query_times (qtype, qcondition, qtime) VALUES (?, ?, ?)');
	$stmt->execute($qtype, $cond, $time );
}

sub is_insert {
	# Check if we have enough rows in table
	my ($table) = @_;
	my $query = $dbh->prepare("SELECT COUNT(*) from $table;");
	$query->execute(); 
	my ($count) = $query->fetchrow_array();
	return $count < 1000000;
}
