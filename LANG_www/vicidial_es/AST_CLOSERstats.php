<? 
### AST_CLOSERstats.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###
# CHANGES
#
# 60619-1714 - Added variable filtering to eliminate SQL injection attack threat
#            - Added required user/pass to gain access to this page
# 60905-1326 - Added queue time stats
#

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
if (isset($_GET["group"]))				{$group=$_GET["group"];}
	elseif (isset($_POST["group"]))		{$group=$_POST["group"];}
if (isset($_GET["query_date"]))				{$query_date=$_GET["query_date"];}
	elseif (isset($_POST["query_date"]))		{$query_date=$_POST["query_date"];}
if (isset($_GET["submit"]))				{$submit=$_GET["submit"];}
	elseif (isset($_POST["submit"]))		{$submit=$_POST["submit"];}
if (isset($_GET["ENVIAR"]))				{$ENVIAR=$_GET["ENVIAR"];}
	elseif (isset($_POST["ENVIAR"]))		{$ENVIAR=$_POST["ENVIAR"];}

$PHP_AUTH_USER = ereg_replace("[^0-9a-zA-Z]","",$PHP_AUTH_USER);
$PHP_AUTH_PW = ereg_replace("[^0-9a-zA-Z]","",$PHP_AUTH_PW);

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 6 and view_reports='1';";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Nombre y contraseña inválidos del usuario: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}

$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
if (!isset($group)) {$group = '';}
if (!isset($query_date)) {$query_date = $NOW_DATE;}

