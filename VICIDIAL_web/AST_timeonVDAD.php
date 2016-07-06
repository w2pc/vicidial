<? 
require("dbconnect.php");

require_once("htglobalize.php");

# AST_timeonVDAD.php
# live real-time stats for the VICIDIAL Auto-Dialer

$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
$epochSIXhoursAGO = ($STARTtime - 21600);
$timeSIXhoursAGO = date("Y-m-d H:i:s",$epochSIXhoursAGO);

$reset_counter++;

if ($reset_counter > 7)
	{
	$reset_counter=0;

	$stmt="update park_log set status='HUNGUP' where hangup_time is not null;";
#	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}

	if ($DB)
		{	
		$stmt="delete from park_log where grab_time < '$timeSIXhoursAGO' and (hangup_time is null or hangup_time='');";
#		$rslt=mysql_query($stmt, $link);
		 echo "$stmt\n";
		}
	}

?>

<HTML>
<HEAD>
<STYLE type="text/css">
<!--
   .green {color: white; background-color: green}
   .red {color: white; background-color: red}
   .blue {color: white; background-color: blue}
   .purple {color: white; background-color: purple}
-->
 </STYLE>

<? 
echo"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n";
echo"<META HTTP-EQUIV=Refresh CONTENT=\"4; URL=$PHP_SELF?server_ip=$server_ip&DB=$DB&reset_counter=$reset_counter\">\n";
echo "<TITLE>VICIDIAL: Time On VDAD</TITLE></HEAD><BODY BGCOLOR=WHITE>\n";
echo "<PRE><FONT SIZE=3>\n\n";

echo "VICIDIAL: Time On VDAD                                              $NOW_TIME\n\n";
echo "+------------+--------+----------+--------------------+---------------------+---------+\n";
echo "| CHANNEL    | STATUS | CAMPAIGN | PHONE NUMBER       | START TIME          | MINUTES |\n";
echo "+------------+--------+----------+--------------------+---------------------+---------+\n";

#$link=mysql_connect("localhost", "cron", "1234");
# $linkX=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

$stmt="select channel,status,campaign_id,phone_code,phone_number,call_time,UNIX_TIMESTAMP(call_time) from vicidial_auto_calls where status NOT IN('XFER') and server_ip='$server_ip' order by auto_call_id;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$parked_to_print = mysql_num_rows($rslt);
	if ($parked_to_print > 0)
	{
	$i=0;
	while ($i < $parked_to_print)
		{
		$row=mysql_fetch_row($rslt);

		$channel =			sprintf("%-10s", $row[0]);
			$cc=0;
		while ( (strlen($channel) > 10) and ($cc < 100) )
			{
			$channel = eregi_replace(".$","",$channel);   
			$cc++;
			if (strlen($channel) <= 10) {$cc=101;}
			}
		$status =			sprintf("%-6s", $row[1]);
		$campaign =			sprintf("%-8s", $row[2]);
			$all_phone = "$row[3]$row[4]";
		$number_dialed =	sprintf("%-18s", $all_phone);
		$start_time =		sprintf("%-19s", $row[5]);
		$call_time_S = ($STARTtime - $row[6]);

		$call_time_M = ($call_time_S / 60);
		$call_time_M = round($call_time_M, 2);
		$call_time_M_int = intval("$call_time_M");
		$call_time_SEC = ($call_time_M - $call_time_M_int);
		$call_time_SEC = ($call_time_SEC * 60);
		$call_time_SEC = round($call_time_SEC, 0);
		if ($call_time_SEC < 10) {$call_time_SEC = "0$call_time_SEC";}
		$call_time_MS = "$call_time_M_int:$call_time_SEC";
		$call_time_MS =		sprintf("%7s", $call_time_MS);
		$G = '';		$EG = '';
		if (eregi("LIVE",$status)) {$G='<SPAN class="green"><B>'; $EG='</B></SPAN>';}
	#	if ($call_time_M_int >= 6) {$G='<SPAN class="red"><B>'; $EG='</B></SPAN>';}

		echo "| $G$channel$EG | $G$status$EG | $G$campaign$EG | $G$number_dialed$EG | $G$start_time$EG | $G$call_time_MS$EG |\n";

		$i++;
		}

		echo "+------------+--------+----------+--------------------+---------------------+---------+\n";
		echo "  $i calls being placed on server $server_ip\n\n";

		echo "  <SPAN class=\"green\"><B>          </SPAN> - LIVE CALL WAITING</B>\n";
	#	echo "  <SPAN class=\"red\"><B>          </SPAN> - Over 5 minutes on hold</B>\n";

		}
	else
	{
	echo "***************************************************************************************\n";
	echo "***************************************************************************************\n";
	echo "******************************* NO LIVE CALLS WAITING *********************************\n";
	echo "***************************************************************************************\n";
	echo "***************************************************************************************\n";
	}

