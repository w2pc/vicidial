<?
### closer_popup.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###
# this is the closer popup of a specific call that grabs the call and allows you to go and fetch info on that caller in the local CRM system.

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
$group=$_GET["group"];						if (!$group) {$group=$_POST["group"];}
$group_selected=$_GET["group_selected"];	if (!$group_selected) {$group_selected=$_POST["group_selected"];}
$dialplan_number=$_GET["dialplan_number"];	if (!$dialplan_number) {$dialplan_number=$_POST["dialplan_number"];}
$extension=$_GET["extension"];				if (!$extension) {$extension=$_POST["extension"];}
$groupselect=$_GET["groupselect"];			if (!$groupselect) {$groupselect=$_POST["groupselect"];}
$PHONE_LOGIN=$_GET["PHONE_LOGIN"];			if (!$PHONE_LOGIN) {$PHONE_LOGIN=$_POST["PHONE_LOGIN"];}
$server_ip=$_GET["server_ip"];				if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$DB=$_GET["DB"];							if (!$DB) {$DB=$_POST["DB"];}
$user=$_GET["user"];						if (!$user) {$user=$_POST["user"];}
$channel=$_GET["channel"];					if (!$channel) {$channel=$_POST["channel"];}
$parked_time=$_GET["parked_time"];			if (!$parked_time) {$parked_time=$_POST["parked_time"];}
$channel_group=$_GET["channel_group"];		if (!$channel_group) {$channel_group=$_POST["channel_group"];}
$debugvars=$_GET["debugvars"];				if (!$debugvars) {$debugvars=$_POST["debugvars"];}
$parked_by=$_GET["parked_by"];				if (!$parked_by) {$parked_by=$_POST["parked_by"];}
$submit=$_GET["submit"];					if (!$submit) {$submit=$_POST["submit"];}
$SUBMIT=$_GET["SUBMIT"];					if (!$SUBMIT) {$SUBMIT=$_POST["SUBMIT"];}


#$DB=1;
$US = '_';
$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$REC_TIME = date("Ymd-His");
$FILE_datetime = $STARTtime;

