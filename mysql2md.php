<?php

exec('cd /doc/sing/dataDictionary/ && git pull');

mysql2md('192.168.0.152', 'root', 'kugou', 'kugou_sing', "/doc/sing/dataDictionary/kugou_sing.md");
mysql2md('192.168.0.152', 'root', 'kugou', 'kugou_sing_admin', "/doc/sing/dataDictionary/kugou_sing_admin.md");
mysql2md('192.168.0.152', 'root', 'kugou', 'kugou_sing_consume', "/doc/sing/dataDictionary/kugou_sing_consume.md");
mysql2md('192.168.0.152', 'root', 'kugou', 'kugou_sing_log', "/doc/sing/dataDictionary/kugou_sing_log.md");
mysql2md('192.168.0.152', 'root', 'kugou', 'kugou_sing_second', "/doc/sing/dataDictionary/kugou_sing_second.md");


exec('cd /doc/sing/dataDictionary/ && git add .');
exec('cd /doc/sing/dataDictionary/ && git commit -m "更新数据字典'.date('Y-m-d H:i:s').'"');
exec('cd /doc/sing/dataDictionary/ && git push');

function mysql2md($host, $user, $pass, $db, $file){	
	$conn = mysql_connect($host, $user, $pass);
	mysql_query('set names utf8', $conn);
	mysql_query('use '.$db, $conn);
	
	$data = '# '.$db."库字典表\r\n";
	
	$rs = mysql_query('show tables', $conn);	
	while($row = mysql_fetch_array($rs, MYSQL_ASSOC)){
		$data .= '### '.$row['Tables_in_'.$db];
		$rs2 = mysql_query('SHOW TABLE STATUS', $conn);
		
		$comment = '';
		while($row2 = mysql_fetch_array($rs2, MYSQL_ASSOC)){
			if($row2['Name'] === $row['Tables_in_'.$db]){
				$comment = $row2['Comment'];
				break;
			}
		}
		
		if($comment){
			$data .= " (".$comment.")\r\n\r\n";
		} else {
			$data .= "\r\n\r\n";
		}
		
		$data .= "字段名|数据类型|是否为空|额外|注释\r\n---|---|---|---|---\r\n";
		$rs1 = mysql_query('SHOW FULL COLUMNS FROM '.$row['Tables_in_'.$db], $conn);
		while($row1 = mysql_fetch_array($rs1, MYSQL_ASSOC)){
			$data .= $row1['Field'].'|'.$row1['Type'].'|'.($row1['Null']==='YES'?'是':'否').'|'.$row1['Extra'].'|'.$row1['Comment']."\r\n";
		}
		$data .= "\r\n##### 索引\r\n";
		
		$index = array();
		$rs3 = mysql_query('SHOW INDEX FROM '.$row['Tables_in_'.$db], $conn);
		while($row3 = mysql_fetch_array($rs3, MYSQL_ASSOC)){
			$index[$row3['Key_name']]['index_info'][] = $row3['Column_name'];
			$index[$row3['Key_name']]['index_type'] = $row3['Non_unique'] === '0' ? '是':'否';
			$index[$row3['Key_name']]['type'] = $row3['Index_type'];
		}
		
		if(is_array($index) && count($index) > 0){
			$data .= "\r\n索引名|是否唯一|索引类型|字段\r\n---|---|---|---\r\n";
			foreach($index as $key_name => $key){
				$data .= $key_name."|".$key['index_type']."|".$key['type']."|";
				foreach($key['index_info'] as $value){
					$data .= $value."    ";
				}
				$data = substr($data, 0, -4);
				$data .= "\r\n";
			}
			$data .= "\r\n\r\n\r\n\r\n";
		} else {
			$data .= "\r\n\r\n无\r\n\r\n";
		}
		echo "表 ".$row['Tables_in_'.$db]." 写入完成！\r\n\r\n";
	}
	
	$data .= "最后修改时间  ".date('Y-m-d H:i:s')."\r\n\r\n";
	
	mysql_close($conn);
	file_put_contents($file, $data);
}
?>
