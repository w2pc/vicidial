<?
### admin_modify_lead.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
$vendor_id=$_GET["vendor_id"];				if (!$vendor_id) {$vendor_id=$_POST["vendor_id"];}
$phone=$_GET["phone"];						if (!$phone) {$phone=$_POST["phone"];}
$lead_id=$_GET["lead_id"];					if (!$lead_id) {$lead_id=$_POST["lead_id"];}
$first_name=$_GET["first_name"];			if (!$first_name) {$first_name=$_POST["first_name"];}
$last_name=$_GET["last_name"];				if (!$last_name) {$last_name=$_POST["last_name"];}
$phone_number=$_GET["phone_number"];		if (!$phone_number) {$phone_number=$_POST["phone_number"];}
$end_call=$_GET["end_call"];				if (!$end_call) {$end_call=$_POST["end_call"];}
$DB=$_GET["DB"];							if (!$DB) {$DB=$_POST["DB"];}
$dispo=$_GET["dispo"];						if (!$dispo) {$dispo=$_POST["dispo"];}
$list_id=$_GET["list_id"];					if (!$list_id) {$list_id=$_POST["list_id"];}
$campaign_id=$_GET["campaign_id"];			if (!$campaign_id) {$campaign_id=$_POST["campaign_id"];}
$phone_code=$_GET["phone_code"];			if (!$phone_code) {$phone_code=$_POST["phone_code"];}
$server_ip=$_GET["server_ip"];				if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$extension=$_GET["extension"];				if (!$extension) {$extension=$_POST["extension"];}
$channel=$_GET["channel"];					if (!$channel) {$channel=$_POST["channel"];}
$call_began=$_GET["call_began"];			if (!$call_began) {$call_began=$_POST["call_began"];}
$parked_time=$_GET["parked_time"];			if (!$parked_time) {$parked_time=$_POST["parked_time"];}
$tsr=$_GET["tsr"];							if (!$tsr) {$tsr=$_POST["tsr"];}
$address1=$_GET["address1"];				if (!$address1) {$address1=$_POST["address1"];}
$address2=$_GET["address2"];				if (!$address2) {$address2=$_POST["address2"];}
$address3=$_GET["address3"];				if (!$address3) {$address3=$_POST["address3"];}
$city=$_GET["city"];						if (!$city) {$city=$_POST["city"];}
$state=$_GET["state"];						if (!$state) {$state=$_POST["state"];}
$postal_code=$_GET["postal_code"];			if (!$postal_code) {$postal_code=$_POST["postal_code"];}
$province=$_GET["province"];				if (!$province) {$province=$_POST["province"];}
$country_code=$_GET["country_code"];		if (!$country_code) {$country_code=$_POST["country_code"];}
$alt_phone=$_GET["alt_phone"];				if (!$alt_phone) {$alt_phone=$_POST["alt_phone"];}
$email=$_GET["email"];						if (!$email) {$email=$_POST["email"];}
$security=$_GET["security"];				if (!$security) {$security=$_POST["security"];}
$comments=$_GET["comments"];				if (!$comments) {$comments=$_POST["comments"];}
$status=$_GET["status"];					if (!$status) {$status=$_POST["status"];}
$submit=$_GET["submit"];					if (!$submit) {$submit=$_POST["submit"];}
$SUBMIT=$_GET["SUBMIT"];					if (!$SUBMIT) {$SUBMIT=$_POST["SUBMIT"];}

### AST GUI database administration modify lead in vicidial_list
### admin_modify_lead.php

# this is the administration lead information modifier screen, the administrator just needs to enter the leadID and then they can view and modify the information in the record for that lead


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");


	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 7;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

if ($WeBRooTWritablE > 0)
	{$fp = fopen ("./project_auth_entries.txt", "a");}

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
			$stmt="SELECT full_name,modify_leads from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname				=$row[0];
			$LOGmodify_leads			=$row[1];

		if ($WeBRooTWritablE > 0)
			{
			fwrite ($fp, "VICIDIAL|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
			fclose($fp);
			}
		}
	else
		{
		if ($WeBRooTWritablE > 0)
			{
			fwrite ($fp, "VICIDIAL|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
			fclose($fp);
			}
		}
	}

?>
<html>
<head>
<title>VICIDIAL ADMIN: Lead record modification</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER><FONT FACE="Courier" COLOR=BLACK SIZE=3>

<? 