$ext_context = 'demo';

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 2;";
		if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICIDIAL-CLOSER\"");
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
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
			$fullname = $row[0];
		fwrite ($fp, "VD_CLOSER|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		}
	else
		{
		fwrite ($fp, "VD_CLOSER|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

echo "<html>\n";
echo "<head>\n";
echo "<title>VICIDIAL CLOSER: Popup</title>\n";

if (eregi('CL_UNIV',$channel_group))
	{
	?>
	<script language="Javascript1.2">
	var btn_name="search";
	if (document.layers) {
		document.captureEvents(Event.KEYPRESS);
		document.onkeypress = function (evt) {
			if (evt.target.constructor == Input) {
				if (evt.target.name == 'lead_id' || evt.target.name == 'phone' || evt.target.name == 'confirmation_id') {
					return ((evt.which >= '0'.charCodeAt() && evt.which <= '9'.charCodeAt()));
				} 
			}
		}
	}
	function CheckForm() {
		if (btn_name=="update") {
			if (document.forms[0].phone.value.length!=10) {
				alert("The phone number you entered does not have 10 digits.\n\nIt has "+document.forms[0].phone.value.length+" - please correct it and try again.");
				return false;
			} else if (document.forms[0].confirmation_id.value.length<=5) {
				alert("The confirmation ID is either missing or not enough characters in length.\n\nPlease correct it and try again.");
				return false;
			} else {
				return true;
			}
		}
	}
	</script>
	<?
	}
else 
	{
	echo "<script language=\"Javascript1.2\">\n";
	echo "function WaitFirefix() {setTimeout(document.forms[0].search_phone.focus(), 1000)}\n";
	echo "</script>\n";
	}
?>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0 onLoad="document.forms[0].search_phone.focus(); setTimeout('document.forms[0].search_phone.focus()', 1000)">
<CENTER><FONT FACE="Courier" COLOR=BLACK SIZE=3>

<? 

$stmt="SELECT count(*) from parked_channels where server_ip='$server_ip' and parked_time='$parked_time' and channel='$channel'";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$parked_count = $row[0];

if ($parked_count > 0)
{
	$stmt="DELETE from parked_channels where server_ip='$server_ip' and parked_time='$parked_time' and channel='$channel' LIMIT 1";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);


	#$monitor_channel = eregi_replace('Zap/', "", $channel);
	$monitor_channel = eregi_replace('-1', "", $channel);
	$SIPexten = $extension;
	$filename = "$REC_TIME$US$SIPexten";
	$DTqueryCID = "RR$FILE_datetime$PHP_AUTH_USER";

#	$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Monitor','$DTqueryCID','Channel: $monitor_channel','File: $filename','Callerid: $DTqueryCID','','','','','','','')";
#	if ($DB) {echo "|$stmt|\n";}
#	$rslt=mysql_query($stmt, $link);

#	$stmt = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('$monitor_channel','$server_ip','SIP/$SIPexten','$NOW_TIME','$STARTtime','$filename')";
#	if ($DB) {echo "|$stmt|\n";}
#	$rslt=mysql_query($stmt, $link);

#	$stmt="SELECT recording_id FROM recording_log where filename='$filename'";
#	$rslt=mysql_query($stmt, $link);
#	if ($DB) {echo "$stmt\n";}
#	$row=mysql_fetch_row($rslt);
#	$recording_id = $row[0];

#	echo "Recording command sent for channel $channel - $filename - $recording_id<BR>\n";

	### insert a NEW record to the vicidial_manager table to be processed
	$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Redirect','$DTqueryCID','Exten: $dialplan_number','Channel: $channel','Context: $ext_context','Priority: 1','Callerid: $DTqueryCID','','','','','')";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	echo "Redirect command sent for channel $channel &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";

	$stmt="SELECT full_name from vicidial_users where user='$parked_by'";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$full_name = $row[0];

	echo "Call Referred by: $parked_by - $full_name\n<BR><BR>\n";

   $url = "http://10.10.10.196/vicidial/closer_dispo.php?lead_id=$parked_by&channel=$channel&server_ip=$server_ip&extension=$extension&call_began=$STARTtime&parked_time=$parked_time&DB=$DB";

	echo "<a href=\"$url\">View Customer Info and Disposition Call</a>\n<BR><BR>\n";



	$stmt="UPDATE park_log set grab_time='$NOW_TIME',status='TALKING',extension='$extension',user='$PHP_AUTH_USER' where parked_time='$parked_time' and server_ip='$server_ip' and  channel='$channel'";
	if ($DB) {echo "|$stmt|\n";}
		$fp = fopen ("./closer_SQL_updates.txt", "a");
		fwrite ($fp, "$date|$PHP_AUTH_USER|$stmt|\n");
		fclose($fp);


	$rslt=mysql_query($stmt, $link);

###########################################################################################
####### HERE IS WHERE YOU DEFINE DIFFERENT CONTENTS DEPENDING UPON THE CHANNEL_GROUP PREFIX 
###########################################################################################
if (eregi('CL_TEST',$channel_group))
	{
	echo "GALLERIA TEST CLOSER GROUP: $channel_group\n";

	$stmt="SELECT user,phone_number from vicidial_list where lead_id='$parked_by';";
		if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$fronter=$row[0];
	$search_phone=$row[1];


	?>
	<form action="http://10.10.10.196/vicidial/closer_lookup3.php" method="post">
		<input type=hidden name="fronter" value="<?=$fronter ?>">
		<input type=hidden name="closer" value="<?=$PHP_AUTH_USER ?>">
		<input type=hidden name="group" value="<?=$channel_group ?>">
		<input type=hidden name="recording_id" value="<?=$recording_id ?>">
	<table border=0 cellspacing=5 cellpadding=3 align=center width=90%>
	<tr>
		<th colspan=2 bgcolor='#666666'><font class='standard_bold' color='white'>COF MW Customer Search</font></th>
	</tr>
	<tr bgcolor='#99FF99'>
		<td align=right width="50%" nowrap><font class='standard_bold'>Phone number</font></td>
		<td align=left width="50%" nowrap><input type=text size=10 maxlength=10 name="search_phone" value="<?=$search_phone ?>"></td>
	</tr>
	<tr>
		<th colspan=2 bgcolor='#666666'><input type=submit name="submit_COF" value="SEARCH"></th>
	</tr>
	</table>
	</form>
	<BR><BR>
	<?
	}

if (eregi('CL_MWCOF',$channel_group))
	{
	echo "GALLERIA INTERNAL CLOSER GROUP: $channel_group\n";

	$stmt="SELECT user,phone_number from vicidial_list where lead_id='$parked_by';";
		if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$fronter=$row[0];
	$search_phone=$row[1];


	?>
	<form action="http://10.10.10.196/vicidial/closer_lookup3.php" method="post">
		<input type=hidden name="fronter" value="<?=$fronter ?>">
		<input type=hidden name="closer" value="<?=$PHP_AUTH_USER ?>">
		<input type=hidden name="group" value="<?=$channel_group ?>">
		<input type=hidden name="recording_id" value="<?=$recording_id ?>">
	<table border=0 cellspacing=5 cellpadding=3 align=center width=90%>
	<tr>
		<th colspan=2 bgcolor='#666666'><font class='standard_bold' color='white'>COF MW Customer Search</font></th>
	</tr>
	<tr bgcolor='#99FF99'>
		<td align=right width="50%" nowrap><font class='standard_bold'>Phone number</font></td>
		<td align=left width="50%" nowrap><input type=text size=10 maxlength=10 name="search_phone" value="<?=$search_phone ?>"></td>
	</tr>
	<tr>
		<th colspan=2 bgcolor='#666666'><input type=submit name="submit_COF" value="SEARCH"></th>
	</tr>
	</table>
	</form>
	<BR><BR>
	<?
	}



if (eregi('CL_GAL',$channel_group))
	{
	echo "GALLERIA CLOSER GROUP: $channel_group\n";
	$group_color='#CCCCCC';

	if (eregi('CL_GALLERIA',$channel_group))
		{
		echo "<br><font color=green size=3><b>-- INTERNAL CALL GALLERIA FRONT --</b></font><br>\n";
		$group_color='#99FF99';
		}
	if (eregi('CL_GALLER2',$channel_group))
		{
		echo "<br><font color=red size=3><b>-- TouchAsia CALL Simple Escapes FRONT --</b></font><br>\n";
		$group_color='#FF9999';
		}
	if (eregi('CL_GALLER3',$channel_group))
		{
		echo "<br><font color=red size=3><b>-- DebitSupplies CALL Simple Escapes FRONT --</b></font><br>\n";
		$group_color='#FF9999';
		}
	if (eregi('CL_GALLER4',$channel_group))
		{
		echo "<br><font color=red size=3><b>-- Vishnu CALL Simple Escapes FRONT --</b></font><br>\n";
		$group_color='#FF9999';
		}


	?>
	<form action="http://10.10.10.196/vicidial/closer_lookup3.php" method="post">
		<input type=hidden name="fronter" value="<?=$parked_by ?>">
		<input type=hidden name="closer" value="<?=$PHP_AUTH_USER ?>">
		<input type=hidden name="group" value="<?=$channel_group ?>">
		<input type=hidden name="recording_id" value="<?=$recording_id ?>">
	<table border=0 cellspacing=5 cellpadding=3 align=center width=90%>
	<tr>
		<th colspan=2 bgcolor='#666666'><font class='standard_bold' color='white'>COF MW Customer Search</font></th>
	</tr>
	<tr bgcolor="<?=$group_color ?>">
		<td align=right width="50%" nowrap><font class='standard_bold'>Phone number</font></td>
		<td align=left width="50%" nowrap><input type=text size=10 maxlength=10 name="search_phone" value="<?=$phone ?>"></td>
	</tr>
	<tr>
		<th colspan=2 bgcolor='#666666'><input type=submit name="submit_COF" value="SEARCH"></th>
	</tr>
	</table>
	</form>
	<BR><BR>
	
<!----
	<form action="http://10.10.10.196/vicidial/closer_lookup3.php" method="post">
		<input type=hidden name="fronter" value="<?=$parked_by ?>">
		<input type=hidden name="closer" value="<?=$PHP_AUTH_USER ?>">
	<table border=0 cellspacing=5 cellpadding=3 align=center width=90%>
	<tr>
		<th colspan=2 bgcolor='#666666'><font class='standard_bold' color='white'>NEW COF BlueGreen Customer Search</font></th>
	</tr>
	<tr bgcolor='#CCCCCC'>
		<td align=right width="50%" nowrap><font class='standard_bold'>Phone number</font></td>
		<td align=left width="50%" nowrap><input type=text size=10 maxlength=10 name="search_phone" value="<?=$phone ?>"></td>
	</tr>
	<tr>
		<th colspan=2 bgcolor='#666666'><input type=submit name="submit_COF" value="SEARCH"></th>
	</tr>
	</table>
	</form>
	<BR><BR>
---->

	<?
	}


if (eregi('CL_UNIV',$channel_group))
	{
	echo "UNIVERSAL CLOSER GROUP: $channel_group\n";


	?>

	<form action="uk_mail_lookup.php" method="post" onSubmit="return CheckForm()">
		<input type=hidden name="fronter" value="<?=$parked_by ?>">
		<input type=hidden name="closer" value="<?=$PHP_AUTH_USER ?>">
		<input type=hidden name="group" value="<?=$channel_group ?>">
		<input type=hidden name="recording_id" value="<?=$recording_id ?>">
	<table border=0 width=80% cellpadding=5 cellspacing=0 align=center>
	<tr>
			<th colspan=2 bgcolor='#CCCCCC'><font class='standard_bold'>New Search</font></th>
	</tr>

	<tr bgcolor='#CCCCCC'>
			<td align=right width="50%" nowrap><font class='standard_bold'>Reservation Number:</font></td>
			<td align=left width="50%" nowrap><input type=text size=10 maxlength=10
	name="reservation_no" value="" ONKEYPRESS="var keyCode = event.which ? event.which : event.keyCode; if (keyCode!=8 && keyCode!=9 && keyCode!=37 && keyCode!=39) return ((keyCode >= '0'.charCodeAt() && keyCode <= '9'.charCodeAt()))"></td>
	</tr>
	<tr bgcolor='#CCCCCC'><td align=right width='50%' nowrap><font class='standard_bold'>Confirmation #:</font></td>
	<td align=left width='50%' nowrap><input type=text name='confirmation_no' size=10 maxlength=20 value=''></td></tr>
	<tr bgcolor='#CCCCCC'>
			<td align=right width="50%" nowrap><font class='standard_bold'>Phone #:</font></td>
			<td align=left width="50%" nowrap><input type=text size=10 maxlength=10
	name="phone" value="" ONKEYPRESS="var keyCode = event.which ? event.which : event.keyCode; if (keyCode!=8 && keyCode!=9 && keyCode!=37 && keyCode!=39) return ((keyCode >= '0'.charCodeAt() && keyCode <= '9'.charCodeAt()))"></td>

	</tr><tr>
		<th colspan=2 bgcolor='#CCCCCC'><input type=submit name="submit_COF" value="SEARCH" onClick="javascript:btn_name='search'"><br><br></th>
	</tr>
	<tr>
		<th colspan=2 bgcolor='#666666'><font class='standard_bold'><a href='closer_popup.php'>Back</a></font></th>
	</tr>
	</table>

	</form>


	<?

	}

###########################################################################################
####### END CUSTOM CONTENTS 
###########################################################################################


#	echo "<a href=\"#\">Close this window</a>\n<BR><BR>\n";
}
else
{
	echo "Redirect command FAILED for channel $channel &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";
	echo "<form><input type=button value=\"Close This Window\" onClick=\"javascript:window.close();\"></form>\n";
}



$ENDtime = date("U");

$RUNtime = ($ENDtime - $STARTtime);

echo "\n\n\n<br><br><br>\n\n";


echo "<font size=0>\n\n\n<br><br><br>\nscript runtime: $RUNtime seconds</font>";


?>


</body>
</html>

<?
	
exit; 



?>