###################################################################################
###### TIME ON INBOUND CALLS
###################################################################################
echo "\n\n";
echo "----------------------------------------------------------------------------------------";
echo "\n\n";
echo "VICIDIAL: Agents Time On Calls                                        $NOW_TIME\n\n";
echo "+------------|--------+-----------+------------+--------+---------------------+---------+\n";
echo "| STATION    | USER   | SESSIONID | CHANNEL    | STATUS | START TIME          | MINUTES |\n";
echo "+------------|--------+-----------+------------+--------+---------------------+---------+\n";


$stmt="select extension,user,conf_exten,channel,status,last_call_time,UNIX_TIMESTAMP(last_call_time),UNIX_TIMESTAMP(last_call_finish) from vicidial_live_agents where status NOT IN('PAUSED') and server_ip='$server_ip' order by extension;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$talking_to_print = mysql_num_rows($rslt);
	if ($talking_to_print > 0)
	{
	$i=0;
	while ($i < $talking_to_print)
		{
		$row=mysql_fetch_row($rslt);
			if (eregi("READY|PAUSED",$row[4]))
			{
			$row[3]='';
			$row[5]=' - WAITING - ';
			$row[6]=$row[7];
			}
		$extension =		sprintf("%-10s", $row[0]);
		$user =				sprintf("%-6s", $row[1]);
		$sessionid =		sprintf("%-9s", $row[2]);
		$channel =			sprintf("%-10s", $row[3]);
			$cc=0;
		while ( (strlen($channel) > 10) and ($cc < 100) )
			{
			$channel = eregi_replace(".$","",$channel);   
			$cc++;
			if (strlen($channel) <= 10) {$cc=101;}
			}
		$status =			sprintf("%-6s", $row[4]);
		$start_time =		sprintf("%-19s", $row[5]);
		$call_time_S = ($STARTtime - $row[6]);

		$call_time_M = ($call_time_S / 60);
		$call_time_M = round($call_time_M, 2);
		$call_time_M_int = intval("$call_time_M");
		$call_time_SEC = ($call_time_M - $call_time_M_int);
		$call_time_SEC = ($call_time_SEC * 60);
		$call_time_SEC = round($call_time_SEC, 0);
		if ($call_time_SEC < 10) {$call_time_SEC = "0$call_time_SEC";}
		$call_time_MS = "$call_time_M_int:$call_time_SEC";
		$call_time_MS =		sprintf("%7s", $call_time_MS);
		$G = '';		$EG = '';
		if ($call_time_M_int >= 5) {$G='<SPAN class="blue"><B>'; $EG='</B></SPAN>';}
		if ($call_time_M_int >= 10) {$G='<SPAN class="purple"><B>'; $EG='</B></SPAN>';}

		echo "| $G$extension$EG | $G$user$EG | $G$sessionid$EG | $G$channel$EG | $G$status$EG | $G$start_time$EG | $G$call_time_MS$EG |\n";

		$i++;
		}

		echo "+------------|--------+-----------+------------+--------+---------------------+---------+\n";
		echo "  $i agents logged in on server $server_ip\n\n";

		echo "  <SPAN class=\"blue\"><B>          </SPAN> - 5 minutes or more on call</B>\n";
		echo "  <SPAN class=\"purple\"><B>          </SPAN> - Over 10 minutes on call</B>\n";

	}
	else
	{
	echo "**************************************************************************************\n";
	echo "**************************************************************************************\n";
	echo "********************************* NO AGENTS ON CALLS *********************************\n";
	echo "**************************************************************************************\n";
	echo "**************************************************************************************\n";
	}


?>
</PRE>

</BODY></HTML>