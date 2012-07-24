

I always hear newer and newer exotic way to store different types of data in MySQL. People are trying to solve the problem of storing complex and not necessary strictly structured data in databases which is fine. But I never understood why to try to be tricky with the simplest datatypes. For example Booleans. You would believe it's easy. Yes or no. But there are several different way to say in MySQL that this is a Boolean. 

Possible solutions
------------------
1) The most common (consider as a best practice): 
   TINYINT unsigned NOT NULL
2) The trivial Boolean or Bool column type which is just a synonyms for TINYINT(1):
   BOOLEAN NOT NULL DEFAULT 0
3) Declaring an enumaration with "true" and "false": 
   bool_col ENUM('false', 'true') NOT NULL DEFAULT 'false'
4) The newest and weirdest I heard about:
   CHAR(0) NULL DEFAULT NULL
   
All of them are quite straightforward except the last one which might need some explanation. Char(0) means a zero length string where null value or lack of the value means false and empty string ('') means true. Why would you do so? Because somebody thinks char(0) has optimal for storage requirements. We will see because I decided to test these presumptions.

Environment
-----------
The server which hosted the test environment was a KVM box.

8x QEMU Virtual CPU version 0.9.1 3065MHz
4GB memory 
High HDD performance
	# hdparm -tT /dev/hda2 
	/dev/hda2:
	Timing cached reads:   25760 MB in  2.00 seconds = 12903.12 MB/sec
	Timing buffered disk reads:  548 MB in  3.01 seconds = 182.17 MB/sec

The test was performed with MySQL-server-5.5.16.

Schema
------
I created a table for each type with the t_xxx_boolean naming convention where xxx is one of the followings: bool, tinyint, enum and char. For collecting results I created a query_times table where I stored query times with 1/10000 sec precision.(You can check out the attached SQL file)

I've put index on all boolean column because I wanted the consider it as flag (published, active etc. like everyday usage of bool in models). Also I've added a varchar(255) column which is pretty common as well but for the sake of simplicity I always inserted md5_hex (32 characters) to that column . But one thing have to be mentioned:

	> create index charbool_idx on t_char_boolean(bool_col);
	ERROR 1167 (42000): The used storage engine can't index column 'bool_col'

You cannot create index on CHAR(0)!

Results
-------
The queries was the same all time. Randomly query for true or false values in the tables.

	> select qtype, count(*) as amount_of_queries from query_times group by qtype;
	+-------+-------------------+
	| qtype | amount_of_queries |
	+-------+-------------------+
	|     0 |            283293 |
	|     1 |            282908 |
	|     2 |            282490 |
	|     3 |            283231 |
	|     4 |            282661 |
	|     5 |            283386 |
	|     6 |            283697 |
	|     7 |            283107 |
	+-------+-------------------+
	
Almost 300 000 query from all type of queries.

	> select qtype, avg(qtime), min(qtime), max(qtime) from query_times group by qtype;
	+-------+------------+------------+------------+
	| qtype | avg(qtime) | min(qtime) | max(qtime) |
	+-------+------------+------------+------------+
	|     0 |  2873.5668 |       1652 |       5584 |
	|     1 |  3035.3421 |       1789 |       6250 |
	|     2 |  1599.5057 |        738 |       3960 |
	|     3 |  1601.5281 |        737 |       4163 |
	|     4 |  1607.0162 |        739 |       4103 |
	|     5 |  1606.7304 |        736 |       3767 |
	|     6 |  1841.6708 |        899 |       4446 |
	|     7 |  1837.4431 |        899 |       4095 |
	+-------+------------+------------+------------+

Where qtype is:
0: Char column where false
1: Char column where true
2: Tinyint column where false
3: Tinyint column where true
4: Boolean column where false
5: Boolean column where true
6: Enum column where false
7: Enum column where true

Storage
-------
No surprise. All the tables have the same average row length:

	> pager grep row_length
	> show table status like 't\_%'\G
	Avg_row_length: 62
	Avg_row_length: 62
	Avg_row_length: 62
	Avg_row_length: 62

Storage wise no difference.

Summary
-------
Don't try to be too smart. Sometimes the simplest and obvious answer is the right answer. (http://en.wikipedia.org/wiki/Occam's_razor) Use TINYINT unsigned NOT NULL DEFAULT 0 (or 1).