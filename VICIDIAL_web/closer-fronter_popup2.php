<?

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$user=$_SERVER['user'];
//$pass=$_SERVER['pass'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### closer-fronter_popup.php

# this is the closer popup of a specific call that starts recording the call and allows you to go and fetch info on that caller in the local CRM system.

#$DB = '1';	# DEBUG override
$US = '_';
$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$REC_TIME = date("Ymd-His");
$FILE_datetime = $STARTtime;
$parked_time = $STARTtime;

# $ext_context = 'default'; defined in dbconnect file
if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

	$stmt="SELECT count(*) from vicidial_users where user='$user' and pass='$pass' and user_level > 0;";
		if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

	if (!$auth)
	{
	 if ( (strlen($PHP_AUTH_USER)>1) and ( (eregi("tsr",$PHP_AUTH_PW)) or (eregi("sales",$PHP_AUTH_PW)) ) )
		{
		 $auth=1;
		 $user = $PHP_AUTH_USER;
		 $pass = $PHP_AUTH_PW;
		 }
	}

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($user)<2) or (strlen($pass)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICIDIAL-CLOSER - $user - $PHP_AUTH_USER\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$user|$pass|\n";
    exit;
	}
  else
	{

	if($auth>0)
		{
		$office_no=strtoupper($user);
		$password=strtoupper($pass);
			$stmt="SELECT full_name from vicidial_users where user='$user' and pass='$pass'";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
			$fullname = $row[0];
		fwrite ($fp, "VD_CLOSER|GOOD|$date|$user|$pass|$ip|$browser|$LOGfullname|\n");
		fclose($fp);
		
		if ( (strlen($customer_zap_channel)>2) and ( (eregi('zap',$customer_zap_channel)) or (eregi('iax',$customer_zap_channel)) ) )
			{
			echo "\n<!-- zap channel: $customer_zap_channel -->\n";
			echo "<!-- session_id:  $session_id -->\n";
			echo "<!-- fronter:     $fronter    -->\n";
			echo "<!-- user:        $user       -->\n";

			}
		else
			{
			echo "Bad channel: $customer_zap_channel\n";
			echo "Make sure the Zap channel is live and try again\n";
			exit;
			}

		}
	else
		{
		fwrite ($fp, "VD_CLOSER|FAIL|$date|$user|$pass|$ip|$browser|\n");
		fclose($fp);
		}
	}

echo "<html>\n";
echo "<head>\n";
echo "<title>VICIDIAL FRONTER-CLOSER: Popup</title>\n";

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
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0 onLoad="document.forms[0].search_phone.focus(); setTimeout('document.forms[0].search_phone.focus()', 1000); self.focus()">
<CENTER><FONT FACE="Courier" COLOR=BLACK SIZE=3>

<? 

$stmt="SELECT count(*) from live_channels where server_ip='$server_ip' and channel='$customer_zap_channel'";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$parked_count = $row[0];

if ($parked_count > 0)
{

#	$stmt="DELETE from parked_channels where server_ip='$server_ip' and parked_time='$parked_time' and channel='$channel' LIMIT 1";
#	if ($DB) {echo "|$stmt|\n";}
#	$rslt=mysql_query($stmt, $link);

	$DTqueryCID = "RZ$FILE_datetime$user";

	### insert a NEW record to the vicidial_manager table to be processed

	$channel = $customer_zap_channel;
#	$channel = eregi_replace('Zap/', "", $channel);
	$SIPexten = eregi_replace('SIP/', "", $SIPexten);
	$filename = "$REC_TIME$US$SIPexten";

#	$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Monitor','$DTqueryCID','Channel: Zap/$channel','File: $filename','Callerid: $DTqueryCID','','','','','','','')";
#	if ($DB) {echo "|$stmt|\n";}
#	$rslt=mysql_query($stmt, $link);

	# Local/78600098@demo-6617,2

	$stmt = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$DTqueryCID','Channel: $local_DEF$conf_silent_prefix$session_id$local_AMP$ext_context','Context: $ext_context','Exten: $recording_exten','Priority: 1','Callerid: $filename','','','','','')";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	$stmt = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('$channel','$server_ip','SIP/$SIPexten','$NOW_TIME','$STARTtime','$filename')";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	$stmt="SELECT recording_id FROM recording_log where filename='$filename'";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$recording_id = $row[0];

	echo "Recording command sent for channel $channel - $filename - $recording_id &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";

	$stmt="SELECT full_name from vicidial_users where user='$fronter'";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$full_name = $row[0];

	echo "Call Referred by: $fronter - $full_name\n<BR><BR>\n";

   $url = "http://10.10.10.196/vicidial/closer_dispo.php?lead_id=$lead_id&channel=$channel&server_ip=$server_ip&extension=$SIPexten&call_began=$STARTtime&parked_time=$parked_time&DB=$DB";

	echo "<a href=\"$url\">View Customer Info and Disposition Call</a>\n<BR><BR>\n";


	$stmt="SELECT group_name,group_color from vicidial_inbound_groups where group_id='$channel_group'";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$group_name = $row[0];
	$group_color = $row[1];

	echo "<br>\n";
	echo "<table border=0 cellspacing=5 cellpadding=3 align=center width=90% bgcolor=\"$group_color\"><tr><td><b> $channel_group - $group_name </b></td></tr></table><br>\n\n";

###########################################################################################
####### HERE IS WHERE YOU DEFINE DIFFERENT CONTENTS DEPENDING UPON THE CHANNEL_GROUP PREFIX 
###########################################################################################

if (eregi('CL',$channel_group))
	{
	if (strlen($phone) > 9) {$search_phone = $phone;}
	if ( (strlen($search_phone) < 10) or (strlen($fronter) < 1) )
		{
		echo "<!-- looking for fronter and search_phone: |$fronter|$search_phone| -->\n";
		$stmt="SELECT user,phone_number from vicidial_list where lead_id='$parked_by';";
			if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if (strlen($fronter) < 1) {$fronter=$row[0];}
		if (strlen($search_phone) < 10) {$search_phone=$row[1];}
		}

	?>
	<form action="http://10.10.10.196/vicidial/closer_lookup3.php" method="post">
		<input type=hidden name="fronter" value="<?=$fronter ?>">
		<input type=hidden name="closer" value="<?=$closer ?>">
		<input type=hidden name="group" value="<?=$channel_group ?>">
		<input type=hidden name="recording_id" value="<?=$recording_id ?>">
	<table border=0 cellspacing=5 cellpadding=3 align=center width=90%>
	<tr>
		<th colspan=2 bgcolor='#666666'><font class='standard_bold' color='white'>COF MW Customer Search</font></th>
	</tr>
	<tr bgcolor="<?=$group_color ?>">
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






if (eregi('UNIV',$channel_group))
	{
	echo "UNIVERSAL CLOSER GROUP: $channel_group\n";


	?>

	<form action="uk_mail_lookup.php" method="post" onSubmit="return CheckForm()">
		<input type=hidden name="fronter" value="<?=$parked_by ?>">
		<input type=hidden name="closer" value="<?=$user ?>">
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
	echo "Record command FAILED for channel $channel &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";
	echo "Please go back and try again\n<BR><BR>\n";
#	echo "<form><input type=button value=\"Close This Window\" onClick=\"javascript:window.close();\"></form>\n";
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