$stmt="select group_id from vicidial_inbound_groups;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$groups_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $groups_to_print)
	{
	$row=mysql_fetch_row($rslt);
	$groups[$i] =$row[0];
	$i++;
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
echo "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=utf-8\">\n";
echo "<TITLE>VICIDIAL: Estadísticas de VDAD Closer</TITLE></HEAD><BODY BGCOLOR=WHITE>\n";
echo "<FORM ACTION=\"$PHP_SELF\" METHOD=GET>\n";
echo "<INPUT TYPE=TEXT NAME=query_date SIZE=10 MAXLENGTH=10 VALUE=\"$query_date\">\n";
echo "<SELECT SIZE=1 NAME=group>\n";
	$o=0;
	while ($groups_to_print > $o)
	{
		if ($groups[$o] == $group) {echo "<option selected value=\"$groups[$o]\">$groups[$o]</option>\n";}
		  else {echo "<option value=\"$groups[$o]\">$groups[$o]</option>\n";}
		$o++;
	}
echo "</SELECT>\n";
echo "<INPUT TYPE=submit NAME=ENVIAR VALUE=ENVIAR>\n";
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href=\"./admin.php?ADD=3111&group_id=$group\">MODIFICAR</a> | <a href=\"./admin.php?ADD=999999\">INFORMES</a> </FONT>\n";
echo "</FORM>\n\n";

echo "<PRE><FONT SIZE=2>\n\n";


if (!$group)
{
echo "\n\n";
echo "SELECCIONE POR FAVOR Una CAMPAÚA Y La FECHA ARRIBA Y El TECLEO SOMETEN\n";
}

else
{


echo "VICIDIAL: Estadísticas de Auto-dial en CLOSER                      $NOW_TIME\n";

echo "\n";
echo "---------- TOTALS\n";

$stmt="select count(*),sum(length_in_sec) from vicidial_closer_log where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and campaign_id='" . mysql_real_escape_string($group) . "';";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$TOTALcalls =	sprintf("%10s", $row[0]);
if ( ($row[0] < 1) or ($row[1] < 1) )
	{$average_hold_seconds = '         0';}
else
	{
	$average_hold_seconds = ($row[1] / $row[0]);
	$average_hold_seconds = round($average_hold_seconds, 0);
	$average_hold_seconds =	sprintf("%10s", $average_hold_seconds);
	}

echo "Llamadas dentro de esta campaña $TOTALcalls\n";
echo "Average Call Length for all Calls:            $average_hold_seconds seconds\n";

echo "\n";
echo "---------- DROPS\n";

$stmt="select count(*),sum(length_in_sec) from vicidial_closer_log where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and campaign_id='" . mysql_real_escape_string($group) . "' and status='DROP' and (length_in_sec <= 999 or length_in_sec is null);";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$DROPcalls =	sprintf("%10s", $row[0]);
if ( ($DROPcalls < 1) or ($TOTALcalls < 1) )
	{$DROPpercent = '0';}
else
	{
	$DROPpercent = (($DROPcalls / $TOTALcalls) * 100);
	$DROPpercent = round($DROPpercent, 0);
	}

if ( ($row[0] < 1) or ($row[1] < 1) )
	{$average_hold_seconds = '         0';}
else
	{
	$average_hold_seconds = ($row[1] / $row[0]);
	$average_hold_seconds = round($average_hold_seconds, 0);
	$average_hold_seconds =	sprintf("%10s", $average_hold_seconds);
	}

echo "Total DROP Calls: $DROPcalls  $DROPpercent%\n";
echo "Average hold time for DROP Calls:             $average_hold_seconds seconds\n";

echo "\n";
echo "---------- QUEUE STATS\n";

$stmt="select count(*),sum(queue_seconds) from vicidial_closer_log where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and campaign_id='" . mysql_real_escape_string($group) . "' and (queue_seconds > 0);";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$QUEUEcalls =	sprintf("%10s", $row[0]);
if ( ($QUEUEcalls < 1) or ($TOTALcalls < 1) )
	{$QUEUEpercent = '0';}
else
	{
	$QUEUEpercent = (($QUEUEcalls / $TOTALcalls) * 100);
	$QUEUEpercent = round($QUEUEpercent, 0);
	}

if ( ($row[0] < 1) or ($row[1] < 1) )
	{$average_queue_seconds = '         0';}
else
	{
	$average_queue_seconds = ($row[1] / $row[0]);
	$average_queue_seconds = round($average_queue_seconds, 2);
	$average_queue_seconds = sprintf("%10.2f", $average_queue_seconds);
	}

if ( ($TOTALcalls < 1) or ($row[1] < 1) )
	{$average_total_queue_seconds = '         0';}
else
	{
	$average_total_queue_seconds = ($row[1] / $TOTALcalls);
	$average_total_queue_seconds = round($average_total_queue_seconds, 2);
	$average_total_queue_seconds = sprintf("%10.2f", $average_total_queue_seconds);
	}

echo "Total Calls That entered Queue:               $QUEUEcalls  $QUEUEpercent%\n";
echo "Average QUEUE Length for queue calls:         $average_queue_seconds seconds\n";
echo "Average QUEUE Length across all calls:        $average_total_queue_seconds seconds\n";


##############################
#########  USER STATS

$TOTagents=0;
$TOTcalls=0;
$TOTtime=0;
$TOTavg=0;

echo "\n";
echo "---------- AGENTE STATS\n";
echo "+--------------------------+------------+----------+--------+\n";
echo "| AGENTE                    | CALLS      | TIME M   | AVRG M |\n";
echo "+--------------------------+------------+----------+--------+\n";

$stmt="select vicidial_closer_log.user,full_name,count(*),sum(length_in_sec),avg(length_in_sec) from vicidial_closer_log,vicidial_users where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and  campaign_id='" . mysql_real_escape_string($group) . "' and vicidial_closer_log.user is not null and length_in_sec is not null and length_in_sec > 4 and vicidial_closer_log.user=vicidial_users.user group by vicidial_closer_log.user;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$users_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $users_to_print)
	{
	$row=mysql_fetch_row($rslt);

	$TOTcalls = ($TOTcalls + $row[2]);
	$TOTtime = ($TOTtime + $row[3]);

	$user =			sprintf("%-6s", $row[0]);
	$full_name =	sprintf("%-15s", $row[1]); while(strlen($full_name)>15) {$full_name = substr("$full_name", 0, -1);}
	$USERcalls =	sprintf("%10s", $row[2]);
	$USERtotTALK =	$row[3];
	$USERavgTALK =	$row[4];

	$USERtotTALK_M = ($USERtotTALK / 60);
	$USERtotTALK_M = round($USERtotTALK_M, 2);
	$USERtotTALK_M_int = intval("$USERtotTALK_M");
	$USERtotTALK_S = ($USERtotTALK_M - $USERtotTALK_M_int);
	$USERtotTALK_S = ($USERtotTALK_S * 60);
	$USERtotTALK_S = round($USERtotTALK_S, 0);
	if ($USERtotTALK_S < 10) {$USERtotTALK_S = "0$USERtotTALK_S";}
	$USERtotTALK_MS = "$USERtotTALK_M_int:$USERtotTALK_S";
	$USERtotTALK_MS =		sprintf("%6s", $USERtotTALK_MS);

	$USERavgTALK_M = ($USERavgTALK / 60);
	$USERavgTALK_M = round($USERavgTALK_M, 2);
	$USERavgTALK_M_int = intval("$USERavgTALK_M");
	$USERavgTALK_S = ($USERavgTALK_M - $USERavgTALK_M_int);
	$USERavgTALK_S = ($USERavgTALK_S * 60);
	$USERavgTALK_S = round($USERavgTALK_S, 0);
	if ($USERavgTALK_S < 10) {$USERavgTALK_S = "0$USERavgTALK_S";}
	$USERavgTALK_MS = "$USERavgTALK_M_int:$USERavgTALK_S";
	$USERavgTALK_MS =		sprintf("%6s", $USERavgTALK_MS);

	echo "| $user - $full_name | $USERcalls |   $USERtotTALK_MS | $USERavgTALK_MS |\n";

	$i++;
	}

$TOTavg = ($TOTtime / $TOTcalls);
$TOTavg = round($TOTavg, 0);
$TOTavg_M = ($TOTavg / 60);
$TOTavg_M = round($TOTavg_M, 2);
$TOTavg_M_int = intval("$TOTavg_M");
$TOTavg_S = ($TOTavg_M - $TOTavg_M_int);
$TOTavg_S = ($TOTavg_S * 60);
$TOTavg_S = round($TOTavg_S, 0);
if ($TOTavg_S < 10) {$TOTavg_S = "0$TOTavg_S";}
$TOTavg_MS = "$TOTavg_M_int:$TOTavg_S";
$TOTavg =		sprintf("%6s", $TOTavg_MS);

$TOTtime_M = ($TOTtime / 60);
$TOTtime_M = round($TOTtime_M, 2);
$TOTtime_M_int = intval("$TOTtime_M");
$TOTtime_S = ($TOTtime_M - $TOTtime_M_int);
$TOTtime_S = ($TOTtime_S * 60);
$TOTtime_S = round($TOTtime_S, 0);
if ($TOTtime_S < 10) {$TOTtime_S = "0$TOTtime_S";}
$TOTtime_MS = "$TOTtime_M_int:$TOTtime_S";
$TOTtime =		sprintf("%6s", $TOTtime_MS);

$TOTagents =		sprintf("%10s", $i);
$TOTcalls =			sprintf("%10s", $TOTcalls);
$TOTtime =			sprintf("%8s", $TOTtime);
$TOTavg =			sprintf("%6s", $TOTavg);

echo "+--------------------------+------------+----------+--------+\n";
echo "| TOTAL Agents: $TOTagents | $TOTcalls | $TOTtime | $TOTavg |\n";
echo "+--------------------------+------------+----------+--------+\n";


##############################
#########  TIME STATS

echo "\n";
echo "---------- ESTADÍSTICAS DEL TIEMPO\n";

echo "<FONT SIZE=0>\n";

$hi_hour_count=0;
$last_full_record=0;
$i=0;
$h=0;
while ($i <= 96)
	{
	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:00:00' and call_date <= '$query_date $h:14:59' and campaign_id='" . mysql_real_escape_string($group) . "';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:00:00' and call_date <= '$query_date $h:14:59' and campaign_id='" . mysql_real_escape_string($group) . "' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;


	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:15:00' and call_date <= '$query_date $h:29:59' and campaign_id='$group';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:15:00' and call_date <= '$query_date $h:29:59' and campaign_id='" . mysql_real_escape_string($group) . "' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;

	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:30:00' and call_date <= '$query_date $h:44:59' and campaign_id='" . mysql_real_escape_string($group) . "';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:30:00' and call_date <= '$query_date $h:44:59' and campaign_id='" . mysql_real_escape_string($group) . "' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;

	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:45:00' and call_date <= '$query_date $h:59:59' and campaign_id='" . mysql_real_escape_string($group) . "';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_closer_log where call_date >= '$query_date $h:45:00' and call_date <= '$query_date $h:59:59' and campaign_id='" . mysql_real_escape_string($group) . "' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;
	$h++;
	}

if ($hi_hour_count < 1)
	{$hour_multiplier = 0;}
else
	{
	$hour_multiplier = (100 / $hi_hour_count);
	#$hour_multiplier = round($hour_multiplier, 0);
	}

echo "<!-- HICOUNT: $hi_hour_count|$hour_multiplier -->\n";
echo "GRÁFICO EN 15 INCREMENTOS MINUCIOSOS DE LAS LLAMADAS TOTALES PUESTAS DE ESTA CAMPAÚA\n";

$k=1;
$Mk=0;
$call_scale = '0';
while ($k <= 102) 
	{
	if ($Mk >= 5) 
		{
		$Mk=0;
		if ( ($k < 1) or ($hour_multiplier <= 0) )
			{$scale_num = 100;}
		else
			{
			$scale_num=($k / $hour_multiplier);
			$scale_num = round($scale_num, 0);
			}
		$LENscale_num = (strlen($scale_num));
		$k = ($k + $LENscale_num);
		$call_scale .= "$scale_num";
		}
	else
		{
		$call_scale .= " ";
		$k++;   $Mk++;
		}
	}


echo "+------+-------------------------------------------------------------------------------------------------------+-------+-------+\n";
#echo "| HOUR | GRAPH IN 15 MINUTE INCREMENTS OF TOTAL INCOMING CALLS FOR THIS GROUP                                  | DROPS | TOTAL |\n";
echo "| HOUR |$call_scale| DROPS | TOTAL |\n";
echo "+------+-------------------------------------------------------------------------------------------------------+-------+-------+\n";

$ZZ = '00';
$i=0;
$h=4;
$hour= -1;
$no_lines_yet=1;

while ($i <= 96)
	{
	$char_counter=0;
	$time = '      ';
	if ($h >= 4) 
		{
		$hour++;
		$h=0;
		if ($hour < 10) {$hour = "0$hour";}
		$time = "+$hour$ZZ+";
		}
	if ($h == 1) {$time = "   15 ";}
	if ($h == 2) {$time = "   30 ";}
	if ($h == 3) {$time = "   45 ";}
	$Ghour_count = $hour_count[$i];
	if ($Ghour_count < 1) 
		{
		if ( ($no_lines_yet) or ($i > $last_full_record) )
			{
			$do_nothing=1;
			}
		else
			{
			$hour_count[$i] =	sprintf("%-5s", $hour_count[$i]);
			echo "|$time|";
			$k=0;   while ($k <= 102) {echo " ";   $k++;}
			echo "| $hour_count[$i] |\n";
			}
		}
	else
		{
		$no_lines_yet=0;
		$Xhour_count = ($Ghour_count * $hour_multiplier);
		$Yhour_count = (99 - $Xhour_count);

		$Gdrop_count = $drop_count[$i];
		if ($Gdrop_count < 1) 
			{
			$hour_count[$i] =	sprintf("%-5s", $hour_count[$i]);

			echo "|$time|<SPAN class=\"green\">";
			$k=0;   while ($k <= $Xhour_count) {echo "*";   $k++;   $char_counter++;}
			echo "*X</SPAN>";   $char_counter++;
			$k=0;   while ($k <= $Yhour_count) {echo " ";   $k++;   $char_counter++;}
				while ($char_counter <= 101) {echo " ";   $char_counter++;}
			echo "| 0     | $hour_count[$i] |\n";

			}
		else
			{
			$Xdrop_count = ($Gdrop_count * $hour_multiplier);

		#	if ($Xdrop_count >= $Xhour_count) {$Xdrop_count = ($Xdrop_count - 1);}

			$XXhour_count = ( ($Xhour_count - $Xdrop_count) - 1 );

			$hour_count[$i] =	sprintf("%-5s", $hour_count[$i]);
			$drop_count[$i] =	sprintf("%-5s", $drop_count[$i]);

			echo "|$time|<SPAN class=\"red\">";
			$k=0;   while ($k <= $Xdrop_count) {echo ">";   $k++;   $char_counter++;}
			echo "D</SPAN><SPAN class=\"green\">";   $char_counter++;
			$k=0;   while ($k <= $XXhour_count) {echo "*";   $k++;   $char_counter++;}
			echo "X</SPAN>";   $char_counter++;
			$k=0;   while ($k <= $Yhour_count) {echo " ";   $k++;   $char_counter++;}
				while ($char_counter <= 102) {echo " ";   $char_counter++;}
			echo "| $drop_count[$i] | $hour_count[$i] |\n";
			}
		}
	
	
	$i++;
	$h++;
	}


echo "+------+-------------------------------------------------------------------------------------------------------+-------+-------+\n\n";





$ENDtime = date("U");
$RUNtime = ($ENDtime - $STARTtime);
echo "\nRun Time: $RUNtime seconds\n";
}



?>
</PRE>

</BODY></HTML>