if ($end_call > 0)
{

$call_length = ($STARTtime - $call_began);

	### insert a NEW record to the vicidial_closer_log table 
	$stmt="INSERT INTO vicidial_closer_log (lead_id,list_id,campaign_id,call_date,start_epoch,end_epoch,length_in_sec,status,phone_code,phone_number,user,comments,processed) values('$lead_id','$list_id','$campaign_id','$parked_time','$call_began','$STARTtime','$call_length','$status','$phone_code','$phone_number','$PHP_AUTH_USER','$comments','Y')";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	### update the lead record in the vicidial_list table 
	$stmt="UPDATE vicidial_list set status='$status',first_name='$first_name',last_name='$last_name',address1='$address1',address2='$address2',address3='$address3',city='$city',state='$state',province='$province',postal_code='$postal_code',country_code='$country_code',alt_phone='$alt_phone',email='$email',security_phrase='$security',comments='$comments' where lead_id='$lead_id'";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

		echo "information modified<BR><BR>\n";
		echo "<form><input type=button value=\"Close This Window\" onClick=\"javascript:window.close();\"></form>\n";
	
	if ( ($dispo != $status) and ($dispo == 'CBHOLD') )
	{
		### inactivate vicidial_callbacks record for this lead 
		$stmt="UPDATE vicidial_callbacks set status='INACTIVE' where lead_id='$lead_id' and status='ACTIVE';";
		if ($DB) {echo "|$stmt|\n";}
		$rslt=mysql_query($stmt, $link);

		echo "<BR>vicidial_callback record inactivated: $lead_id<BR>\n";
	}

}
else
{
	$stmt="SELECT count(*) from vicidial_list where lead_id='$lead_id'";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$lead_count = $row[0];

	if ($lead_count > 0)
	{

		$stmt="SELECT * from vicidial_list where lead_id='$lead_id'";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$row=mysql_fetch_row($rslt);
		   $lead_id			= "$row[0]";
		   $dispo			= "$row[3]";
		   $tsr				= "$row[4]";
		   $vendor_id		= "$row[5]";
		   $list_id			= "$row[7]";
		   $campaign_id		= "$row[8]";
		   $phone_code		= "$row[10]";
		   $phone_number	= "$row[11]";
		   $title			= "$row[12]";
		   $first_name		= "$row[13]";	#
		   $middle_initial	= "$row[14]";
		   $last_name		= "$row[15]";	#
		   $address1		= "$row[16]";	#
		   $address2		= "$row[17]";	#
		   $address3		= "$row[18]";	#
		   $city			= "$row[19]";	#
		   $state			= "$row[20]";	#
		   $province		= "$row[21]";	#
		   $postal_code		= "$row[22]";	#
		   $country_code	= "$row[23]";	#
		   $gender			= "$row[24]";
		   $date_of_birth	= "$row[25]";
		   $alt_phone		= "$row[26]";	#
		   $email			= "$row[27]";	#
		   $security		= "$row[28]";	#
		   $comments		= "$row[29]";	#

		echo "<br>Call information: $first_name $last_name - $phone_number<br><br><form action=$PHP_SELF method=POST>\n";
		echo "<input type=hidden name=end_call value=1>\n";
		echo "<input type=hidden name=DB value=\"$DB\">\n";
		echo "<input type=hidden name=lead_id value=\"$lead_id\">\n";
		echo "<input type=hidden name=dispo value=\"$dispo\">\n";
		echo "<input type=hidden name=list_id value=\"$list_id\">\n";
		echo "<input type=hidden name=campaign_id value=\"$campaign_id\">\n";
		echo "<input type=hidden name=phone_code value=\"$phone_code\">\n";
		echo "<input type=hidden name=phone_number value=\"$phone_number\">\n";
		echo "<input type=hidden name=server_ip value=\"$server_ip\">\n";
		echo "<input type=hidden name=extension value=\"$extension\">\n";
		echo "<input type=hidden name=channel value=\"$channel\">\n";
		echo "<input type=hidden name=call_began value=\"$call_began\">\n";
		echo "<input type=hidden name=parked_time value=\"$parked_time\">\n";
		echo "<table cellpadding=1 cellspacing=0>\n";
		echo "<tr><td colspan=2>Vendor ID: $vendor_id &nbsp; &nbsp; Lead ID: $lead_id</td></tr>\n";
		echo "<tr><td colspan=2>Fronter: <A HREF=\"user_stats.php?user=$tsr\">$tsr</A> &nbsp; &nbsp; List ID: $list_id</td></tr>\n";
		echo "<tr><td align=right>First Name: </td><td align=left><input type=text name=first_name size=15 maxlength=30 value=\"$first_name\"> &nbsp; \n";
		echo " Last Name: <input type=text name=last_name size=15 maxlength=30 value=\"$last_name\"> </td></tr>\n";
		echo "<tr><td align=right>Address 1 : </td><td align=left><input type=text name=address1 size=30 maxlength=30 value=\"$address1\"></td></tr>\n";
		echo "<tr><td align=right>Address 2 : </td><td align=left><input type=text name=address2 size=30 maxlength=30 value=\"$address2\"></td></tr>\n";
		echo "<tr><td align=right>Address 3 : </td><td align=left><input type=text name=address3 size=30 maxlength=30 value=\"$address3\"></td></tr>\n";
		echo "<tr><td align=right>City : </td><td align=left><input type=text name=city size=30 maxlength=30 value=\"$city\"></td></tr>\n";
		echo "<tr><td align=right>State: </td><td align=left><input type=text name=state size=2 maxlength=2 value=\"$state\"> &nbsp; \n";
		echo " Postal Code: <input type=text name=postal_code size=10 maxlength=10 value=\"$postal_code\"> </td></tr>\n";

		echo "<tr><td align=right>Province : </td><td align=left><input type=text name=province size=30 maxlength=30 value=\"$province\"></td></tr>\n";
		echo "<tr><td align=right>Country : </td><td align=left><input type=text name=country_code size=3 maxlength=3 value=\"$country_code\"></td></tr>\n";
		echo "<tr><td align=right>Alt Phone : </td><td align=left><input type=text name=alt_phone size=10 maxlength=10 value=\"$alt_phone\"></td></tr>\n";
		echo "<tr><td align=right>Email : </td><td align=left><input type=text name=email size=30 maxlength=50 value=\"$email\"></td></tr>\n";
		echo "<tr><td align=right>Security : </td><td align=left><input type=text name=security size=30 maxlength=100 value=\"$security\"></td></tr>\n";
		echo "<tr><td align=right>Comments : </td><td align=left><input type=text name=comments size=30 maxlength=255 value=\"$comments\"></td></tr>\n";
			echo "<tr bgcolor=#B6D3FC><td align=right>Disposition: </td><td align=left><select size=1 name=status>\n";

				$stmt="SELECT * from vicidial_statuses where selectable='Y' order by status";
				$rsltx=mysql_query($stmt, $link);
				$statuses_to_print = mysql_num_rows($rsltx);
				$statuses_list='';

				$o=0;
				$DS=0;
				while ($statuses_to_print > $o) 
				{
					$rowx=mysql_fetch_row($rsltx);
					if ($dispo == "$rowx[0]")
						{$statuses_list .= "<option SELECTED value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n"; $DS++;}
					else
						{$statuses_list .= "<option value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n";}
					$o++;
				}
				if ($DS < 1) {$statuses_list .= "<option SELECTED value=\"$dispo\">$dispo</option>\n";}
			echo "$statuses_list";
			echo "</select></td></tr>\n";


		echo "<tr><td colspan=2><input type=submit name=submit value=\"SUBMIT\"></td></tr>\n";
		echo "</table></form>\n";
		echo "<BR><BR><BR>\n";

	}
	else
	{
		echo "lead lookup FAILED for lead_id $lead_id &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";
#		echo "<a href=\"$PHP_SELF\">Close this window</a>\n<BR><BR>\n";
	}



echo "<br><br>\n";

echo "<center>\n";

echo "<B>CALLS TO THIS LEAD:</B>\n";
echo "<TABLE width=550 cellspacing=0 cellpadding=1>\n";
echo "<tr><td><font size=2>DATE/TIME </td><td align=left><font size=2>LENGTH</td><td align=left><font size=2> STATUS</td><td align=left><font size=2> TSR</td><td align=right><font size=2> CAMPAIGN</td><td align=right><font size=2> LIST</td><td align=right><font size=2> LEAD</td></tr>\n";

	$stmt="select * from vicidial_log where lead_id='$lead_id' order by uniqueid desc limit 50;";
	$rslt=mysql_query($stmt, $link);
	$logs_to_print = mysql_num_rows($rslt);

	$u=0;
	while ($logs_to_print > $u) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $u))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}

			echo "<tr $bgcolor><td><font size=2>$row[4]</td>";
			echo "<td align=left><font size=2> $row[7]</td>\n";
			echo "<td align=left><font size=2> $row[8]</td>\n";
			echo "<td align=left><font size=2> <A HREF=\"user_stats.php?user=$row[11]\" target=\"_blank\">$row[11]</A> </td>\n";
			echo "<td align=right><font size=2> $row[3] </td>\n";
			echo "<td align=right><font size=2> $row[2] </td>\n";
			echo "<td align=right><font size=2> $row[1] </td></tr>\n";

		$u++;
	}


echo "</TABLE></center>\n";



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





