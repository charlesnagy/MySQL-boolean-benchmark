create table t_char_boolean (
id int unsigned AUTO_INCREMENT,
bool_col CHAR(0) NULL DEFAULT NULL,
some_char VARCHAR(255),
PRIMARY KEY(id)) Engine=InnoDB DEFAULT CHARSET=latin1;
create index charbool_idx on t_char_boolean(bool_col);

create table t_tinyint_boolean (
id int unsigned AUTO_INCREMENT,
bool_col TINYINT NOT NULL DEFAULT 0,
some_char VARCHAR(255),
PRIMARY KEY(id)) Engine=InnoDB DEFAULT CHARSET=latin1;
create index intbool_idx on t_tinyint_boolean(bool_col);

-- These types are synonyms for TINYINT(1). A value of zero is considered false. Nonzero values are considered 
create table t_bool_boolean (
id int unsigned AUTO_INCREMENT,
bool_col BOOLEAN NOT NULL DEFAULT 0,
some_char VARCHAR(255),
PRIMARY KEY(id)) Engine=InnoDB DEFAULT CHARSET=latin1;
create index booleanbool_idx on t_bool_boolean(bool_col);

create table t_enum_boolean (
id int unsigned AUTO_INCREMENT,
bool_col ENUM('false', 'true') NOT NULL DEFAULT 'false',
some_char VARCHAR(255),
PRIMARY KEY(id)) Engine=InnoDB DEFAULT CHARSET=latin1;
create index enumbool_idx on t_enum_boolean(bool_col);

create table query_times (
	id int unsigned not null AUTO_INCREMENT,
	qtype tinyint unsigned not null,
	qcondition varchar(64) not null,
	qtime mediumint unsigned null,
	PRIMARY KEY (id)
) Engine=InnoDB DEFAULT CHARSET=latin1;
create index qtype_idx on query_times(qtype);
