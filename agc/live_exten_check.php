<?
### live_exten_check.php

### This script is designed purely to send whether the client channel is live and to what channel it is connected
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $PHP_AUTH_USER
###  - $PHP_AUTH_PW
### optional variables:
###  - $format - ('text','debug')
###  - $exten - ('cc101','testphone','49-1','1234','913125551212',...)
###  - $protocol - ('SIP','Zap','IAX2',...)
### 

# changes
# 50404-1249 First build of script
# 50406-1402 added connected trunk lookup
# 50428-1452 added live_inbound check for exten on 2nd line of output
# 50503-1233 added session_name checking for extra security
# 50524-1429 added parked calls count
# 50610-1204 Added NULL check on MySQL results to reduced errors
#

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$exten=$_GET["exten"];					if (!$exten) {$exten=$_POST["exten"];}
$protocol=$_GET["protocol"];			if (!$protocol) {$protocol=$_POST["protocol"];}

# default optional vars if not set
if (!$format)	{$format="text";}

$version = '0.0.6';
$build = '50610-1204';
$STARTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
if (!$query_date) {$query_date = $NOW_DATE;}

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 0;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}
  else
	{

	if( ( (strlen($server_ip)<6) or (!$server_ip) ) or ( (strlen($session_name)<12) or (!$session_name) ) )
		{
		echo "Invalid server_ip: |$server_ip|  or  Invalid session_name: |$session_name|\n";
		exit;
		}
	else
		{
		$stmt="SELECT count(*) from web_client_sessions where session_name='$session_name' and server_ip='$server_ip';";
		if ($DB) {echo "|$stmt|\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$SNauth=$row[0];
		  if(!$SNauth)
			{
			Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
			Header("HTTP/1.0 401 Unauthorized");
			echo "Invalid session_name: |$session_name|$server_ip|\n";
			exit;
			}
		  else
			{
			# do nothing for now
			}
		}
	}

if ($format=='debug')
{
echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build    EXTEN: $exten   server_ip: $server_ip-->\n";
echo "<title>Live Extension Check";
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}


echo "DateTime: $NOW_TIME|";
echo "UnixTime: $STARTtime|";

$stmt="SELECT count(*) FROM parked_channels where server_ip = '$server_ip';";
	if ($format=='debug') {echo "\n<!-- $stmt -->";}
$rslt=mysql_query($stmt, $link);
$row=mysql_fetch_row($rslt);
echo "$row[0]|";

	$MT[0]='';
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($exten)<1) or (strlen($protocol)<3) )
	{
	$channel_live=0;
	echo "Exten $exten is not valid or protocol $protocol is not valid\n";
	exit;
	}
	else
	{
	$stmt="SELECT channel,extension FROM live_sip_channels where server_ip = '$server_ip' and channel LIKE \"$protocol/$exten%\";";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$channels_list = mysql_num_rows($rslt);}
	echo "$channels_list|";
	$loop_count=0;
		while ($channels_list>$loop_count)
		{
		$loop_count++;
		$row=mysql_fetch_row($rslt);
		$ChannelA[$loop_count] = "$row[0]";
		$ChannelB[$loop_count] = "$row[1]";
		if ($format=='debug') {echo "\n<!-- $row[0]     $row[1] -->";}
		}
	}

	$counter=0;
	while($loop_count > $counter)
	{
		$counter++;
	$stmt="SELECT channel FROM live_channels where server_ip = '$server_ip' and channel_data = '$ChannelA[$counter]';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$trunk_count = mysql_num_rows($rslt);}
		if ($trunk_count>0)
		{
		$row=mysql_fetch_row($rslt);
		echo "Conversation: $counter ~";
		echo "ChannelA: $ChannelA[$counter] ~";
		echo "ChannelB: $ChannelB[$counter] ~";
		echo "ChannelBtrunk: $row[0]|";
		}
		else
		{
		$stmt="SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and channel_data = '$ChannelA[$counter]';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		if ($rslt) {$trunk_count = mysql_num_rows($rslt);}
			if ($trunk_count>0)
			{
			$row=mysql_fetch_row($rslt);
			echo "Conversation: $counter ~";
			echo "ChannelA: $ChannelA[$counter] ~";
			echo "ChannelB: $ChannelB[$counter] ~";
			echo "ChannelBtrunk: $row[0]|";
			}
			else
			{
			$stmt="SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and channel LIKE \"$ChannelB[$counter]%\";";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			if ($rslt) {$trunk_count = mysql_num_rows($rslt);}
				if ($trunk_count>0)
				{
				$row=mysql_fetch_row($rslt);
				echo "Conversation: $counter ~";
				echo "ChannelA: $ChannelA[$counter] ~";
				echo "ChannelB: $ChannelB[$counter] ~";
				echo "ChannelBtrunk: $row[0]|";
				}
				else
				{
				$stmt="SELECT channel FROM live_channels where server_ip = '$server_ip' and channel LIKE \"$ChannelB[$counter]%\";";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				if ($rslt) {$trunk_count = mysql_num_rows($rslt);}
					if ($trunk_count>0)
					{
					$row=mysql_fetch_row($rslt);
					echo "Conversation: $counter ~";
					echo "ChannelA: $ChannelA[$counter] ~";
					echo "ChannelB: $ChannelB[$counter] ~";
					echo "ChannelBtrunk: $row[0]|";
					}
					else
					{
					echo "Conversation: $counter ~";
					echo "ChannelA: $ChannelA[$counter] ~";
					echo "ChannelB: $ChannelB[$counter] ~";
					echo "ChannelBtrunk: $ChannelA[$counter]|";
					}
				}
			}
		}
	}

echo "\n";

### check for live_inbound entry
$stmt="select * from live_inbound where server_ip = '$server_ip' and phone_ext = '$exten' and acknowledged='N';";
	if ($format=='debug') {echo "\n<!-- $stmt -->";}
$rslt=mysql_query($stmt, $link);
if ($rslt) {$channels_list = mysql_num_rows($rslt);}
	if ($channels_list>0)
	{
	$row=mysql_fetch_row($rslt);
	$LIuniqueid = "$row[0]";
	$LIchannel = "$row[1]";
	$LIcallerid = "$row[3]";
	$LIdatetime = "$row[6]";
	echo "$LIuniqueid|$LIchannel|$LIcallerid|$LIdatetime|$row[8]|$row[9]|$row[10]|$row[11]|$row[12]|$row[13]|";
	if ($format=='debug') {echo "\n<!-- $row[0]|$row[1]|$row[2]|$row[3]|$row[4]|$row[5]|$row[6]|$row[7]|$row[8]|$row[9]|$row[10]|$row[11]|$row[12]|$row[13]| -->";}
	}




if ($format=='debug') 
	{
	$ENDtime = date("U");
	$RUNtime = ($ENDtime - $STARTtime);
	echo "\n<!-- script runtime: $RUNtime seconds -->";
	echo "\n</body>\n</html>\n";
	}
	
exit; 

?>