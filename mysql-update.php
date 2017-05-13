<?php
set_time_limit(0);
//外部参数 source_host source_user source_pass source_db target_host target_user target_pass target_db

//数据源
define('SOURCE_HOST', trim($argv[1]));
define('SOURCE_USER', trim($argv[2]));
define('SOURCE_PASS', trim($argv[3]));
define('SOURCE_DB', trim($argv[4]));

//目标数据库
define('TARGET_HOST', trim($argv[5]));
define('TARGET_USER', trim($argv[6]));
define('TARGET_PASS', trim($argv[7]));
define('TARGET_DB', trim($argv[8]));

compare();

//初始化数据库连接
function init(){
	//初始化数据源
	define('SOURCE_LINK', mysql_connect(SOURCE_HOST, SOURCE_USER, SOURCE_PASS));
	mysql_select_db(SOURCE_DB, SOURCE_LINK);
	
	//初始目标数据库
	define('TARGET_LINK', mysql_connect(TARGET_HOST, TARGET_USER, TARGET_PASS));
	mysql_select_db(TARGET_DB, TARGET_LINK);
}

//执行完毕，回收连接
function close(){
	mysql_close(SOURCE_LINK);
	mysql_close(TARGET_LINK);
}

//执行sql语句
function execute($sql, $link){
	echo $sql."\r\n";
	mysql_query($sql, $link);
}

function compare(){
	init();
	
	//如果目标数据库不存在，先创建一个
	$sql = 'create database if not exists `'.TARGET_DB.'` default charset utf8 collate utf8_general_ci';
	mysql_query($sql, TARGET_LINK);
	
	//获取数据源的数据结构
	$source_database_struct = get_database_struct(SOURCE_LINK, SOURCE_DB);
	
	//获取目标的数据结构
	$target_database_struct = get_database_struct(TARGET_LINK, TARGET_DB);
	
	//以数据源为准，比较差异
	foreach($source_database_struct as $table_name => $create_table){
		if(!$target_database_struct[$table_name]){
			execute($create_table, TARGET_LINK);
		} else {
			//比较字段
			compare_column(SOURCE_LINK, TARGET_LINK, SOURCE_DB, TARGET_DB, $table_name);
			
			//比较索引
			compare_keys(SOURCE_LINK, TARGET_LINK, SOURCE_DB, TARGET_DB, $table_name);
			
			//比较分区
			compare_partition(SOURCE_LINK, TARGET_LINK, SOURCE_DB, TARGET_DB, $table_name);
		}
	}
	
	//删除多余的表
	foreach($target_database_struct as $table_name => $create_table){
		if(!$source_database_struct[$table_name]){
			$sql = 'drop table `'.TARGET_DB.'`.`'.$table_name.'`';
			execute($sql, TARGET_LINK);
		}
	}
	
	close();
}

//比较字段
function compare_column($source_link, $target_link, $source_db, $target_db, $table_name){
	$sql = $after = '';
	$source_column = get_table_column($source_link, $source_db, $table_name);
	$target_column = get_table_column($target_link, $target_db, $table_name);
	foreach($source_column as $column_name => $column_info){
		$column_name = trim($column_name);
		if(!$target_column[$column_name]){
			$sql = 'alter table `'.$target_db.'`.`'.$table_name.'` add `'.$column_name.'` ';
			$sql.= $column_info['COLUMN_TYPE'].' '.($column_info['IS_NULLABLE'] == 'NO' ? 'NOT NULL ' : 'NULL ');
			$sql.= ' comment \''.$column_info['COLUMN_COMMENT'].'\'';
			if ($after) {
				$sql.= ' after `'.$after.'`';
			}
			execute($sql, $target_link);
		} else {
			//如果字段的属性不对
			$need_modify = false;
			$sql = 'alter table `'.$target_db.'`.`'.$table_name.'` change `'.$column_name.'` ';
			foreach($column_info as $key => $info){
				$key = trim($key);
				$source = $info = trim($info);
				$target = trim($target_column[$column_name][$key]);
				switch ($key) {
					case 'COLUMN_NAME':
					$sql.= '`'.$info.'` ';
					break;
					case 'IS_NULLABLE':
					if($info == 'YES'){
						$sql.= 'NULL ';
					} else {
						$sql.= 'NOT NULL ';
					}
					break;
					case 'COLUMN_DEFAULT':
					if($info == 'null' || $info == ''){
						$sql.= 'NULL ';
					} else {
						$sql.= 'DEFAULT \''.$info.'\' ';
					}
					break;
					case 'COLUMN_TYPE':
					if($info){
						$sql.= $info.' ';
					}
					break;
					case 'COLUMN_COMMENT':
					if($info){
						$sql.= 'comment \''.$info.'\' ';
					}
					break;
					case 'EXTRA':
					if($info){
						$sql.= ' '.$info.' ';
					}
					break;
					case 'COLLATION_NAME':
					if($info){
						$sql.= ' COLLATE '.$info.' ';
					}
					break;
				}
				if(!$need_modify){
					$need_modify = $source != $target;
				}
			}
			if ($need_modify) {
				execute($sql, $target_link);
			}
		}
		$after = $column_name;
	}
	//如果多余
	foreach($target_column as $column_name => $column_info){
		if(!$source_column[$column_name]){
			$sql = 'alter table `'.$target_db.'`.`'.$table_name.'` drop `'.$column_name.'`';	
			execute($sql, $target_link);
		}
	}
}

