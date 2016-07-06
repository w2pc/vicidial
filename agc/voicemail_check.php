<?
### voicemail_check.php

### This script is designed purely to check whether the voicemail box on the server defined has new and old messages
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $user
###  - $pass
### optional variables:
###  - $format - ('text','debug')
###  - $vmail_box - ('101','1234',...)
### 

# changes
# 50422-1147 First build of script
# 50503-1241 added session_name checking for extra security
# 50711-1201 removed HTTP authentication in favor of user/pass vars
#


require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$user=$_GET["user"];					if (!$user) {$user=$_POST["user"];}
$pass=$_GET["pass"];					if (!$pass) {$pass=$_POST["pass"];}
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$vmail_box=$_GET["vmail_box"];			if (!$vmail_box) {$vmail_box=$_POST["vmail_box"];}

# default optional vars if not set
if (!$format)	{$format="text";}

$version = '0.0.3';
$build = '50711-1201';
$StarTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
if (!$query_date) {$query_date = $NOW_DATE;}

	$stmt="SELECT count(*) from vicidial_users where user='$user' and pass='$pass' and user_level > 0;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

  if( (strlen($user)<2) or (strlen($pass)<2) or (!$auth))
	{
    echo "Invalid Username/Password: |$user|$pass|\n";
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
echo "<!-- VERSION: $version     BUILD: $build    VMBOX: $vmail_box   server_ip: $server_ip-->\n";
echo "<title>Voicemail Check";
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}

	$MT[0]='';
	$row='';   $rowx='';
	if (strlen($vmail_box)<1)
	{
	$channel_live=0;
	echo "voicemail box $vmail_box is not valid\n";
	exit;
	}
	else
	{
	$stmt="SELECT messages,old_messages FROM phones where server_ip='$server_ip' and voicemail_id='$vmail_box' limit 1;";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	$vmails_list = mysql_num_rows($rslt);
	$loop_count=0;
		while ($vmails_list>$loop_count)
		{
		$loop_count++;
		$row=mysql_fetch_row($rslt);
		echo "$row[0]|$row[1]";
		if ($format=='debug') {echo "\n<!-- $row[0]     $row[1] -->";}
		}
	}


if ($format=='debug') 
	{
	$ENDtime = date("U");
	$RUNtime = ($ENDtime - $StarTtime);
	echo "\n<!-- script runtime: $RUNtime seconds -->";
	echo "\n</body>\n</html>\n";
	}
	
exit; 

?>