<? 
### AST_VDADstats.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###

header ("Content-type: text/html; charset=utf-8");

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
$group=$_GET["group"];						if (!$group) {$group=$_POST["group"];}
$query_date=$_GET["query_date"];			if (!$query_date) {$query_date=$_POST["query_date"];}
$submit=$_GET["submit"];					if (!$submit) {$submit=$_POST["submit"];}
$SUBMIT=$_GET["SUBMIT"];					if (!$SUBMIT) {$SUBMIT=$_POST["SUBMIT"];}

$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
if (!$query_date) {$query_date = $NOW_DATE;}

$stmt="select campaign_id from vicidial_campaigns;";
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
echo"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n";
#echo"<META HTTP-EQUIV=Refresh CONTENT=\"7; URL=$PHP_SELF?server_ip=$server_ip&DB=$DB\">\n";
echo "<TITLE>VICIDIAL: VDAD Stats</TITLE></HEAD><BODY BGCOLOR=WHITE>\n";
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
echo "<INPUT type=submit NAME=SUBMIT VALUE=SUBMIT>\n";
echo "</FORM>\n\n";

echo "<PRE><FONT SIZE=2>\n\n";


if (!$group)
{
echo "\n\n";
echo "PLEASE SELECT A CAMPAIGN AND DATE ABOVE AND CLICK SUBMIT\n";
}

else
{


echo "VICIDIAL: Auto-dial Stats                             $NOW_TIME\n";

echo "\n";
echo "---------- TOTALS\n";

$stmt="select count(*),sum(length_in_sec) from vicidial_log where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and campaign_id='$group';";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$TOTALcalls =	sprintf("%10s", $row[0]);
$average_hold_seconds = ($row[1] / $row[0]);
$average_hold_seconds = round($average_hold_seconds, 0);
$average_hold_seconds =	sprintf("%10s", $average_hold_seconds);

echo "Total Calls placed from this Campaign:        $TOTALcalls\n";
echo "Average Call Length for all Calls in seconds: $average_hold_seconds\n";

echo "\n";
echo "---------- DROPS\n";

$stmt="select count(*),sum(length_in_sec) from vicidial_log where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and campaign_id='$group' and status='DROP' and (length_in_sec <= 60 or length_in_sec is null);";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$DROPcalls =	sprintf("%10s", $row[0]);
$DROPpercent = (($DROPcalls / $TOTALcalls) * 100);
$DROPpercent = round($DROPpercent, 0);

$average_hold_seconds = ($row[1] / $row[0]);
$average_hold_seconds = round($average_hold_seconds, 0);
$average_hold_seconds =	sprintf("%10s", $average_hold_seconds);

echo "Total DROP Calls:                             $DROPcalls  $DROPpercent%\n";
echo "Average Length for DROP Calls in seconds:     $average_hold_seconds\n";

echo "\n";
echo "---------- AUTO-DIAL NO ANSWERS\n";

$stmt="select count(*),sum(length_in_sec) from vicidial_log where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and campaign_id='$group' and status='NA' and (length_in_sec <= 60 or length_in_sec is null);";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$NAcalls =	sprintf("%10s", $row[0]);
$NApercent = (($NAcalls / $TOTALcalls) * 100);
$NApercent = round($NApercent, 0);

$average_na_seconds = ($row[1] / $row[0]);
$average_na_seconds = round($average_na_seconds, 0);
$average_na_seconds =	sprintf("%10s", $average_na_seconds);

echo "Total NA calls -Busy,Disconnect,BTvoicemail:  $NAcalls  $NApercent%\n";
echo "Average Call Length for NA Calls in seconds:  $average_na_seconds\n";


##############################
#########  USER STATS

echo "\n";
echo "---------- USER STATS\n";
echo "+--------------------------+------------+--------+--------+\n";
echo "| USER                     | CALLS      | TIME M | AVRG M |\n";
echo "+--------------------------+------------+--------+--------+\n";

$stmt="select vicidial_log.user,full_name,count(*),sum(length_in_sec),avg(length_in_sec) from vicidial_log,vicidial_users where call_date >= '$query_date 00:00:01' and call_date <= '$query_date 23:59:59' and  campaign_id='$group' and vicidial_log.user is not null and length_in_sec is not null and length_in_sec > 4 and vicidial_log.user=vicidial_users.user group by vicidial_log.user;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$users_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $users_to_print)
	{
	$row=mysql_fetch_row($rslt);

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

	echo "| $user - $full_name | $USERcalls | $USERtotTALK_MS | $USERavgTALK_MS |\n";

	$i++;
	}

echo "+--------------------------+------------+--------+--------+\n";

##############################
#########  TIME STATS

echo "\n";
echo "---------- TIME STATS\n";

echo "<FONT SIZE=0>\n";

$hi_hour_count=0;
$last_full_record=0;
$i=0;
$h=0;
while ($i <= 96)
	{
	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:00:00' and call_date <= '$query_date $h:14:59' and campaign_id='$group';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:00:00' and call_date <= '$query_date $h:14:59' and campaign_id='$group' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;


	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:15:00' and call_date <= '$query_date $h:29:59' and campaign_id='$group';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:15:00' and call_date <= '$query_date $h:29:59' and campaign_id='$group' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;

	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:30:00' and call_date <= '$query_date $h:44:59' and campaign_id='$group';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:30:00' and call_date <= '$query_date $h:44:59' and campaign_id='$group' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;

	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:45:00' and call_date <= '$query_date $h:59:59' and campaign_id='$group';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$hour_count[$i] = $row[0];
	if ($hour_count[$i] > $hi_hour_count) {$hi_hour_count = $hour_count[$i];}
	if ($hour_count[$i] > 0) {$last_full_record = $i;}
	$stmt="select count(*) from vicidial_log where call_date >= '$query_date $h:45:00' and call_date <= '$query_date $h:59:59' and campaign_id='$group' and status='DROP';";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$drop_count[$i] = $row[0];
	$i++;
	$h++;
	}

$hour_multiplier = (100 / $hi_hour_count);
#$hour_multiplier = round($hour_multiplier, 0);

echo "<!-- HICOUNT: $hi_hour_count|$hour_multiplier -->\n";
echo "GRAPH IN 15 MINUTE INCREMENTS OF TOTAL CALLS PLACED FROM THIS CAMPAIGN\n";

$k=1;
$Mk=0;
$call_scale = '0';
while ($k <= 102) 
	{
	if ($Mk >= 5) 
		{
		$Mk=0;
		$scale_num=($k / $hour_multiplier);
		$scale_num = round($scale_num, 0);
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


echo "+------+-------------------------------------------------------------------------------------------------------+-------+-------+\n";







}



?>
</PRE>

</BODY></HTML>