//比较索引
function compare_keys($source_link, $target_link, $source_db, $target_db, $table_name){
	$sql = '';
	$source_key = get_table_keys($source_link, $source_db, $table_name);
	$target_key = get_table_keys($target_link, $target_db, $table_name);
	foreach($source_key as $key_name => $key_info){
		$key_name = trim($key_name);
		if(!$target_key[$key_name]){
			$sql = 'alter table `'.$target_db.'`.`'.$table_name.'` ';
			if($key_name == 'PRIMARY'){
				$sql.= ' add primary key';
			} else {
				$is_unique = false;
				foreach($key_info as $k => $v){
					foreach($v as $kk => $vv){
						$is_unique = intval($vv) <= 0;
					}
				}
				if($is_unique){
					$sql.= ' add unique `';
				} else {
					$sql.= ' add index `';
				}
				$sql.= $key_name.'`';
			}
			$sql.= ' (`';
			foreach($key_info as $key => $value){
				$sql.= trim($key);
				$sql.= '`,`';
			}
			$sql = substr($sql, 0, -2);
			$sql.= ' )';
			execute($sql, $target_link);
		}
	}
	//如果多余
	foreach($target_key as $key_name => $key_info){
		$sql = 'alter table `'.$target_db.'`.`'.$table_name.'`';
		if(!$source_key[$key_name]){
			if($key_name == 'PRIMARY') {
				$sql.= ' drop primary key ';
			} else {
				$sql.= ' drop index `'.$key_name.'`';
			}
			execute($sql, $target_link);
		}
	}
}

//比较分区
function compare_partition($source_link, $target_link, $source_db, $target_db, $table_name){
	$sql = '';
	$source_partitions = get_table_partitions($source_link, $source_db, $table_name);
	$target_partitions = get_table_partitions($target_link, $target_db, $table_name);
	$extra = false;
	foreach($source_partitions as $method => $partitions){
		if($target_partitions[$method]){
			continue;
		}
		$sql = 'alter table `'.$target_db.'`.`'.$table_name.'` partition by '.$method;
		switch($method){
			case 'KEY':
				$sql.= '('.trim($partitions['PARTITION_EXPRESSION']).') partitions '.trim($partitions['PARTITION_NUM']);
			break;
			case 'HASH':
				$sql.= '('.trim($partitions['PARTITION_EXPRESSION']).') partitions '.trim($partitions['PARTITION_NUM']);
			break;
			case 'LIST':
				foreach($partitions as $p){
					if($extra === false){
						$sql.= '('.trim($partitions[0]['PARTITION_EXPRESSION']).') (';
						$extra = true;
					}
					$sql.= 'partition '.trim($p['PARTITION_NAME']).' values in ('.trim($p['PARTITION_DESCRIPTION']).'),';
				}
				$sql = substr($sql, 0, -1);
				$sql.= ')';
			break;
			case 'RANGE':
				foreach($partitions as $p){
					if($extra === false){
						$sql.= '('.trim($partitions[0]['PARTITION_EXPRESSION']).') (';
						$extra = true;
					}
					$sql.= 'partition '.trim($p['PARTITION_NAME']).' values less than ('.trim($p['PARTITION_DESCRIPTION']).'),';
				}
				$sql = substr($sql, 0, -1);
				$sql.= ')';
			break;
		}
	}
	if(intval(strpos($sql, 'HASH')) > 0 || intval(strpos($sql, 'KEY')) > 0 || intval(strpos($sql, 'LIST')) > 0 || intval(strpos($sql, 'RANGE')) > 0){
		execute($sql, $target_link);
	}
	
	//如果多余
	if(count($source_partitions) > 0 || count($target_partitions) > 0){
		foreach($target_partitions as $method => $partitions){
			if(!$source_partitions[$method]){
				$sql = 'alter table `'.$target_db.'`.`'.$table_name.'` remove partitioning';
				execute($sql, $target_link);
			}
		}
	}
}

//获取数据库结构
function get_database_struct($link, $db){
	$struct_map = array();
	foreach(get_database_table($link, $db) as $table){
		$sql = 'show create table `'.$db.'`.`'.$table.'`';
		$rs = mysql_query($sql, $link);
		while ($row = mysql_fetch_assoc($rs)) {
			$struct_map[$table] = trim($row['Create Table']);
		}
	}
	return $struct_map;
}

