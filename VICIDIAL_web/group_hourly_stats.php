<?

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### group_hourly_stats.php

$STARTtime = date("U");
$TODAY = date("Y-m-d");
$date_with_hour_default = date("Y-m-d H");

if (!$date_with_hour) {$date_with_hour = $date_with_hour_default;}
if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

#$link=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 7;";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}
  else
	{

	if($auth>0)
		{
		$office_no=strtoupper($PHP_AUTH_USER);
		$password=strtoupper($PHP_AUTH_PW);
			$stmt="SELECT full_name from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
		fwrite ($fp, "VICIDIAL|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);
		}
	else
		{
		fwrite ($fp, "VICIDIAL|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}

#	$stmt="SELECT full_name from vicidial_users where user='$user';";
#	$rslt=mysql_query($stmt, $link);
#	$row=mysql_fetch_row($rslt);
#	$full_name = $row[0];

	}




?>
<html>
<head>
<title>VICIDIAL ADMIN: Group Hourly Stats</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>
<TABLE WIDTH=620 BGCOLOR=#D9E6FE cellpadding=2 cellspacing=0><TR BGCOLOR=#015B91><TD ALIGN=LEFT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B> &nbsp; VICIDIAL ADMIN: Group Hourly Stats <? echo $group ?></TD><TD ALIGN=RIGHT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B><? echo date("l F j, Y G:i:s A") ?> &nbsp; </TD></TR>




<? 

if ( ($group) and ($status) and ($date_with_hour) )
{
$stmt="SELECT user,full_name from vicidial_users where full_name LIKE \"%$group%\" order by full_name desc;";
	if ($DB) {echo "$stmt\n";}
$rslt=mysql_query($stmt, $link);
$tsrs_to_print = mysql_num_rows($rslt);
	$o=0;
	while($o < $tsrs_to_print)
	{
		$row=mysql_fetch_row($rslt);
		$VDuser[$o] = "$row[0]";
		$VDname[$o] = "$row[1]";
		$o++;
	}

	$o=0;
	while($o < $tsrs_to_print)
	{
		$stmt="select count(*) from vicidial_log where call_date >= '$date_with_hour:00:00' and  call_date <= '$date_with_hour:59:59' and user='$VDuser[$o]';";
			if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$VDtotal[$o] = "$row[0]";

		$stmt="select count(*) from vicidial_log where call_date >= '$date_with_hour:00:00' and  call_date <= '$date_with_hour:59:59' and user='$VDuser[$o]' and status='$status';";
			if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$VDcount[$o] = "$row[0]";
		$o++;
	}

echo "<TR><TD ALIGN=LEFT COLSPAN=2>\n";

echo "<br><center>\n";

echo "<B>TSR HOUR COUNTS: $group | $status | $date_with_hour</B>\n";

echo "<center><TABLE width=500 cellspacing=0 cellpadding=1>\n";
echo "<tr><td><font size=2>TSR </td><td align=left><font size=2>ID </td><td align=right><font size=2> $status</td><td align=right><font size=2> TOTAL CALLS</td><td align=right><font size=2> &nbsp; </td></tr>\n";

	$total_calls=0;
	$o=0;
	while($o < $tsrs_to_print)
	{
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=2>$VDuser[$o]</td>";
		echo "<td align=left><font size=2> $VDname[$o]</td>\n";
		echo "<td align=right><font size=2> $VDcount[$o]</td>\n";
		echo "<td align=right><font size=2> $VDtotal[$o]</td>\n";
		echo "<td align=right><font size=1><a href=\"./admin.php?ADD=3&user=$VDuser[$o]\">MODIFY</a> | <a href=\"./user_stats.php?user=$VDuser[$o]\">STATS</a></td></tr>\n";
		$total_calls = ($total_calls + $VDcount[$o]);

		$o++;
	}

echo "<tr><td><font size=2>TOTAL </td><td align=right><font size=2> $status </td><td align=right><font size=2> $total_calls</td></tr>\n";


}

echo "</TABLE></center>\n";
echo "<br><br>\n";


	echo "<br>Please enter the group you want to get hourly stats for: <form action=$PHP_SELF method=POST>\n";
	echo "<input type=hidden name=DB value=$DB>\n";
	echo "group: <input type=text name=group size=10 maxlength=10 value=\"$group\"> &nbsp; (example: survey)<br>\n";
	echo "status: <input type=text name=status size=10 maxlength=10 value=\"$status\"> &nbsp; (example: XFER)<br>\n";
	echo "date with hour: <input type=text name=date_with_hour size=14 maxlength=13 value=\"$date_with_hour\"> &nbsp; (example: 2004-06-25 14)<br>\n";
	echo "<input type=submit name=submit value=submit>\n";
	echo "<BR><BR><BR>\n";


$ENDtime = date("U");

$RUNtime = ($ENDtime - $STARTtime);

echo "\n\n\n<br><br><br>\n\n";


echo "<font size=0>\n\n\n<br><br><br>\nscript runtime: $RUNtime seconds</font>";


?>


</TD></TR><TABLE>
</body>
</html>

<?
	
exit; 



?>