//获取数据库所有表
function get_database_table($link, $db){
	$table_list = array();
	$sql = 'show tables from `'.$db.'`';
	$rs = mysql_query($sql, $link);
	while ($row = mysql_fetch_assoc($rs)) {
		$table_list[] = trim($row['Tables_in_'.$db]);
	}
	return $table_list;
}

//获取表的所有字段信息
function get_table_column($link, $db, $table){
	$sql = 'select COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COLUMN_DEFAULT,COLUMN_COMMENT,EXTRA,COLLATION_NAME from information_schema.columns ';
	$sql.= 'where TABLE_SCHEMA=\''.$db.'\' and TABLE_NAME=\''.$table.'\' order by ORDINAL_POSITION asc';
	$rs = mysql_query($sql, $link);
	$table_column = array();
	while ($row = mysql_fetch_assoc($rs)) {
		$tmp = array();
		$tmp['COLUMN_NAME'] = trim($row['COLUMN_NAME']);
		$tmp['COLUMN_TYPE'] = trim($row['COLUMN_TYPE']);
		$tmp['COLUMN_DEFAULT'] = trim($row['COLUMN_DEFAULT']);
		$tmp['IS_NULLABLE'] = trim($row['IS_NULLABLE']);
		$tmp['COLUMN_COMMENT'] = trim($row['COLUMN_COMMENT']);
		$tmp['EXTRA'] = trim($row['EXTRA']);
		$tmp['COLLATION_NAME'] = trim($row['COLLATION_NAME']);
		$table_column[$row['COLUMN_NAME']] = $tmp;
	}
	return $table_column;
}

//获取表的索引信息
function get_table_keys($link, $db, $table){
	$sql = 'show keys from `'.$db.'`.`'.$table.'`';
	$rs = mysql_query($sql, $link);
	$last = '';
	$tmp = $table_keys = array();
	while ($row = mysql_fetch_assoc($rs)) {
		$key_name = trim($row['Key_name']);
		if($key_name != $last){
			$tmp = array();
		}
		$last = $key_name;
		$t = array();
		$t['Non_unique'] = $row['Non_unique'];
		$tmp[$row['Column_name']] = $t;
		$table_keys[$key_name] = $tmp;
	}
	return $table_keys;
}

//获取表的分区信息
function get_table_partitions($link, $db, $table){
	$sql = 'select PARTITION_NAME,PARTITION_METHOD,PARTITION_EXPRESSION,PARTITION_DESCRIPTION FROM INFORMATION_SCHEMA.PARTITIONS';
	$sql.= ' where TABLE_SCHEMA=\''.$db.'\' and TABLE_NAME=\''.$table.'\'';
	$rs = mysql_query($sql, $link);
	$partitions = array();
	$i = 1;
	while ($row = mysql_fetch_assoc($rs)) {
		if(!trim($row['PARTITION_NAME']) && !trim($row['PARTITION_METHOD']) && !trim($row['PARTITION_EXPRESSION']) && !trim($row['PARTITION_DESCRIPTION'])){
			continue;
		}
		if(!is_array($partitions[$row['PARTITION_METHOD']])){
			$partitions[$row['PARTITION_METHOD']] = array();
		}
		switch($row['PARTITION_METHOD']){
			case 'KEY':
				get_key_or_hash_partition($row, $partitions, $i);
			break;
			case 'HASH':
				get_key_or_hash_partition($row, $partitions, $i);
			break;
			case 'LIST':
				get_list_or_range_partition($row, $partitions, $i);
			break;
			case 'RANGE':
				get_list_or_range_partition($row, $partitions, $i);
			break;
		}
		$i += 1;
	}
	return $partitions;
}

function get_key_or_hash_partition($row, &$partitions, $i){
	$partitions[$row['PARTITION_METHOD']]['PARTITION_EXPRESSION'] = trim(str_replace('`', '', $row['PARTITION_EXPRESSION']));
	$partitions[$row['PARTITION_METHOD']]['PARTITION_NUM'] = $i;
}

function get_list_or_range_partition($row, &$partitions, $i){
	$partitions[$row['PARTITION_METHOD']][$i - 1]['PARTITION_EXPRESSION'] = trim(str_replace('`', '', $row['PARTITION_EXPRESSION']));
	$partitions[$row['PARTITION_METHOD']][$i - 1]['PARTITION_NAME'] = trim($row['PARTITION_NAME']);
	$partitions[$row['PARTITION_METHOD']][$i - 1]['PARTITION_DESCRIPTION'] = trim($row['PARTITION_DESCRIPTION']);
}

function echo_($var){
	echo '<pre>';
	print_r($var);
	echo '</pre>';
}
?>