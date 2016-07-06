#!/usr/local/ActivePerl-5.8/bin/perl -w
# 
# astVICIDIAL_0.6.pl version 0.6      for Perl/Tk
# by MattF <vicidial@eflo.net> started 2004/01/06
#
# Description:
#
# SUMMARY:
# This program was designed for 
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
# Both - Net::MySQL, Net::Telnet and Time::HiRes perl modules loaded
#
# For this program to work you also need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# On the server side the AST_update.pl program must always be 
# running on a machine somewhere for the client app to receive live information
# and function properly, also there are Asterisk conf file settings and 
# MySQL databases that must be present for the client app to work. 
# Information on these is detailed in the README file
# 
# Use this command to debug with ptkdb and uncomment Devel::ptkdb module below
# perl -d:ptkdb C:\AST_VICI\astVICIDIAL_0.6.pl  
#  
#
# as of version 2, app will no longer have direct interaction with the manager interface
# this leads to way too many crashes of the Asterisk server. Instead this
# program will submit manager commands to a table in the MySQL DB for a command
# running program to blindly execute, and then a listen-only program will update
# the status of the command in the table
# 
# Distributed with no waranty under the GNU Public License
#

# some script specific initial values
$build = '40716-1632';
$DB=1;
$XCF=0;
$DASH='-';
$USUS='__';
$park_frame_list_refresh = 0;
$Default_window = 1;
$zap_frame_list_refresh = 1;
$open_dialpad_window_again = 0;
$updater_duplicate_counter = 0;   
$updater_duplicate_value = '';   
$updater_warning_up=0;
$session_id = '';
$START_DIALING=0;
$call_length_in_seconds=0;
$INCALL=0;
$zap_validation_count=0;
$CONF_RING_MONITOR_on = 0;
$auto_dial_level = '0';
$active_auto_dial = '0';
$WAITING_for_call = '';
$LOGfile="VICIDIAL.log";
$local_DEF = 'Local/';
$local_AMP = '@';
	$SI_manager_command_sent = 0;


require 5.002;

use lib ".\\",".\\libs", './', './libs', '../libs', '/usr/local/perl_TK/libs', 'C:\\AST_VICI\\libs', 'C:\\cygwin\\usr\\local\\perl_TK\\libs';

### Make sure this file is in a libs path or put the absolute path to it
require("AST_VICI_conf.pl");	# local configuration file

#use Devel::ptkdb;	# uncomment if you want to debug with ptkdb

if (!$VICIDIAL_park_on_extension) {$VICIDIAL_park_on_extension = "$conf_on_extension";}
if (!$VICIDIAL_park_on_filename) {$VICIDIAL_park_on_filename = "conf";}

use Time::HiRes ('gettimeofday','usleep','sleep');  # needed to have perl sleep in increments of less than one second
use Net::MySQL;
use Net::Telnet ();

use English;
use Tk;
use Tk::DialogBox;
use Tk::BrowseEntry;

sub current_datetime;

sub login_system;
sub logout_system;

sub start_dialing;
sub stop_dialing;
sub start_recording;
sub stop_recording;
sub hangup_customer;
sub transfer_call;
sub call_dispo_window;
sub dispo_pop_change_value;

sub dtmf_dialpad_window;
sub conf_send_dtmf;
sub conf_park_customer;
sub conf_grab_park_customer;
sub closer_transfer;
sub call_transfer_confirm_window;
sub leave_Xway_call;

sub pause_auto_dialing;
sub resume_auto_dialing;

sub LaunchBrowser_New;

### Create new Perl Tk window instance and name it
	my $MW = MainWindow->new;

	$MW->title("astVICIDIAL - 0.6");
	$MW->Label(-text => "BUILD $build          <vicidial\@eflo.net>")->pack(-side => 'bottom');

	my $ans;

### Time/Date display and sessionID at the top of the screen
	my $time_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$time_frame->Label(-text => "Time:")->pack(-side => 'left');
	my $time_value = $time_frame->Entry(-width => '26', -relief => 'sunken')->pack(-side => 'left');
	my $system_ext_value = $time_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
	$time_frame->Label(-text => "     Session ID:")->pack(-side => 'right');

### config file defined phone ID
	$time_frame->Label(-text => "     Phone ID:")->pack(-side => 'left');
	my $login_value = $time_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
    $login_value->insert('0', $SIP_user);


	my $login_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### login into the system frame
		my $login_system_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');

		### user ID entry field
		my $user_frame = $login_system_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$user_frame->Label(-text => "           User ID:")->pack(-side => 'left');
		my $user_value = $user_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$user_value->insert('0', $login_user);

		### password entry field
		my $pass_frame = $login_system_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$pass_frame->Label(-text => "     Password:")->pack(-side => 'left');
		my $pass_value = $pass_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$pass_value->insert('0', $login_pass);

		### campaign entry field
		my $campaign_frame = $login_system_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$campaign_frame->Label(-text => "     Campaign:")->pack(-side => 'left');
		my $campaign_value = $campaign_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$campaign_value->insert('0', $login_campaign);

		### login button frame, initially viewed
		my $login_button_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		my $login_system_button = $login_button_frame->Button(-text => 'LOGIN', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|login_system_button|||";
					 &event_logger();
					 login_system;
					});
		$login_system_button->pack(-side => 'right', -expand => 'no', -fill => 'both');

		### logout button frame, initially hidden
		my $logout_button_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
	$logout_button_frame->place(-in=>$login_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner
		### button at the bottom of the zap listbox to hangup zap channels
		my $logout_system_button = $logout_button_frame->Button(-text => 'LOGOUT', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|logout_system_button|||";
					 &event_logger();
					 logout_system;
					});
		$logout_system_button->pack(-side => 'right', -expand => 'no', -fill => 'both');


	my $status_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
		### status display field
		my $status_display_frame = $status_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$status_display_frame->Label(-text => "STATUS:")->pack(-side => 'left');
		my $status_value = $status_display_frame->Entry(-width => '70', -relief => 'sunken')->pack(-side => 'left');
		$status_value->insert('0', "READY");


########################################################
### main frame for the dialer app
	my $main_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

#		$main_frame->Label(-text => "  ")->pack(-side => 'top');
	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner

	########################################################
	### buttons at the left side of the main dialer frame
		my $dial_buttons_frame = $main_frame->Frame()->pack(-expand => '0', -fill => 'y', -side => 'left');
		my $AM_dial_buttons_frame = $dial_buttons_frame->Frame()->pack(-expand => '0', -fill => 'y', -side => 'top');

		
		
		### manual dial frame, initially viewed
		my $manual_dial_frame = $AM_dial_buttons_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
		my $start_dialing_button = $manual_dial_frame->Button(-text => 'DIAL NEXT NUMBER', -width => -1, -background => '#CCFFCC', -activebackground => '#99FF99',
					-command => sub 
					{
						$status_value->delete('0', 'end');
						$status_value->insert('0', "Dialing next number ---- DO NOT CLOSE WINDOW");

						$event_string = "CLICK|start_dialing_button|||";
					 &event_logger();
					 start_dialing;
					});
		$start_dialing_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
	#	$start_dialing_button->configure(-state => 'normal');

		### auto dial frame, initially viewed
		my $auto_dial_frame = $AM_dial_buttons_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$auto_dial_frame->place(-in=>$AM_dial_buttons_frame, -width=>1, -height=>1, -x=>5, -y=>1); # hide frame
		my $auto_dialing_button_pause = $auto_dial_frame->Button(-text => 'PAUSE', -width => -1, -background => '#CCFFCC', -activebackground => '#99FF99',
					-command => sub 
					{
						$event_string = "CLICK|auto_dialing_button_pause|||";
					 &event_logger();
					 pause_auto_dialing;
					});
		$auto_dialing_button_pause->pack(-side => 'left', -expand => 'no', -fill => 'both');
	#	$auto_dialing_button_pause->configure(-state => 'normal');

		my $auto_dialing_button_resume = $auto_dial_frame->Button(-text => 'RESUME', -width => -1, -background => '#CCFFCC', -activebackground => '#99FF99',
					-command => sub 
					{
						$event_string = "CLICK|auto_dialing_button_resume|||";
					 &event_logger();
					 resume_auto_dialing;
					});
		$auto_dialing_button_resume->pack(-side => 'right', -expand => 'no', -fill => 'both');
	#	$auto_dialing_button_resume->configure(-state => 'normal');

		
		
		
		
		
		
		
		

	### display field that shows the filename as soon as recording is started
		my $rec_fname_frame = $dial_buttons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_fname_frame->Label(-text => "RECORDING FILENAME:")->pack(-side => 'top');
		my $rec_fname_value = $rec_fname_frame->Entry(-width => '25', -relief => 'sunken')->pack(-side => 'top');
		$rec_fname_value->insert('0', '');

	### display field that shows the unique recording ID in the database only after the recording session is finished
		my $rec_recid_frame = $dial_buttons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_recid_frame->Label(-text => "RECORDING ID:")->pack(-side => 'left');
		my $rec_recid_value = $rec_recid_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
		$rec_recid_value->insert('0', '');

		my $record_buttons_frame = $dial_buttons_frame->Frame()->pack(-expand => '0', -fill => 'y', -side => 'top');

		my $start_recording_button = $record_buttons_frame->Button(-text => 'START REC', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|start_recording_button|||";
					 &event_logger();
					 start_recording;
					});
		$start_recording_button->pack(-side => 'left', -expand => 'no', -fill => 'both');
	#	$start_recording_button->configure(-state => 'disabled');

		my $stop_recording_button = $record_buttons_frame->Button(-text => 'STOP REC', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|stop_recording_button|||";
					 &event_logger();
					 stop_recording;
					});
		$stop_recording_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
		$stop_recording_button->configure(-state => 'disabled');

		my $rec_recid_spacer_frame = $dial_buttons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_recid_spacer_frame->Label(-text => "-----     -----")->pack(-side => 'bottom');


		my $park_buttons_frame = $dial_buttons_frame->Frame()->pack(-expand => '0', -fill => 'y', -side => 'top');

		my $park_call_button = $park_buttons_frame->Button(-text => 'PARK CALL', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|park_call_button|||";
					 &event_logger();
					 $status_value->delete('0', 'end');
					$status_value->insert('0', "     ----- CALL HAS BEEN PARKED ----- $phone_code$phone_number     TO GET CALL BACK CLICK ON THE \"GRAB PARK\" BUTTON");
					 conf_park_customer();
					});
		$park_call_button->pack(-side => 'left', -expand => 'no', -fill => 'both');
		$park_call_button->configure(-state => 'disabled');

		my $grab_park_button = $park_buttons_frame->Button(-text => 'GRAB PARK', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|grab_park_button|||";
					 &event_logger();
					 $status_value->delete('0', 'end');
					$status_value->insert('0', "     ----- PARKED CALL HAS BEEN GRABBED ----- $phone_code$phone_number ");
					 conf_grab_park_customer();
					});
		$grab_park_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
		$grab_park_button->configure(-state => 'disabled');


		my $customer_hungup_button = $dial_buttons_frame->Button(-text => 'CUSTOMER HUNGUP ', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|customer_hungup_button|||";
					 &event_logger();
					 customer_hungup();
					});
		$customer_hungup_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$customer_hungup_button->configure(-state => 'disabled');

		my $hangup_customer_button = $dial_buttons_frame->Button(-text => 'HANGUP CUSTOMER', -width => -1, -background => '#FFCCFF', -activebackground => '#FF99FF',
					-command => sub 
					{
						$event_string = "CLICK|hangup_customer_button|||";
					 &event_logger();
					$customer_hungup_button->configure(-state => 'normal');
					 hangup_customer;
					});
		$hangup_customer_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$hangup_customer_button->configure(-state => 'disabled');

		my $transfer_call_button = $dial_buttons_frame->Button(-text => 'TRANSFER - CONF', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|transfer_call_button|||";
					 &event_logger();
					 transfer_call;
					});
		$transfer_call_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$transfer_call_button->configure(-state => 'disabled');

	########################################################
	### spacer frome of the main dialer frame
		my $middle_spacer_frame = $main_frame->Frame()->pack(-expand => '0', -fill => 'none', -side => 'left');

		$middle_spacer_frame->Label(-text => "  ")->pack(-side => 'top');


	########################################################
	### call info at the right side of the main dialer frame
		my $dial_closer_frame = $main_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'none', -side => 'right', -anchor   => "ne");
			$dial_closer_frame->place(-in=>$main_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left

		my $dial_info_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'none', -side => 'left', -anchor   => "nw");

		$dial_info_frame->Label(-text => " ")->pack(-side => 'top');

		### call system display-only fields
		my $call_sys_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$call_sys_frame->Label(-text => "Dial Code:")->pack(-side => 'left');
		my $dial_code_value = $call_sys_frame->Entry(-width => '6', -relief => 'sunken')->pack(-side => 'left');
		$dial_code_value->insert('0', '');
		$call_sys_frame->Label(-text => "  Call Length:")->pack(-side => 'left');
		my $call_length_value = $call_sys_frame->Entry(-width => '5', -relief => 'sunken')->pack(-side => 'left');
		$call_length_value->insert('0', '');
		$call_sys_frame->Label(-text => "  Zap:")->pack(-side => 'left');
		my $zap_channel_value = $call_sys_frame->Entry(-width => '12', -relief => 'sunken')->pack(-side => 'left');
		$zap_channel_value->insert('0', '');

#		$dial_info_frame->Label(-text => " ")->pack(-side => 'top');
		$dial_info_frame->Label(-text => "Customer Information:")->pack(-side => 'top');

		### full name entry fields
		my $full_name_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$full_name_frame->Label(-text => "Title:     ")->pack(-side => 'left');
		my $title_name_value = $full_name_frame->Entry(-width => '4', -relief => 'sunken')->pack(-side => 'left');
		$title_name_value->insert('0', '');
		$full_name_frame->Label(-text => " First:")->pack(-side => 'left');
		my $first_name_value = $full_name_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$first_name_value->insert('0', '');
		$full_name_frame->Label(-text => " MI:")->pack(-side => 'left');
		my $middle_name_value = $full_name_frame->Entry(-width => '1', -relief => 'sunken')->pack(-side => 'left');
		$middle_name_value->insert('0', '');
		$full_name_frame->Label(-text => " Last:")->pack(-side => 'left');
		my $last_name_value = $full_name_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$last_name_value->insert('0', '');


		my $address_info_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");

		my $address_form_frame = $address_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left', -anchor   => "nw");

		my $address_web_button_frame = $address_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right', -anchor   => "w");

		### address a entry field
		my $address_a_frame = $address_form_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$address_a_frame->Label(-text => "Address 1:")->pack(-side => 'left');
		my $address_a_value = $address_a_frame->Entry(-width => '30', -relief => 'sunken')->pack(-side => 'left');
		$address_a_value->insert('0', '');

		### address b entry field
		my $address_b_frame = $address_form_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$address_b_frame->Label(-text => "Address 2:")->pack(-side => 'left');
		my $address_b_value = $address_b_frame->Entry(-width => '30', -relief => 'sunken')->pack(-side => 'left');
		$address_b_value->insert('0', '');

		### address c entry field
		my $address_c_frame = $address_form_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$address_c_frame->Label(-text => "Address 3:")->pack(-side => 'left');
		my $address_c_value = $address_c_frame->Entry(-width => '30', -relief => 'sunken')->pack(-side => 'left');
		$address_c_value->insert('0', '');


		my $address_web_button = $address_web_button_frame->Button(-text => "WEB\nFORM", -width => -1, -background => '#FFFFFF', -activebackground => '#FFFFFF',
					-command => sub 
					{
						$event_string = "CLICK|address_web_button|||";
					 &event_logger();

					&create_VICIDIAL_query_string;

					$url="$VICIDIAL_web_form_address$VICIDIAL_web_QUERY_STRING";
					print STDERR "$url\n";
						LaunchBrowser_New();
					});
		$address_web_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$address_web_button->configure(-state => 'disabled');


		### city state entry fields
		my $city_state_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$city_state_frame->Label(-text => "City:     ")->pack(-side => 'left');
		my $city_value = $city_state_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$city_value->insert('0', '');
		$city_state_frame->Label(-text => "   State:")->pack(-side => 'left');
		my $state_value = $city_state_frame->Entry(-width => '2', -relief => 'sunken')->pack(-side => 'left');
		$state_value->insert('0', '');

		### province postal code entry fields
		my $prov_post_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$prov_post_frame->Label(-text => "Province:")->pack(-side => 'left');
		my $province_value = $prov_post_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$province_value->insert('0', '');
		$prov_post_frame->Label(-text => "   Post Code:")->pack(-side => 'left');
		my $post_value = $prov_post_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$post_value->insert('0', '');

		### phone number entry field
		my $phone_number_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$phone_number_frame->Label(-text => "Phone:")->pack(-side => 'left');
		my $phone_value = $phone_number_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$phone_value->insert('0', '');

		### vendor_id entry field
		$phone_number_frame->Label(-text => "           Vendor ID:")->pack(-side => 'left');
		my $vendor_id_value = $phone_number_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$vendor_id_value->insert('0', '');


		### alt phone number entry field
		my $alt_phone_number_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$alt_phone_number_frame->Label(-text => "Alt Phone:")->pack(-side => 'left');
		my $alt_phone_value = $alt_phone_number_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$alt_phone_value->insert('0', '');

		### security entry field
		$alt_phone_number_frame->Label(-text => " Show:")->pack(-side => 'left');
		my $security_value = $alt_phone_number_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$security_value->insert('0', '');

		### email entry field
		$alt_phone_number_frame->Label(-text => " E:")->pack(-side => 'left');
		my $email_value = $alt_phone_number_frame->Entry(-width => '5', -relief => 'sunken')->pack(-side => 'left');
		$email_value->insert('0', '');


		$dial_info_frame->Label(-text => " ")->pack(-side => 'top');

		### comments entry fields
		my $comments_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$comments_frame->Label(-text => "Comments:")->pack(-side => 'left');
		my $comments_value = $comments_frame->Entry(-width => '45', -relief => 'sunken')->pack(-side => 'left');
		$comments_value->insert('0', '');



	### send-to-closer frame

		my $closer_send_button = $dial_closer_frame->Button(-text => " S        \n E     C\n N     L\n D     O\n        S\n T     E\n O     R", -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|closer_send_button|||";
					 &event_logger();

					 &closer_transfer();
					});
		$closer_send_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$closer_send_button->configure(-state => 'normal');

		my $dial_closer_code_frame = $dial_closer_frame->Frame(-background => '#CCCCFF')->pack(-expand => '0', -fill => 'both', -side => 'top', -anchor   => "ne");
		$dial_closer_code_frame->Label(-text => "\nCode:   ", -background => '#CCCCFF')->pack(-side => 'left');
		my $closer_send_code_value = $dial_closer_code_frame->Entry(-width => '2', -relief => 'sunken')->pack(-side => 'left');
		$closer_send_code_value->insert('0', '');

		$dial_closer_frame->Label(-text => " \n ", -background => '#CCCCFF')->pack(-side => 'top');

		my $leave_Xway_call_button = $dial_closer_frame->Button(-text => "LEAVE\n3-WAY\nCALL", -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|leave_Xway_call_button|||";
					 &event_logger();

					 &leave_Xway_call();
					});
		$leave_Xway_call_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$leave_Xway_call_button->configure(-state => 'normal');



	########################################################
	### disposition frame for the dialer app
		my $dispo_frame = $MW->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			$dispo_frame->Label(-text => "  ", -background => '#FFFFCC')->pack(-side => 'top');
		$dispo_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left

		### disposition entry fields
		my $dispo_entry_frame = $dispo_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$dispo_entry_frame->Label(-text => "Disposition:", -background => '#FFFFCC')->pack(-side => 'left');
		my $dispo_value = $dispo_entry_frame->Entry(-width => '8', -relief => 'sunken')->pack(-side => 'left');
		$dispo_value->insert('0', '');
		$dispo_entry_frame->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'left');
		my $dispo_ext_value = $dispo_entry_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$dispo_ext_value->insert('0', '');





	########################################################
	### transfer - conference frame for the dialer app
		my $xferconf_frame = $MW->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'bottom');

#			$xferconf_frame->Label(-text => "  ", -background => '#CCCCFF')->pack(-side => 'top');
		$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left

		my $xferconf_call_frame = $xferconf_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'left');

		### xferconf entry fields
			$xferconf_call_frame->Label(-text => " ", -background => '#CCCCFF')->pack(-side => 'top');

		my $xfer_number_entry_frame = $xferconf_call_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$xfer_number_entry_frame->Label(-text => "Number to call:", -background => '#CCCCFF')->pack(-side => 'left');
		my $xfer_number_value = $xfer_number_entry_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$xfer_number_value->insert('0', '');
		$xfer_number_entry_frame->Label(-text => " Length:", -background => '#CCCCFF')->pack(-side => 'left');
		my $xfer_length_value = $xfer_number_entry_frame->Entry(-width => '5', -relief => 'sunken')->pack(-side => 'left');
		$xfer_length_value->insert('0', '');
		$xfer_number_entry_frame->Label(-text => " Zap:", -background => '#CCCCFF')->pack(-side => 'left');
		my $xfer_channel_value = $xfer_number_entry_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$xfer_channel_value->insert('0', '');

		### xferconf dial buttons
		my $xfer_dial_buttons_frame = $xferconf_call_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");


		my $dial_with_cust_button = $xfer_dial_buttons_frame->Button(-text => 'DIAL WITH CUSTOMER', -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|dial_with_cust_button|||";
					 &event_logger();
					conf_dial_number();
					});
		$dial_with_cust_button->pack(-side => 'left', -expand => 'no', -fill => 'both');


		my $dial_park_cust_button = $xfer_dial_buttons_frame->Button(-text => 'PARK CUSTOMER DIAL', -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|dial_park_cust_button|||";
					 &event_logger();
					conf_park_customer();
					conf_dial_number();
					});
		$dial_park_cust_button->pack(-side => 'left', -expand => 'no', -fill => 'both');


		my $dial_blind_xfer_button = $xfer_dial_buttons_frame->Button(-text => 'DIAL BLIND TRANSFER', -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|dial_blind_xfer_button|||";
					 &event_logger();
					conf_blind_xfer_customer();
					});
		$dial_blind_xfer_button->pack(-side => 'left', -expand => 'no', -fill => 'both');



		### xferconf conference buttons
		my $xfer_conf_buttons_frame = $xferconf_call_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");


		my $grab_park_cust_button = $xfer_conf_buttons_frame->Button(-text => 'GRAB PARK CUSTOMER', -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|grab_park_cust_button|||";
					 &event_logger();
					conf_grab_park_customer();
					});
		$grab_park_cust_button->pack(-side => 'left', -expand => 'no', -fill => 'both');
		$grab_park_cust_button->configure(-state => 'disabled');


		my $hangup_xfer_line_button = $xfer_conf_buttons_frame->Button(-text => 'HANGUP XFER LINE  ', -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|hangup_xfer_line_button|||";
					 &event_logger();
					conf_hangup_xfer_line();
					});
		$hangup_xfer_line_button->pack(-side => 'left', -expand => 'no', -fill => 'both');
		$hangup_xfer_line_button->configure(-state => 'disabled');


		my $hangup_both_lines_button = $xfer_conf_buttons_frame->Button(-text => 'HANGUP BOTH LINES  ', -width => -1, -background => '#CCCCFF', -activebackground => '#9999FF',
					-command => sub 
					{
						$event_string = "CLICK|hangup_both_lines_button|||";
					 &event_logger();
					conf_hangup_xfer_line();
					hangup_customer();
					});
		$hangup_both_lines_button->pack(-side => 'left', -expand => 'no', -fill => 'both');





		my $xfer_preset_dtmf_frame = $xferconf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'right', -anchor   => "ne");

		my $xferconf_dtmf_frame = $xferconf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'right', -anchor   => "ne");

		### xferconf send DTMF entry fields
		my $xfer_number_dtmf_entry_frame = $xferconf_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");
		$xfer_number_dtmf_entry_frame->Label(-text => "DTMF to send:", -background => '#FFCCCC')->pack(-side => 'top');
		my $xfer_dtmf_value = $xfer_number_dtmf_entry_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'top');
		$xfer_dtmf_value->insert('0', '');

		my $send_dtmf_button = $xferconf_dtmf_frame->Button(-text => 'SEND DTMF', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|send_dtmf_button|||";
					 &event_logger();
					conf_send_dtmf();
					});
		$send_dtmf_button->pack(-side => 'top', -expand => 'no', -fill => 'both');

		my $dtmf_dialpad_button = $xferconf_dtmf_frame->Button(-text => 'DIALPAD', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|dtmf_dialpad_button|||";
					 &event_logger();
					dtmf_dialpad_window();
					});
		$dtmf_dialpad_button->pack(-side => 'top', -expand => 'no', -fill => 'both');

#		my $xfer_preset_dtmf_frame = $xferconf_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");

		my $xfer_preset_dtmf_frame_A = $xfer_preset_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");

		my $xfer_preset_dtmf_frame_B = $xfer_preset_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");

		my $xfer_preset_dtmf_frame_C = $xfer_preset_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");

		my $pop_dtmf_ukone_button = $xfer_preset_dtmf_frame_A->Button(-text => 'UK1', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_ukone_button|8172775772|,7261,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ',7261,,,,1,,,2900,,,1');
					});
		$pop_dtmf_ukone_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');

		my $pop_dtmf_uktwo_button = $xfer_preset_dtmf_frame_A->Button(-text => 'UK2', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_uktwo_button|8172775772|,7411,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ',7411,,,,1,,,2900,,,1');
					});
		$pop_dtmf_uktwo_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');

		my $pop_dtmf_ukthree_button = $xfer_preset_dtmf_frame_A->Button(-text => 'UK3', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_ukthree_button|8172775772|,7417,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ',7417,,,,1,,,2900,,,1');
					});
		$pop_dtmf_ukthree_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');

		my $pop_dtmf_ausone_button = $xfer_preset_dtmf_frame_B->Button(-text => 'AUS1', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_ausone_button|8172775772|,7412,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ',7412,,,,1,,,2900,,,1');
					});
		$pop_dtmf_ausone_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');

		my $pop_dtmf_austwo_button = $xfer_preset_dtmf_frame_B->Button(-text => 'AUS2', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_austwo_button|8172775772|,7418,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ',7418,,,,1,,,2900,,,1');
					});
		$pop_dtmf_austwo_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');

		my $pop_dtmf_usone_button = $xfer_preset_dtmf_frame_B->Button(-text => 'US1', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_usone_button|8172775772|,7402,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ',7402,,,,1,,,2900,,,1');
					});
		$pop_dtmf_usone_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');

		my $pop_dtmf_ustwo_button = $xfer_preset_dtmf_frame_C->Button(-text => 'US2 MW', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_ustwo_button|8175094450|,1,,5465#,,,$phone_number,,,,,,,1,,#|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8175094450');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', ",1,,5465#,,,$phone_number,,,,,,,1,,#");
					});
		$pop_dtmf_ustwo_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');



		


################################################################################################################
### set various start and refresh routines at millisecond intervals
################################################################################################################
sub RefreshList
{
	$MW->after (1000, \&current_datetime);
	$MW->repeat (1000, \&current_datetime);
	$MW->repeat (1000, \&validate_live_channels);
	$MW->repeat (1000, \&check_for_auto_incoming);
			return;
}


RefreshList();

MainLoop();








##########�##########�##########�##########�##########�##########�##########�##########
##########�##########�##########�##########�##########�##########�##########�##########
### SUBROUTINES GO HERE
##########�##########�##########�##########�##########�##########�##########�##########
##########�##########�##########�##########�##########�##########�##########�##########



sub start_dialing {&call_next_number;}
sub stop_dialing {}
sub start_recording {}
sub stop_recording {}


sub transfer_call {

	$transfer_call_button->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'disabled');

	$xferconf_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
	if ($VICIDIAL_allow_closers) {$dial_closer_frame->pack(-expand => '1', -fill => 'both', -side => 'right');}


}


################################################################################
################################################################################
### time based or recurring subroutines
################################################################################
################################################################################

##########################################
### get the current date and time
##########################################
sub current_datetime
{

$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = ($year + 1900);
	$CIDyear=($year-2000);
	$mon++;
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}
	$CIDdate = "$CIDyear$mon$mday$hour$min$sec";
	$filedate = "$year$mon$mday$DASH$hour$min$sec";
	$tsSQLdate = "$year$mon$mday$hour$min$sec";
	$SQLdate = "$year-$mon-$mday $hour:$min:$sec";
	$epochdate = "$secX";
	$displaydate = "   $year/$mon/$mday           $hour:$min:$sec";

		$time_value->delete('0', 'end');
		$time_value->insert('0', $displaydate);

my $LIVE_CHANNEL = $zap_channel_value->get;
if (length($LIVE_CHANNEL)> 4)
	{
	$call_length_in_seconds++;
		$call_length_value->delete('0', 'end');
		$call_length_value->insert('0', $call_length_in_seconds);

	}
my $XFER_CHANNEL = $xfer_channel_value->get;
if (length($XFER_CHANNEL)> 4)
	{
	$xfer_length_in_seconds++;
		$xfer_length_value->delete('0', 'end');
		$xfer_length_value->insert('0', $xfer_length_in_seconds);

	}

if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
	{
	$random = int( rand(9999999)) + 10000000;

	### update the vicidial_live_agents every second with a new random number so it is shown to be alive
	$stmtA = "UPDATE vicidial_live_agents set random_id='$random' where user='$user' and server_ip='$server_ip';";
	$dbhA->query($stmtA);
	}

}



##########################################
### while in auto_dial mode, check for calls being sent to us
##########################################
sub check_for_auto_incoming
{
if ($WAITING_for_call)
	{
	$lead_id='';   $uniqueid='';   $callerid='';   $customer_zap_channel='';
	$dbhA->query("SELECT lead_id,uniqueid,callerid,channel FROM vicidial_live_agents where server_ip = '$server_ip' and user='$user' and campaign_id='$campaign' and status='QUEUE'");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
		 $rec_countH=0;
		   while ( $record = $iter->each)
		   {
		   $lead_id =				"$record->[0]";
		   $uniqueid =				"$record->[1]";
		   $callerid =				"$record->[2]";
		   $customer_zap_channel =	"$record->[3]";
		   } 
	   }
		if (length($customer_zap_channel)>5)
			{
			$WAITING_for_call=0;

			$stmtA = "UPDATE vicidial_live_agents set status='INCALL',last_call_time='$SQLdate' where user='$user' and server_ip='$server_ip'";
			print STDERR "|$stmtA|\n";
		   $dbhA->query("$stmtA");
			my $affected_rows = $dbhA->get_affected_rows_length;
			print STDERR "vicidial_live_agents rows updated: |$affected_rows|\n";

				&auto_next_lead_info;
			}



	}
}





##########################################
### get the current date and time
##########################################
sub validate_live_channels
{

if ($open_dialpad_window_again)
	{
	$open_dialpad_window_again = 0;
	&dtmf_dialpad_window;
	}

if ($open_call_dispo_window_again)
	{
	$open_call_dispo_window_again = 0;
	&call_dispo_window;
	}


	$cust_channel = $zap_channel_value->get;
	$xfer_channel = $xfer_channel_value->get;

if ( (length($cust_channel)>4) && ($call_length_in_seconds > 5) )
	{

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	$dbhA->query("SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$cust_channel' and extension IN('$session_id','conf','ring','$VICIDIAL_park_on_filename','park','universal_')");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_countH=0;
		   while ( $record = $iter->each)
		   {
		   $rec_countH = "$record->[0]";
		   } 
	   }
	#$dbhA->close;

	if ($rec_countH)	### if channel active set inactivity counter to zero
		{
		$zap_validation_count=0;
		}
	else
		{
		$zap_validation_count++;
		print "Zap channel down : |$cust_channel|$zap_validation_count|";
		if ($zap_validation_count > 1) 
			{

			$zap_channel_value->delete('0', 'end');
		#	$start_recording_button->configure(-state => 'disabled');
			$transfer_call_button->configure(-state => 'disabled');

			$zap_validation_count=0;

			$event_string = "SUBRT|validate_live_channels|Zap channel down : |$cust_channel|$zap_validation_count|";
			event_logger;

			}
		}

	}

if ( (length($xfer_channel)>4) && ($xfer_length_in_seconds > 5) )
	{

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	$dbhA->query("SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$xfer_channel' and extension IN('$session_id','conf','ring','$VICIDIAL_park_on_filename','park','universal_')");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_countH=0;
		   while ( $record = $iter->each)
		   {
		   $rec_countH = "$record->[0]";
		   } 
	   }
	#$dbhA->close;

	if ($rec_countH)	### if channel active set inactivity counter to zero
		{
		$zap_xfer_validation_count=0;
		}
	else
		{
		$zap_xfer_validation_count++;
		print "Zap channel down : |$xfer_channel|$zap_xfer_validation_count|";
		if ($zap_xfer_validation_count > 1) 
			{

			$xfer_channel_value->delete('0', 'end');

			$zap_xfer_validation_count=0;

			$event_string = "SUBRT|validate_live_channels|Xfer channel down : |$xfer_channel|$zap_xfer_validation_count|";
			event_logger;

			}
		}

	}

if ($CONFERENCE_RECORDING)
	{
	$conf_silent_prefix = '7';

	   $dbhA->query("SELECT channel,extension FROM live_sip_channels where server_ip = '$server_ip' and extension = '$session_id' order by channel desc");
		$rec_val_counter=0;
	   if ($dbhA->has_selected_record)
		{
	   $iter=$dbhA->create_record_iterator;
		   while ( $record = $iter->each)
			{
			#	if ($DB) {print STDERR "RECORDING: |$session_id|$record->[0]|$record->[1]|\n";}
			   if ( ($record->[0] =~ /Local\/$conf_silent_prefix$session_id\@/) && ($record->[1] =~ /$session_id/) )
					{
		   			$status_value->delete('0', 'end');
					$status_value->insert('0', "$record->[0]");
					$CONFERENCE_RECORDING_CHANNEL = "$record->[0]";
					$rec_val_counter++;
					}


			}
		}

	if ($rec_val_counter)	### if channel active set inactivity counter to zero
		{
		$recording_validation_count=0;
		}
	else
		{
		$recording_validation_count++;
		print "Recording channel down : |$CONFERENCE_RECORDING_CHANNEL|$recording_validation_count|";
		if ($recording_validation_count > 1) 
			{
			$event_string = "SUBRT|validate_rec_channels|Rec channel down : |$CONFERENCE_RECORDING_CHANNEL|$recording_validation_count|";
			event_logger;

			$status_value->delete('0', 'end');
			$CONFERENCE_RECORDING_CHANNEL = "";

			$recording_validation_count=0;
			$start_recording_button->configure(-state => 'normal');
			$stop_recording_button->configure(-state => 'disabled');

			$CONFERENCE_RECORDING = 0;
			}
		}

	}

}





################################################################################
################################################################################
### event or button based subroutines
################################################################################
################################################################################

##########################################
##########################################
### write event to client logfile
##########################################
##########################################
sub event_logger {
	### open the log file for writing ###
	open(Lout, ">>$LOGfile")
			|| die "Can't open $LOGfile: $!\n";

	print Lout "$SQLdate|$build|$event_string|\n";

	close(Lout);

$event_string='';
}





##########################################
##########################################
### login to the system
##########################################
##########################################
sub login_system {
    my $Luser = $user_value->get;
    my $Lpass = $pass_value->get;
    my $Lcampaign = $campaign_value->get;
	$user = $Luser;
	$campaign = $Lcampaign;

	print STDERR "LOGGING IN as |$Luser|$Lpass| on campaign |$Lcampaign|\n";

		$event_string = "SUBRT|login_system|LOGGING IN as |$Luser|$Lpass| on campaign |$Lcampaign|";
	 event_logger;

	my $login_dialog = $MW->DialogBox( -title   => "System Login Status:",
                                 -buttons => [ "OK" ],
				);

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	$dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";


	### check to see if campaign entered exists and is active
	   $dbhA->query("SELECT count(*) FROM vicidial_campaigns where campaign_id='$campaign' and active='Y'");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_countG=0;
		   while ( $record = $iter->each)
		   {
		   $rec_countG = "$record->[0]";
		   } 
	   }

	if ($rec_countG)	### if campaign active continue with login process
		{
		   $dbhA->query("SELECT count(*) FROM vicidial_users where user='$Luser' and pass='$Lpass'");
		   if ($dbhA->has_selected_record)
		   {
		   $iter=$dbhA->create_record_iterator;
			 $rec_count=0;
			   while ( $record = $iter->each)
			   {
		#	   print STDERR $record->[0]," - conference room\n";
			   $rec_count = "$record->[0]";
			   } 
		   }

		if ($rec_count)
			{

			&get_dispo_list;

	#		&call_dispo_window;

			&get_number_of_leads_to_call_in_campaign;

			if ($campaign_leads_to_call > 0)
				{
			### insert an entry into the user log for the login event
				$stmtA = "INSERT INTO vicidial_user_log values('','$Luser','LOGIN','$Lcampaign','$SQLdate','$epochdate')";
				$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";


				### check to see if the user has a conf extension already, this happens if they previously exited uncleanly
				$dbhA->query("SELECT conf_exten FROM vicidial_conferences where extension='$SIP_user' and server_ip = '$server_ip' LIMIT 1");
				if ($dbhA->has_selected_record)
					{
					$iter=$dbhA->create_record_iterator;
					 $recB_count=0;
					   while ( $record = $iter->each)
					   {
					#	   print STDERR $record->[0]," - conference room\n";
					   $session_id = "$record->[0]";
					   $recB_count++;
					   } 
					}
				if ($recB_count)
					{
					print STDERR "USING PREVIOUS MEETME ROOM - $session_id - $SQLdate\n";
					}
				else
					{
					$dbhA->query("SELECT conf_exten FROM vicidial_conferences where server_ip = '$server_ip' and extension='' LIMIT 1");
					if ($dbhA->has_selected_record)
						{
						$iter=$dbhA->create_record_iterator;
						 $recC_count=0;
						   while ( $record = $iter->each)
						   {
						   $session_id = "$record->[0]";
						   $recC_count++;
						   } 
						}

					$stmtA = "UPDATE vicidial_conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$session_id'";
					$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
					}

					print STDERR $session_id," - conference room - $SQLdate\n";
					$system_ext_value->delete('0', 'end');
					$system_ext_value->insert('0', $session_id);


					$stmtA = "UPDATE vicidial_list set status='N', user='' where status IN('QUEUE','INCALL') and user ='$user'";
					print STDERR "|$stmtA|\n";
				   $dbhA->query("$stmtA");
					my $affected_rows = $dbhA->get_affected_rows_length;
					print STDERR "old QUEUE and INCALL reverted list:   |$affected_rows|\n";

					$stmtA = "DELETE from vicidial_hopper where status IN('QUEUE','INCALL','DONE') and user ='$user'";
					print STDERR "|$stmtA|\n";
				   $dbhA->query("$stmtA");
					my $affected_rows = $dbhA->get_affected_rows_length;
					print STDERR "old QUEUE and INCALL reverted hopper: |$affected_rows|\n";

					$stmtA = "DELETE from vicidial_live_agents where user ='$user'";
					print STDERR "|$stmtA|\n";
				   $dbhA->query("$stmtA");
					my $affected_rows = $dbhA->get_affected_rows_length;
					print STDERR "old vicidial_live_agents records cleared: |$affected_rows|\n";

					#$dbhA->close;


				##### popup a message window saying that login was successful
				$login_dialog->add("Label", -text => "you have logged in as\n user: $Luser \n on phone: $SIP_user \n\n campaign: $campaign\n\n PLEASE ANSWER YOUR PHONE WHEN IT RINGS")->pack;
				$login_dialog->Show;


				$login_button_frame->place(-in=>$login_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner pixel
				$logout_button_frame->pack(-expand => '1', -fill => 'both', -side => 'top');


			### use manager middleware-app to connect the phone to the user
				$SIqueryCID = "SI$CIDdate$session_id";

			### insert a NEW record to the vicidial_manager table to be processed
				$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$SIqueryCID','Channel: $SIP_user','Context: $ext_context','Exten: $session_id','Priority: 1','Callerid: $SIqueryCID','','','','','')";
				$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

				$SI_manager_command_sent = 1;

					$event_string = "SUBRT|login_system|SI|$SIqueryCID|$stmtA|";
				 event_logger;

				$status_value->delete('0', 'end');
				$status_value->insert('0', "You have logged in to campaign $campaign  with $campaign_leads_to_call leads to call");

			##### CHECK TO SEE IF WE WILL BE AUTO-DIALING OR MANUAL DIALING
			$auto_dial_level=0;
			$dbhA->query("SELECT auto_dial_level FROM vicidial_campaigns where campaign_id='$campaign'");
				if ($dbhA->has_selected_record)
					{
					$iter=$dbhA->create_record_iterator;
					 $recADL_count=0;
					   while ( $record = $iter->each)
					   {
					   $auto_dial_level = "$record->[0]";
					   $recADL_count++;
					   } 
					}
				
				if ($auto_dial_level > 0)
					{
					$manual_dial_frame->place(-in=>$AM_dial_buttons_frame, -width=>1, -height=>1, -x=>5, -y=>1); # hide the frame
					$auto_dial_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
						$SHOW_auto_dial_frame=1;
					print STDERR "Auto dial level:   |$auto_dial_level|\n";

					$auto_dialing_button_pause->configure(-state => 'disabled');
					$auto_dialing_button_resume->configure(-state => 'normal');

				### insert a new record to the vicidial_live_agents table for this session login
					$stmtA = "INSERT INTO vicidial_live_agents values('','$user','$server_ip','$session_id','$SIP_user','PAUSED','','$campaign','','','','$random','$SQLdate','$tsSQLdate','$SQLdate')";
					$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

					}
				else
					{
					if ($SHOW_auto_dial_frame)
						{
						$auto_dial_frame->place(-in=>$AM_dial_buttons_frame, -width=>1, -height=>1, -x=>5, -y=>1); # hide
						$manual_dial_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
							$SHOW_auto_dial_frame=0;
						}

					print STDERR "Manual dialing this login:   |$auto_dial_level|\n";

					$start_dialing_button->configure(-state => 'normal');
					}


				##### events to trigger after login successful go here


				$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');


				}

			else
				{
#				#$dbhA->close;

				$status_value->delete('0', 'end');
				$status_value->insert('0', "Login failed, no leads to dial in this campaign");

				$login_dialog->add("Label", -text => "login failed: no leads to dial in this campaign: $Lcampaign")->pack;
				$login_dialog->Show;
				}

			}
		else
			{
			#$dbhA->close;

			$status_value->delete('0', 'end');
			$status_value->insert('0', "Login failed, bad user, try again");

			$login_dialog->add("Label", -text => "login failed for user: $Luser pass: $Lpass")->pack;
			$login_dialog->Show;
			}

		}	### end campaign exists loop
	else
		{
		#$dbhA->close;

		$status_value->delete('0', 'end');
		$status_value->insert('0', "Login failed, bad campaign, try again");

		$login_dialog->add("Label", -text => "login failed campaign is not active: $Lcampaign")->pack;
		$login_dialog->Show;
		}

}





##########################################
##########################################
### pause and resume auto dialing
##########################################
##########################################
sub pause_auto_dialing {
$active_auto_dial = '0';
$WAITING_for_call = '0';

$status_value->delete('0', 'end');
$status_value->insert('0', "Auto-dialer paused. Please press RESUME to start receiving calls again");

### update the vicidial_live_agents every second with a new random number so it is shown to be alive
$stmtA = "UPDATE vicidial_live_agents set status='PAUSED' where user='$user' and server_ip='$server_ip';";
$dbhA->query($stmtA);

$auto_dialing_button_pause->configure(-state => 'disabled');
$auto_dialing_button_resume->configure(-state => 'normal');

print STDERR "Auto-dialing paused:   |$auto_dial_level|$active_auto_dial|\n";
}

sub resume_auto_dialing {
$active_auto_dial = '1';
$WAITING_for_call = '1';

$status_value->delete('0', 'end');
$status_value->insert('0', "Auto-dialer resumed. Waiting for next call");

### update the vicidial_live_agents every second with a new random number so it is shown to be alive
$stmtA = "UPDATE vicidial_live_agents set status='READY' where user='$user' and server_ip='$server_ip';";
$dbhA->query($stmtA);

$auto_dialing_button_pause->configure(-state => 'normal');
$auto_dialing_button_resume->configure(-state => 'disabled');

print STDERR "Auto-dialing resumed:   |$auto_dial_level|$active_auto_dial|\n";
}





##########################################
##########################################
### logout of the system
##########################################
##########################################
sub logout_system {

	$auto_dial_level='0';
		if ($active_auto_dial) {&pause_auto_dialing;}
    my $Luser = $user_value->get;
    my $Lcampaign = $campaign_value->get;
    my $OLD_session_id = $system_ext_value->get;

		$event_string = "SUBRT|logout_system|LOGGING OUT as |$Luser| on campaign |$Lcampaign| with session_id |$OLD_session_id|";
	 event_logger;

    my $HANGUP = $zap_channel_value->get;
if (length($HANGUP)>2)
	{
	$logout_hangup_flag=1;
	 hangup_customer;
	}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";
		$stmtA = "INSERT INTO vicidial_user_log values('','$Luser','LOGOUT','$Lcampaign','$SQLdate','$epochdate')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

	$stmtA = "UPDATE vicidial_conferences set extension='' where server_ip='$server_ip' and conf_exten='$OLD_session_id'";
	$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";


	@sip_chan_hangup=@MT;

		$stmtA = "SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and channel LIKE \"$SIP_user$DASH\%\" limit 9";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|logout_system|HX|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			 $recH_count=0;
			   while ( $record = $iter->each)
			   {
				$sip_chan_hangup[$recH_count] = "$record->[0]";
			   $recH_count++;
			   } 
			}

	$recH_count=0;
	foreach(@sip_chan_hangup)
		{

				$HSqueryCID = "H$recH_count$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$SIqueryCID','Channel: $sip_chan_hangup[$recH_count]','','','','','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$HX_manager_command_sent = 1;

				$event_string = "SUBRT|logout_system|HX|$HSqueryCID|$stmtA|";
			 event_logger;

			$recH_count++;
		}



	$dbhA->close;

		$status_value->delete('0', 'end');
		$status_value->insert('0', "You are now logged out");

	$system_ext_value->delete('0', 'end');

	my $login_dialog = $MW->DialogBox( -title   => "System Logout Status:",
                                 -buttons => [ "OK" ],
				);

    $login_dialog->add("Label", -text => "you have logged out of the system")->pack;
    $login_dialog->Show;

	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner

	$logout_button_frame->place(-in=>$login_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner pixel
	$login_button_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

}






##########################################
##########################################
### get the list of dispositions from the system
##########################################
##########################################
sub get_dispo_list {

#	$dispo_listbox->delete('0', 'end');


   $dbhA->query("SELECT status,status_name FROM vicidial_statuses WHERE selectable='Y' and status != 'NEW' order by status limit 50;");
   if ($dbhA->has_selected_record)
	{
   $iterA=$dbhA->create_record_iterator;
	 $rec_countY=0;
	   while ($recordA = $iterA->each)
		{
		   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}

			$DBstatus[$rec_countY] = "$recordA->[0] -- $recordA->[1]";

			$rec_countY++;
		} 
	}


		$event_string = "SUBRT|get_dispo_list|Getting DISPO LIST|$rec_countY dispositions|";
	 event_logger;

}




##########################################
##########################################
### get the count of available leads to call in the active campaign
##########################################
##########################################
sub get_number_of_leads_to_call_in_campaign {

		$event_string = "SUBRT|get_number_of_leads_to_call_in_campaign|START|";
	 event_logger;

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";


   $dbhA->query("SELECT dial_status_a,dial_status_b,dial_status_c,dial_status_d,dial_status_e,park_ext,park_file_name,web_form_address,allow_closers FROM vicidial_campaigns where campaign_id = '$campaign';");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	   while ( $record = $iter->each)
	   {
	   $status_A = "$record->[0]";
	   $status_B = "$record->[1]";
	   $status_C = "$record->[2]";
	   $status_D = "$record->[3]";
	   $status_E = "$record->[4]";
	   $park_ext = "$record->[5]";
	   $park_file_name = "$record->[6]";
	   $web_form_address = "$record->[7]";
	   $allow_closers = "$record->[8]";
	   } 
   }

	# If a park extension is not set, use the default one
	if ( (length($park_ext)>0) && (length($park_file_name)>0) )
		{
		$VICIDIAL_park_on_extension = "$park_ext";
		$VICIDIAL_park_on_filename = "$park_file_name";
		print STDERR "CAMPAIGN CUSTOM PARKING:  |$VICIDIAL_park_on_extension|$VICIDIAL_park_on_filename|\n";
		}
		print STDERR "CAMPAIGN DEFAULT PARKING: |$VICIDIAL_park_on_extension|$VICIDIAL_park_on_filename|\n";

	# If a web form address is not set, use the default one
	if (length($web_form_address)>0)
		{
		$VICIDIAL_web_form_address = "$web_form_address";
		print STDERR "CAMPAIGN CUSTOM WEB FORM:   |$VICIDIAL_web_form_address|\n";
		}
	else
		{
		$VICIDIAL_web_form_address = "$VICIDIAL_web_URL";
		print STDERR "CAMPAIGN DEFAULT WEB FORM:  |$VICIDIAL_web_form_address|\n";
		}

	# If closers are allowed on this campaign
	if ($allow_closers =~ /Y/i)
		{
		$VICIDIAL_allow_closers = 1;
		print STDERR "CAMPAIGN ALLOWS CLOSERS:    |$VICIDIAL_allow_closers|\n";
		}
	else
		{
		$VICIDIAL_allow_closers = 0;
		print STDERR "CAMPAIGN ALLOWS NO CLOSERS: |$VICIDIAL_allow_closers|\n";
		}


	$stmtA = "SELECT count(*) FROM vicidial_hopper where campaign_id = '$campaign' and status='READY';";
   $dbhA->query("$stmtA");
 	   print STDERR "|$stmtA|\n";

  if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_count=0;
	   while ( $record = $iter->each)
	   {
	   print STDERR $record->[0]," - leads left to call in hopper\n";

	   $campaign_leads_to_call = "$record->[0]";
	   } 
   }

	#$dbhA->close;

		$event_string = "SUBRT|get_number_of_leads_to_call_in_campaign|END|$campaign_leads_to_call leads to call|";
	 event_logger;


}





##########################################
##########################################
### grabs the next number to call from the database and reserves it
### then it selects the details and posts them to the Entry fields
### and initiates the Originate call
##########################################
##########################################
sub call_next_number {

	$XCF=0;

		$event_string = "SUBRT|call_next_number|START|";
	 event_logger;

	$start_dialing_button->configure(-state => 'disabled');

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";


	$stmtA = "UPDATE vicidial_hopper set status='QUEUE', user='$user' where campaign_id='$campaign' and status='READY' order by hopper_id LIMIT 1";
	print STDERR "|$stmtA|\n";
   $dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;
	print STDERR "hopper rows updated to QUEUE: |$affected_rows|\n";

if ($affected_rows)
	{
	$lead_id='';

	$stmtA = "SELECT lead_id FROM vicidial_hopper where campaign_id='$campaign' and status='QUEUE' and user='$user' LIMIT 1";
	print STDERR "|$stmtA|\n";
   $dbhA->query("$stmtA");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_countCUSTDATA=0;
	   while ( $record = $iter->each)
	   {
		   $lead_id			= "$record->[0]";
	   }
   }

	$stmtA = "SELECT * FROM vicidial_list where lead_id='$lead_id';";
	print STDERR "|$stmtA|\n";
   $dbhA->query("$stmtA");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_countCUSTDATA=0;
	   while ( $record = $iter->each)
	   {
		   $lead_id			= "$record->[0]";
		   $vendor_id		= "$record->[5]";
		   $list_id			= "$record->[7]";
		   $phone_code		= "$record->[10]";
		   $phone_number	= "$record->[11]";
		   $title			= "$record->[12]";
		   $first_name		= "$record->[13]";
		   $middle_initial	= "$record->[14]";
		   $last_name		= "$record->[15]";
		   $address1		= "$record->[16]";
		   $address2		= "$record->[17]";
		   $address3		= "$record->[18]";
		   $city			= "$record->[19]";
		   $state			= "$record->[20]";
		   $province		= "$record->[21]";
		   $postal_code		= "$record->[22]";
		   $country_code	= "$record->[23]";
		   $gender			= "$record->[24]";
		   $date_of_birth	= "$record->[25]";
		   $alt_phone		= "$record->[26]";
		   $email			= "$record->[27]";
		   $security		= "$record->[28]";
		   $comments		= "$record->[29]";
		   $called_count	= "$record->[30]";

		$rec_countCUSTDATA++;
	   } 
   }

	if ($rec_countCUSTDATA)
	{
		$dial_code_value->delete('0', 'end');
		$dial_code_value->insert('0', $phone_code);
		$title_name_value->delete('0', 'end');
		$title_name_value->insert('0', $title);
		$first_name_value->delete('0', 'end');
		$first_name_value->insert('0', $first_name);
		$middle_name_value->delete('0', 'end');
		$middle_name_value->insert('0', $middle_name);
		$last_name_value->delete('0', 'end');
		$last_name_value->insert('0', $last_name);
		$address_a_value->delete('0', 'end');
		$address_a_value->insert('0', $address1);
		$address_b_value->delete('0', 'end');
		$address_b_value->insert('0', $address2);
		$address_c_value->delete('0', 'end');
		$address_c_value->insert('0', $address3);
		$city_value->delete('0', 'end');
		$city_value->insert('0', $city);
		$state_value->delete('0', 'end');
		$state_value->insert('0', $state);
		$province_value->delete('0', 'end');
		$province_value->insert('0', $province);
		$post_value->delete('0', 'end');
		$post_value->insert('0', $postal_code);
		$phone_value->delete('0', 'end');
		$phone_value->insert('0', $phone_number);
		$vendor_id_value->delete('0', 'end');
		$vendor_id_value->insert('0', $vendor_id);
		$alt_phone_value->delete('0', 'end');
		$alt_phone_value->insert('0', $alt_phone);
		$security_value->delete('0', 'end');
		$security_value->insert('0', $security);
		$email_value->delete('0', 'end');
		$email_value->insert('0', $email);
		$comments_value->delete('0', 'end');
		$comments_value->insert('0', $comments);

		### update called_count
		$called_count++;

		$stmtA = "UPDATE vicidial_list set status='INCALL', called_since_last_reset='Y', called_count='$called_count',user='$user' where lead_id='$lead_id'";
		print STDERR "|$stmtA|\n";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		print STDERR "rows updated to INCALL: |$affected_rows|\n";

		$stmtA = "DELETE FROM vicidial_hopper where lead_id='$lead_id'";
		print STDERR "|$stmtA|\n";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		print STDERR "rows deleted from hopper: |$affected_rows|\n";

	}

	#$dbhA->close;


	$silent_prefix = '7';


	### use manager middleware-app to connect the next call to the meetme room
		$CNqueryCID = "CN$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$CNqueryCID','Exten: 9$phone_code$phone_number','Context: $ext_context','Channel: $local_DEF$silent_prefix$session_id$local_AMP$ext_context','Priority: 1','Callerid: $CNqueryCID','','','','','')";
#		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$CNqueryCID','Exten: 7$session_id','Context: $ext_context','Channel: $call_out_number_group$phone_code$phone_number','Priority: 1','Callerid: $CNqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|call_next_number|CN|$CNqueryCID|$stmtA|";
		 event_logger;

	$status_value->delete('0', 'end');
	$status_value->insert('0', "Calling $phone_code$phone_number     Waiting for connect: 0");

		

	$get_channel_of_new_call_loop=0;
	$customer_zap_channel='';
	while ( ($get_channel_of_new_call_loop < 50) && (length($customer_zap_channel)<4) )
		{
		### sleep for 9 tenths of a second
		usleep(1*900*1000);
		print STDERR "Called $phone_code$phone_number     waiting for ring: $get_channel_of_new_call_loop seconds\r";
		$get_channel_of_new_call_loop++;
		$status_value->delete('0', 'end');
		$status_value->insert('0', "Called $phone_code$phone_number     Time until ring was: $get_channel_of_new_call_loop seconds");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$CNqueryCID' and status='UPDATED' and channel LIKE \"Zap%\"";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|call_next_number|CN|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$customer_zap_channel = "$record->[0]";
				$uniqueid = "$record->[1]";
			   } 
			}
		}

	if ($get_channel_of_new_call_loop > 49)
		{
		$status_value->delete('0', 'end');
		$status_value->insert('0', "ERROR ----- Please contact your phone system administrator and hangup this call.");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$CNqueryCID' and status='SENT'";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|call_next_number|CN|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$customer_zap_channel = "$record->[0]";
				$uniqueid = "$record->[1]";
			   } 
			}

		}

#	$customer_zap_channel =~ s/Channel: |^ *| *$//gi;
#	$customer_zap_channel =~ s/^ *| *$//gi;

	$SIPexten = $SIP_user;
	$SIPexten =~ s/sip\///gi;

	$zap_channel_value->delete('0', 'end');
	$zap_channel_value->insert('0', $customer_zap_channel);

	if ($phone_code eq '') {$channel_group='Outbound Local';   $number_dialed=$phone_number;}
	if ($phone_code eq '1') {$channel_group='Outbound Long Distance';   $number_dialed=$phone_number;}
	if ($phone_code eq '01161') {$channel_group='Outbound AUS';   $number_dialed="$phone_code$phone_number";}
	if ($phone_code eq '01144') {$channel_group='Outbound UK';   $number_dialed="$phone_code$phone_number";}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";
	if (length($customer_zap_channel)>5)
		{
		$stmtA = "INSERT INTO vicidial_log (uniqueid,lead_id,list_id,campaign_id,call_date,start_epoch,status,phone_code,phone_number,user,processed) values('$uniqueid','$lead_id','$list_id','$campaign','$SQLdate','$secX','INCALL','$phone_code','$phone_number','$user','N')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: |$stmtA|\n";

		$stmtA = "INSERT INTO call_log (uniqueid,channel,channel_group,type,server_ip,extension,number_dialed,caller_code,start_time,start_epoch) values('$uniqueid','$customer_zap_channel','$channel_group','Zap','$server_ip','$SIPexten','$number_dialed','VD $user $lead_id','$SQLdate','$secX')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: |$stmtA|\n";

		}

	#$dbhA->close;

	$INCALL=1;

#	$start_recording_button->configure(-state => 'normal');
#	$stop_recording_button->configure(-state => 'disabled');

	$hangup_customer_button->configure(-state => 'normal');
	$transfer_call_button->configure(-state => 'normal');
	$park_call_button->configure(-state => 'normal');
	$address_web_button->configure(-state => 'normal');

	}

else
	{
	#$dbhA->close;

	$status_value->delete('0', 'end');
	$status_value->insert('0', "Logging you out, no more leads to dial in this campaign");

	my $dialog = $MW->DialogBox( -title   => "Leads error",
								 -buttons => [ "OK" ],
				);

	$dialog->add("Label", -text => "Logging out: no more leads to dial in this campaign: $Lcampaign")->pack;
	$dialog->Show;

	&logout_system;

	}

		$event_string = "SUBRT|call_next_number|END|Dial string |$call_out_number_group$phone_code$phone_number|";
	 event_logger;

}





##########################################
##########################################
### grabs the lead info from the database and then it selects the details
### and posts them to the Entry fields all channel and uniqueid values
### should be populated coming to this subroutine
##########################################
##########################################
sub auto_next_lead_info {

	$XCF=0;

		$event_string = "SUBRT|auto_next_lead_info|START|";
	 event_logger;

#	$start_dialing_button->configure(-state => 'disabled');

	$stmtA = "SELECT * FROM vicidial_list where lead_id='$lead_id';";
	print STDERR "|$stmtA|\n";
   $dbhA->query("$stmtA");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_countCUSTDATA=0;
	   while ( $record = $iter->each)
	   {
		   $lead_id			= "$record->[0]";
		   $vendor_id		= "$record->[5]";
		   $list_id			= "$record->[7]";
		   $phone_code		= "$record->[10]";
		   $phone_number	= "$record->[11]";
		   $title			= "$record->[12]";
		   $first_name		= "$record->[13]";
		   $middle_initial	= "$record->[14]";
		   $last_name		= "$record->[15]";
		   $address1		= "$record->[16]";
		   $address2		= "$record->[17]";
		   $address3		= "$record->[18]";
		   $city			= "$record->[19]";
		   $state			= "$record->[20]";
		   $province		= "$record->[21]";
		   $postal_code		= "$record->[22]";
		   $country_code	= "$record->[23]";
		   $gender			= "$record->[24]";
		   $date_of_birth	= "$record->[25]";
		   $alt_phone		= "$record->[26]";
		   $email			= "$record->[27]";
		   $security		= "$record->[28]";
		   $comments		= "$record->[29]";
		   $called_count	= "$record->[30]";

		$rec_countCUSTDATA++;
	   } 
   }

	if ($rec_countCUSTDATA)
	{
		$dial_code_value->delete('0', 'end');
		$dial_code_value->insert('0', $phone_code);
		$title_name_value->delete('0', 'end');
		$title_name_value->insert('0', $title);
		$first_name_value->delete('0', 'end');
		$first_name_value->insert('0', $first_name);
		$middle_name_value->delete('0', 'end');
		$middle_name_value->insert('0', $middle_name);
		$last_name_value->delete('0', 'end');
		$last_name_value->insert('0', $last_name);
		$address_a_value->delete('0', 'end');
		$address_a_value->insert('0', $address1);
		$address_b_value->delete('0', 'end');
		$address_b_value->insert('0', $address2);
		$address_c_value->delete('0', 'end');
		$address_c_value->insert('0', $address3);
		$city_value->delete('0', 'end');
		$city_value->insert('0', $city);
		$state_value->delete('0', 'end');
		$state_value->insert('0', $state);
		$province_value->delete('0', 'end');
		$province_value->insert('0', $province);
		$post_value->delete('0', 'end');
		$post_value->insert('0', $postal_code);
		$phone_value->delete('0', 'end');
		$phone_value->insert('0', $phone_number);
		$vendor_id_value->delete('0', 'end');
		$vendor_id_value->insert('0', $vendor_id);
		$alt_phone_value->delete('0', 'end');
		$alt_phone_value->insert('0', $alt_phone);
		$security_value->delete('0', 'end');
		$security_value->insert('0', $security);
		$email_value->delete('0', 'end');
		$email_value->insert('0', $email);
		$comments_value->delete('0', 'end');
		$comments_value->insert('0', $comments);

		### update called_count
		$called_count++;

		$stmtA = "UPDATE vicidial_list set status='INCALL', user='$user' where lead_id='$lead_id'";
		print STDERR "|$stmtA|\n";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		print STDERR "rows updated to INCALL: |$affected_rows|\n";
	}


	#		$customer_zap_channel = "$record->[0]";
	#		$uniqueid = "$record->[1]";

	$SIPexten = $SIP_user;
	$SIPexten =~ s/sip\///gi;

	$zap_channel_value->delete('0', 'end');
	$zap_channel_value->insert('0', $customer_zap_channel);

	if (length($customer_zap_channel)>5)
		{
		$stmtA = "UPDATE vicidial_log set user='$user', comments='AUTO', list_id='$list_id', status='INCALL' where lead_id='$lead_id' and uniqueid='$uniqueid'";
		print STDERR "|$stmtA|\n";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		print STDERR "vicidial_log rows updated: |$affected_rows|\n";

		}


	$INCALL=1;

	$auto_dialing_button_pause->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'normal');
	$transfer_call_button->configure(-state => 'normal');
	$park_call_button->configure(-state => 'normal');
	$address_web_button->configure(-state => 'normal');

	

		$event_string = "SUBRT|auto_next_lead_info|END|Dial string |$customer_zap_channel|$uniqueid|$lead_id|$phone_code$phone_number|";
	 event_logger;

}





##########################################
##########################################
### hangup the customer Zap channel dialed, the 1st outbound line
##########################################
##########################################
sub hangup_customer {

    my $HANGUP = $zap_channel_value->get;

	$HANGUP_CID_zap = $HANGUP;
	$HANGUP_CID_zap =~ s/\D//gi;

		$event_string = "SUBRT|hangup_customer|$HANGUP|";
	 event_logger;

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

		$stmtA = "UPDATE vicidial_log set end_epoch='$secX', length_in_sec='$call_length_in_seconds',status='DONE' where uniqueid='$uniqueid'";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

	#$dbhA->close;

	### error box if channel to park is not live
if (length($HANGUP)<5)
	{
	
		$customer_hungup_button->configure(-state => 'normal');

		my $dialog = $MW->DialogBox( -title   => "Channel Hangup Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to Hangup is not live\n   |$HANGUP|")->pack;
		$dialog->Show;  
	}
else
	{
		$HUqueryCID = $CNqueryCID;
		$HUqueryCID =~ s/^../HU/gi;
		if (!$HUqueryCID) {$HUqueryCID = "HV$HANGUP_CID_zap$CIDdate";}

		### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$HUqueryCID','Channel: $HANGUP','','','','','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$event_string = "SUBRT|hangup_customer|HC|$CNqueryCID|$stmtA|";
		 event_logger;


	$zap_channel_value->delete('0', 'end');

	$INCALL=0;

#	$start_recording_button->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'disabled');
	$transfer_call_button->configure(-state => 'disabled');
	$park_call_button->configure(-state => 'disabled');

	if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
		{
		$stmtA = "UPDATE vicidial_live_agents set status='PAUSED',lead_id='',uniqueid='',callerid='',channel='',last_call_finish='$SQLdate' where user='$user' and server_ip='$server_ip'";
		print STDERR "|$stmtA|\n";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		print STDERR "vicidial_live_agents rows updated: |$affected_rows|\n";
		}

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dial_closer_frame->place(-in=>$main_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
		&call_dispo_window;

	if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
		{
		### delete call record from  vicidial_auto_calls
		$stmtA = "DELETE from vicidial_auto_calls where uniqueid='$uniqueid';";
		$dbhA->query($stmtA);	
		
		$WAITING_for_call=1;
		}
	}

}






##########################################
##########################################
### customer hungup the Zap channel before user did
##########################################
##########################################
sub customer_hungup {


	$zap_channel_value->delete('0', 'end');

	$customer_hungup_button->configure(-state => 'disabled');
#	$start_recording_button->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'disabled');
	$transfer_call_button->configure(-state => 'disabled');
	$park_call_button->configure(-state => 'disabled');

	if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
		{
		$stmtA = "UPDATE vicidial_live_agents set status='PAUSED',lead_id='',uniqueid='',callerid='',channel='',last_call_finish='$SQLdate' where user='$user' and server_ip='$server_ip'";
		print STDERR "|$stmtA|\n";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		print STDERR "vicidial_live_agents rows updated: |$affected_rows|\n";
		}

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dial_closer_frame->place(-in=>$main_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
		&call_dispo_window;

	if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
		{
		### delete call record from  vicidial_auto_calls
		$stmtA = "DELETE from vicidial_auto_calls where uniqueid='$uniqueid';";
		$dbhA->query($stmtA);	
		
		$WAITING_for_call=1;
		}
}






##########################################
##########################################
### commits the information that is in the fields to the database
##########################################
##########################################
sub commit_customer_info_to_db {

    my $disposition		 = $dispo_value->get;
    my $title			 = $title_name_value->get;
    my $first_name		 = $first_name_value->get;
    my $middle_initial	 = $middle_name_value->get;
    my $last_name		 = $last_name_value->get;
    my $address1		 = $address_a_value->get;
    my $address2		 = $address_b_value->get;
    my $address3		 = $address_c_value->get;
    my $city			 = $city_value->get;
    my $state			 = $state_value->get;
    my $province		 = $province_value->get;
    my $postal_code		 = $post_value->get;
    my $phone			 = $phone_value->get;
    my $alt_phone		 = $alt_phone_value->get;
    my $security		 = $security_value->get;
    my $email			 = $email_value->get;
    my $comments		 = $comments_value->get;

		$event_string = "SUBRT|commit_customer_info_to_db|$disposition|$title|$first_name|$middle_initial|$last_name|$address1|$address2|$address3|$city|$state|$province|$postal_code|$alt_phone|$comments|";
	 event_logger;

if ($phone_number eq "$alt_phone") {$alt_phone = '';}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

#	$stmtA = "UPDATE vicidial_list set status='$disposition', title='$title', first_name='$first_name', middle_initial='$middle_initial', last_name='$last_name', address1='$address1', address2='$address2', address3='$address3', city='$city', state='$state', province='$province', postal_code='$postal_code', alt_phone='$alt_phone', security_phrase='$security', email='$email', comments='$comments' where lead_id='$lead_id'";
	$stmtA = "UPDATE vicidial_list set status='$disposition', title='$title', first_name='$first_name', middle_initial='$middle_initial', last_name='$last_name', address1='$address1', address2='$address2', address3='$address3', city='$city', state='$state', province='$province', postal_code='$postal_code', alt_phone='$alt_phone', email='$email', comments='$comments' where lead_id='$lead_id'";

	print STDERR "|$stmtA|\n";

   $dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;

	print STDERR "rows updated with modified data: |$affected_rows|\n";


	$stmtA = "UPDATE vicidial_log set status='$disposition' where uniqueid='$uniqueid'";
		if($DB){print STDERR "\n|$stmtA|\n";}
	$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";


	#$dbhA->close;




	$dispo_value->delete('0', 'end');
	$dial_code_value->delete('0', 'end');
	$title_name_value->delete('0', 'end');
	$first_name_value->delete('0', 'end');
	$middle_name_value->delete('0', 'end');
	$last_name_value->delete('0', 'end');
	$address_a_value->delete('0', 'end');
	$address_b_value->delete('0', 'end');
	$address_c_value->delete('0', 'end');
	$city_value->delete('0', 'end');
	$state_value->delete('0', 'end');
	$province_value->delete('0', 'end');
	$post_value->delete('0', 'end');
	$phone_value->delete('0', 'end');
	$vendor_id_value->delete('0', 'end');
	$alt_phone_value->delete('0', 'end');
	$security_value->delete('0', 'end');
	$email_value->delete('0', 'end');
	$comments_value->delete('0', 'end');

	$call_length_in_seconds=0;
	$call_length_value->delete('0', 'end');


	$customer_hungup_button->configure(-state => 'disabled');
	$address_web_button->configure(-state => 'disabled');

if ($keep_auto_dial_value)
	{
	$start_dialing_button->configure(-state => 'disabled');
	$event_string = "SUBRT|auto_dial_next_number||";
	 event_logger;

	&start_dialing;
	$keep_auto_dial_value=0;
	}

}





##########################################
##########################################
### dials the transfer-conference number
##########################################
##########################################
sub conf_dial_number {

	my $conf_number_to_dial = $xfer_number_value->get;

	$xfer_length_in_seconds=0;

		$event_string = "SUBRT|conf_dial_number|$conf_number_to_dial|";
	 &event_logger;

	### error box if improperly formatted number is entered
	if ( (length($conf_number_to_dial) ne 3) && (length($conf_number_to_dial) ne 4) && (length($conf_number_to_dial) ne 9) && (length($conf_number_to_dial) ne 10) && (length($conf_number_to_dial) ne 11) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Number Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "Outside number to dial must be:\n- 3 or 4 digits for local speed-dial\n- 9 digits for Australia\n- 10 digits for US long distance \n or 11 digits for a UK number\n   |$conf_number_to_dial|")->pack;
		$dialog->Show;  
	}

	else
	{
		if ( (length($conf_number_to_dial) eq 3) or (length($conf_number_to_dial) eq 4) ) {$CNTD_prefix = '';}
		if (length($conf_number_to_dial) eq 9) {$CNTD_prefix = '01161';}
		if (length($conf_number_to_dial) eq 10) {$CNTD_prefix = '1';}
		if ( (length($conf_number_to_dial) eq 10) && ($conf_number_to_dial =~ /^727|^813/i) ) {$CNTD_prefix = '1';}
		if (length($conf_number_to_dial) eq 11) {$conf_number_to_dial =~ s/^.//gi;   $CNTD_prefix = '01144';}
		

	### use manager middleware-app to connect the next call to the meetme room
		$XDqueryCID = "XD$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$XDqueryCID','Exten: $session_id','Context: $ext_context','Channel: $call_out_number_group$CNTD_prefix$conf_number_to_dial','Priority: 1','Callerid: $XDqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|conf_dial_number|XD|$XDqueryCID|$stmtA|";
		 &event_logger;

	$get_channel_of_new_xcall_loop=0;
	$xferconf_zap_channel='';
	while ( ($get_channel_of_new_xcall_loop < 50) && (length($xferconf_zap_channel)<4) )
		{
		### sleep for 9 tenths of a second
		usleep(1*900*1000);
		print STDERR "Called $CNTD_prefix$conf_number_to_dial     waiting for ring: $get_channel_of_new_xcall_loop seconds\r";
		$get_channel_of_new_xcall_loop++;
		$status_value->delete('0', 'end');
		$status_value->insert('0', "Called $CNTD_prefix$conf_number_to_dial     Time until ring was: $get_channel_of_new_xcall_loop seconds");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$XDqueryCID' and status='UPDATED'";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|conf_dial_number|XD|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$xferconf_zap_channel = "$record->[0]";
				$xfer_uniqueid = "$record->[1]";
			   } 
			}
		}

	if ($get_channel_of_new_xcall_loop > 49)
		{
		$status_value->delete('0', 'end');
		$status_value->insert('0', "ERROR ----- Please contact your phone system administrator and hangup this call.");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$XDqueryCID' and status='SENT'";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|conf_dial_number|XD|$stmtA|FAIL|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$xferconf_zap_channel = "$record->[0]";
				$xfer_uniqueid = "$record->[1]";
			   } 
			}

		}


	$SIPexten = $SIP_user;
	$SIPexten =~ s/sip\///gi;

	$xfer_channel_value->delete('0', 'end');
	$xfer_channel_value->insert('0', $xferconf_zap_channel);

	if ($CNTD_prefix eq '') {$channel_group='Outbound Local';   $number_dialed=$conf_number_to_dial;}
	if ($CNTD_prefix eq '1') {$channel_group='Outbound Long Distance';   $number_dialed=$conf_number_to_dial;}
	if ($CNTD_prefix eq '01161') {$channel_group='Outbound AUS';   $number_dialed="$CNTD_prefix$conf_number_to_dial";}
	if ($CNTD_prefix eq '01144') {$channel_group='Outbound UK';   $number_dialed="$CNTD_prefix$conf_number_to_dial";}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	if (length($xferconf_zap_channel)>5)
		{
		$stmtA = "INSERT INTO call_log (uniqueid,channel,channel_group,type,server_ip,extension,number_dialed,caller_code,start_time,start_epoch) values('$xfer_uniqueid','$xferconf_zap_channel','$channel_group','Zap','$server_ip','$SIPexten','$number_dialed','VD $user XFER','$SQLdate','$secX')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
		}
	#$dbhA->close;


	$hangup_customer_button->configure(-state => 'disabled');
	$transfer_call_button->configure(-state => 'disabled');
	$hangup_xfer_line_button->configure(-state => 'normal');

	}

}





##########################################
##########################################
### parks the customer
##########################################
##########################################
sub conf_park_customer {

my $PARK = $zap_channel_value->get;

		$event_string = "SUBRT|conf_park_customer|$PARK|";
	 event_logger;

	### error box if channel to park is not live
if (length($PARK)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Channel Park Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to park is not live\n   |$PARK|")->pack;
		$dialog->Show;  
	}
else
	{

	### use manager middleware-app to connect the next call to the meetme room
		$RDqueryCID = "RD$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$RDqueryCID','Channel: $PARK','Context: $ext_context','Exten: $VICIDIAL_park_on_extension','Priority: 1','Callerid: $RDqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

		$park_extension = "$VICIDIAL_park_on_filename";
		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|conf_park_customer|RD|$RDqueryCID|$stmtA|";
		 &event_logger;



		### insert parked call into parked_channels table
#		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#		or 	die "Couldn't connect to database: \n";

		$stmtA = "INSERT INTO parked_channels values('$PARK','$server_ip','','$park_extension','$SIP_user','$SQLdate');";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

		#$dbhA->close;

		$grab_park_cust_button->configure(-state => 'normal');
		$grab_park_button->configure(-state => 'normal');

	}

}





##########################################
##########################################
### transfer the customer to closer queue
##########################################
##########################################
sub closer_transfer {

my $PARK = $zap_channel_value->get;
my $park_exten_suffix = $closer_send_code_value->get;
$PARK_CONFIRM = $zap_channel_value->get;
$park_exten_suffix = "_$park_exten_suffix";
		if ($DB) {print STDERR "\n|TRANSFER TO CLOSER - XXXXXXXXXXXXXXXXXXXXXXXXXXXX|\n";}

		$event_string = "SUBRT|closer_transfer|$PARK|";
	 event_logger;

	### error box if channel to park is not live
if (length($PARK)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Channel Closer Transfer Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to transfer is not live\n   |$PARK|")->pack;
		$dialog->Show;  
	}
else
	{

	### use manager middleware-app to connect the next call to the meetme room
		$TCqueryCID = "TC$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$TCqueryCID','Channel: $PARK','Context: $ext_context','Exten: $VICIDIAL_park_on_extension','Priority: 1','Callerid: $TCqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
		if ($DB) {print STDERR "\n|$stmtA|\n";}

		$park_extension = "$VICIDIAL_park_on_filename";
		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|closer_transfer|TC|$TCqueryCID|$stmtA|";
		 &event_logger;

	### popup that asks if the closer transfer went through
		&call_transfer_confirm_window;

		while ( (!$call_transfer_move_on) or ($XCF) )
			{
			&call_transfer_confirm_window;
			}

	### insert parked call into parked_channels table
		$stmtA = "INSERT INTO parked_channels values('$PARK','$server_ip','CL_$campaign$park_exten_suffix','$park_extension','$lead_id','$SQLdate');";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

		$stmtA = "INSERT INTO park_log (uniqueid,status,channel,server_ip,parked_time,channel_group) values('$uniqueid','PARKED','$PARK','$server_ip','$SQLdate','CL_$campaign$park_exten_suffix')";
		if ($DB) {print STDERR "\n|$stmtA|\n";}

		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

		#$dbhA->close;

	$zap_channel_value->delete('0', 'end');

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dial_closer_frame->place(-in=>$main_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
		&call_dispo_window;

	if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
		{
		### delete call record from  vicidial_auto_calls
		$stmtA = "DELETE from vicidial_auto_calls where uniqueid='$uniqueid';";
		$dbhA->query($stmtA);	
		
		$WAITING_for_call=1;
		}

	}

}





##########################################
##########################################
### open call transfer confirmation popup 
##########################################
##########################################
sub call_transfer_confirm_window
{

	$XCF++;
	$call_transfer_move_on=0;

	my $dialog_call_xferconfirm = $MW->DialogBox( -title   => "Call Transfer Confirm", -background => '#FFFFCC',
					 -buttons => [ "Yes","No" ],
	);

	my $call_xferconfirm_main_frame = $dialog_call_xferconfirm->Frame( -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $call_xferconfirm_header_row_frame = $call_xferconfirm_main_frame->Frame( -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $call_xferconfirm_buttons_frame = $call_xferconfirm_main_frame->Frame( -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top');
	$call_xferconfirm_header_row_frame->Label(-text => "DID THE TRANSFER GO THROUGH? ", -background => '#FFFFCC')->pack(-side => 'left');


		### sendcallerID entry field
		my $xferconfirm_pop_entry_frame = $call_xferconfirm_buttons_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$xferconfirm_pop_entry_frame->Label(-text => "CIDmanual:", -background => '#FFFFCC')->pack(-side => 'left');
		my $xferconfirm_value = $xferconfirm_pop_entry_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$xferconfirm_value->insert('0', "T$XCF$CIDdate$session_id");


	my $call_xferconfirm_result = $dialog_call_xferconfirm->Show;
	if ($call_xferconfirm_result =~ /Yes/i)
		{
		$call_transfer_move_on++;
		$XCF='0';
		$xferconfirm_value->delete('0', 'end');
		print STDERR "call_xferconfirm window closed\n";
		}

	if ($call_xferconfirm_result =~ /No/i)
		{
		$xferconfirm_value_get = $xferconfirm_value->get;

		if (length($xferconfirm_value_get) < 10)
			{
			$xferconfirm_value_get = "T$XCF$CIDdate$user";
			}
		
		### use manager middleware-app to connect the next call to the closer park
			$TCqueryCID = $xferconfirm_value_get;

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$TCqueryCID','Channel: $PARK_CONFIRM','Context: $ext_context','Exten: $VICIDIAL_park_on_extension','Priority: 1','Callerid: $TCqueryCID','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
			if ($DB) {print STDERR "\n|$stmtA|\n";}

			$park_extension = "$VICIDIAL_park_on_filename";
			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|call_xferconfirm|T$XCF|$TCqueryCID|$stmtA|";
			 &event_logger;

		}

}





##########################################
##########################################
### transfer the customer and 3rd party to separate conference and go on to next call
##########################################
##########################################
sub leave_Xway_call {

my $XFER_CUST = $zap_channel_value->get;
my $XFER_THIRD = $xfer_channel_value->get;

		if ($DB) {print STDERR "\n|TRANSFER BOTH TO NEW CONF - YYYYYYYYYYYYYYYYYYYYYYY|\n";}

		$event_string = "SUBRT|leave_Xway_call|$XFER_CUST|$XFER_THIRD|";
	 event_logger;

### error box if channel to park is not live
if (length($XFER_CUST)<5)
	{
		my $dialog = $MW->DialogBox( -title   => "Leave 3-way call Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The customer channel you are trying to leave is not live\n   |$XFER_CUST|")->pack;
		$dialog->Show;  
	}
else
	{
	### error box if channel to hangup is not live
	if (length($XFER_THIRD)<5)
		{
		
			my $dialog = $MW->DialogBox( -title   => "Leave 3-way call Error",
										 -buttons => [ "OK" ],
						);
			$dialog->add("Label", -text => "The 3rd party channel you are trying to leave is not live\n   |$XFER_THIRD|")->pack;
			$dialog->Show;  
		}
	else
		{

		$stmtA = "SELECT conf_exten FROM conferences where server_ip='$server_ip' and extension='' limit 1";
		$dbhA->query($stmtA);
		if ($dbhA->has_selected_record)
		{
		$iter=$dbhA->create_record_iterator;
		 $NCrec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - conference room\n";
		   $Xway_conf = "$record->[0]";
		   $NCrec_count++;
		   } 
		}

		if ($NCrec_count)
			{
			$stmtA = "UPDATE conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$Xway_conf'";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
			

			### use manager middleware-app to connect the next call to the meetme room
				$LXqueryCID = "LX$CIDdate$session_id";

			### insert a NEW record to the vicidial_manager table to be processed
				$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$LXqueryCID','Channel: $XFER_CUST','ExtraChannel: $XFER_THIRD','Context: $ext_context','Exten: $Xway_conf','Priority: 1','Callerid: $LXqueryCID','','','','')";
				$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
				if ($DB) {print STDERR "\n|$stmtA|\n";}

					$event_string = "SUBRT|leave_Xway_call|LX|$LXqueryCID|$stmtA|";
				 &event_logger;

			### popup that asks if the closer transfer went through
	#			&call_transfer_confirm_window;
	#
	#			while ( (!$call_transfer_move_on) or ($XCF) )
	#				{
	#				&call_transfer_confirm_window;
	#				}

			$zap_channel_value->delete('0', 'end');
			$xfer_channel_value->delete('0', 'end');

			$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
			$dial_closer_frame->place(-in=>$main_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame
			$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
				&call_dispo_window;

			if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
				{
				### delete call record from  vicidial_auto_calls
				$stmtA = "DELETE from vicidial_auto_calls where uniqueid='$uniqueid';";
				$dbhA->query($stmtA);	
				
				$WAITING_for_call=1;
				}

			}
		else
			{
			my $dialog = $MW->DialogBox( -title   => "Leave 3-way call Error",
										 -buttons => [ "OK" ],
						);
			$dialog->add("Label", -text => "There are no available conferences to transfer the lines to\n   |$XFER_THIRD|")->pack;
			$dialog->Show;  
			}


		}

	}

}





##########################################
##########################################
### blind transfers the customer to another number
##########################################
##########################################
sub conf_blind_xfer_customer {

my $XFER = $zap_channel_value->get;
my $conf_number_to_dial = $xfer_number_value->get;

		$event_string = "SUBRT|conf_blind_xfer_customer|$XFER|$conf_number_to_dial|";
	 event_logger;

### error box if improperly formatted number is entered
if ( (length($conf_number_to_dial) ne 3) && (length($conf_number_to_dial) ne 4) && (length($conf_number_to_dial) ne 9) && (length($conf_number_to_dial) ne 10) && (length($conf_number_to_dial) ne 11) )
{

	my $dialog = $MW->DialogBox( -title   => "Number Error",
								 -buttons => [ "OK" ],
				);
	$dialog->add("Label", -text => "Outside number to dial must be:\n- 3 or 4 digits for local speed-dial\n- 9 digits for Australia\n- 10 digits for US long distance \n or 11 digits for a UK number\n   |$conf_number_to_dial|")->pack;
	$dialog->Show;  
}

else
{
	if ( (length($conf_number_to_dial) eq 3) or (length($conf_number_to_dial) eq 4) ) {$CNTD_prefix = '';}
	if (length($conf_number_to_dial) eq 9) {$CNTD_prefix = '901161';}
	if (length($conf_number_to_dial) eq 10) {$CNTD_prefix = '91';}
	if ( (length($conf_number_to_dial) eq 10) && ($conf_number_to_dial =~ /^727|^813/i) ) {$CNTD_prefix = '91';}
	if (length($conf_number_to_dial) eq 11) {$CNTD_prefix = '';}

		### error box if channel to transfer is not live
	if (length($XFER)<5)
		{
		
			my $dialog = $MW->DialogBox( -title   => "Channel transfer Error",
										 -buttons => [ "OK" ],
						);
			$dialog->add("Label", -text => "The channel you are trying to transfer is not live\n   |$XFER|")->pack;
			$dialog->Show;  
		}
	else
		{


		### use manager middleware-app to connect the next call to the meetme room
			$BXqueryCID = "BX$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$BXqueryCID','Channel: $XFER','Context: $ext_context','Exten: $CNTD_prefix$conf_number_to_dial','Priority: 1','Callerid: $BXqueryCID','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|conf_blind_xfer_customer|BX|$BXqueryCID|$stmtA|";
			 &event_logger;




	$zap_channel_value->delete('0', 'end');

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dial_closer_frame->place(-in=>$main_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
		&call_dispo_window;

		}

	}

}





##########################################
##########################################
### grabs the customer that is parked
##########################################
##########################################
sub conf_grab_park_customer {

my $PICKUP = $zap_channel_value->get;

		$event_string = "SUBRT|conf_grab_park_customer|$PICKUP|";
	 event_logger;

	### error box if channel to park is not live
if (length($PICKUP)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Channel Pickup Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to park is not live\n   |$PICKUP|")->pack;
		$dialog->Show;  
	}
else
	{


		### use manager middleware-app to connect the next call to the meetme room
			$GPqueryCID = "GP$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$GPqueryCID','Channel: $PICKUP','Context: $ext_context','Exten: $session_id','Priority: 1','Callerid: $GPqueryCID','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|conf_grab_park_customer|GP|$GPqueryCID|$stmtA|";
			 &event_logger;

	

		### delete call from parked_channels table
#		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#		or 	die "Couldn't connect to database: \n";
		$stmtA = "DELETE FROM parked_channels where channel='$PICKUP' and server_ip = '$server_ip';";
		$dbhA->query($stmtA);
#		$dbhA->close;

	}

}







##########################################
##########################################
### hangs up the conference line
##########################################
##########################################
sub conf_hangup_xfer_line {

my $XFER_HANGUP = $xfer_channel_value->get;

		$event_string = "SUBRT|conf_hangup_xfer_line|$XFER_HANGUP|";
	 event_logger;

	### error box if channel to hangup is not live
if (length($XFER_HANGUP)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Xfer Channel Hangup Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to hangup is not live\n   |$XFER_HANGUP|")->pack;
		$dialog->Show;  
	}
else
	{

		### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$XDqueryCID','Channel: $XFER_HANGUP','','','','','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$event_string = "SUBRT|conf_hangup_xfer_line|XH|$XDqueryCID|$stmtA|";
		 event_logger;



	

	$xfer_channel_value->delete('0', 'end');


	}

}






##########################################
##########################################
### starts recording locally on the customer-connected line
##########################################
##########################################
sub start_recording
{

$CONFERENCE_RECORDING = 1;
$CONFERENCE_RECORDING_CHANNEL = '';


$SIP_user = $login_value->get;
$ext = $SIP_user;
$ext =~ s/SIP\///gi;
$filename = "$filedate$US$ext";

$start_recording_button->configure(-state => 'disabled');
$stop_recording_button->configure(-state => 'normal');

#if (!$RECORD) {$RECORD = '-';}
#if (length($RECORD)>4) {$channel = $RECORD;}
#else {$channel = $zap_channel_value->get;}
	$channel = $zap_channel_value->get;

	$channel =~ s/Zap\///gi;
	$record_channel = $channel;

		$event_string = "SUBRT|start_recording|START|$filename|$record_channel|";
	 event_logger;

	$local_DEF = 'Local/';
	$local_AMP = '@';
	$conf_silent_prefix = '7';

		### use manager middleware-app to connect the next call to the meetme room
			$RBqueryCID = "RB$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$RBqueryCID','Channel: $local_DEF$conf_silent_prefix$session_id$local_AMP$ext_context','Context: $ext_context','Exten: $recording_exten','Priority: 1','Callerid: $filename','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|start_recording|RB|$RBqueryCID|$stmtA|";
			 &event_logger;

	

	$status_value->delete('0', 'end');
    $status_value->insert('0', " - RECORDING - ");
	$rec_fname_value->delete('0', 'end');
    $rec_fname_value->insert('0', "$filename");
	$rec_recid_value->delete('0', 'end');


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

		$stmtA = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('Zap/$channel','$server_ip','$SIP_user','$SQLdate','$secX','$filename')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

	   $dbhA->query("SELECT recording_id FROM recording_log where filename='$filename'");
	   if ($dbhA->has_selected_record) {
	   $iter=$dbhA->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $rec_count++;
		   $rec_recid_value->insert('0', "$recording_id");
		   } 
	   }


	#$dbhA->close;

	print "|channel:$channel|$filename|\n";

		$event_string = "SUBRT|start_recording|END|$filename|$channel|$recording_id|";
	 event_logger;

}






##########################################
##########################################
### starts recording locally on the customer-connected line
##########################################
##########################################
sub stop_recording
{
$SIP_user = $login_value->get;

if (length($CONFERENCE_RECORDING_CHANNEL) > 5)
	{

		$event_string = "SUBRT|stop_recording|$SIP_user|$record_channel|";
	 event_logger;


		### use manager middleware-app to connect the next call to the meetme room
			$REqueryCID = "RE$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$REqueryCID','Channel: $CONFERENCE_RECORDING_CHANNEL','','','','','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|stop_recording|RE|$REqueryCID|$stmtA|";
			 &event_logger;

	


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	   $dbhA->query("SELECT recording_id,start_epoch FROM recording_log where filename='$filename'");
	   if ($dbhA->has_selected_record) {
	   $iter=$dbhA->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $start_time = "$record->[1]";
		   $rec_count++;
		   } 
	   }

	if ($rec_count)
		{
		$length_in_sec = ($secX - $start_time);
		$length_in_min = ($length_in_sec / 60);
		$length_in_min = sprintf("%8.2f", $length_in_min);

		# print STDERR "\nQUERY done: start time = $start_time | sec: $length_in_sec | min: $length_in_min |\n";

		$stmtA = "UPDATE recording_log set end_time='$SQLdate',end_epoch='$secX',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
		}
	#$dbhA->close;

	print "|channel:$CONFERENCE_RECORDING_CHANNEL|$record_channel|$filename|\n";

	$status_value->delete('0', 'end');
    $status_value->insert('0', "Length: $length_in_min Min.");
  #  $rec_recid_value->insert('0', "$recording_id");


$record_channel='';

$start_recording_button->configure(-state => 'normal');
$stop_recording_button->configure(-state => 'disabled');

$CONFERENCE_RECORDING = 0;
$CONFERENCE_RECORDING_CHANNEL = '';

	}
}






##########################################
##########################################
### starts recording locally on the customer-connected line
##########################################
##########################################
sub hangup_ring_monitor
{
$SIP_user = $login_value->get;

if (length($monitor_channel) > 50)
	{

		$event_string = "SUBRT|stop_recording|$SIP_user|$record_channel|";
	 event_logger;


		### use manager middleware-app to connect the next call to the meetme room
			$REqueryCID = "RE$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$REqueryCID','Channel: $CONFERENCE_RECORDING_CHANNEL','','','','','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|stop_recording|RE|$REqueryCID|$stmtA|";
			 &event_logger;

	


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	   $dbhA->query("SELECT recording_id,start_epoch FROM recording_log where filename='$filename'");
	   if ($dbhA->has_selected_record) {
	   $iter=$dbhA->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $start_time = "$record->[1]";
		   $rec_count++;
		   } 
	   }

	if ($rec_count)
		{
		$length_in_sec = ($secX - $start_time);
		$length_in_min = ($length_in_sec / 60);
		$length_in_min = sprintf("%8.2f", $length_in_min);

		# print STDERR "\nQUERY done: start time = $start_time | sec: $length_in_sec | min: $length_in_min |\n";

		$stmtA = "UPDATE recording_log set end_time='$SQLdate',end_epoch='$secX',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";
		}
	#$dbhA->close;

	print "|channel:$CONFERENCE_RECORDING_CHANNEL|$record_channel|$filename|\n";

	$status_value->delete('0', 'end');
    $status_value->insert('0', "Length: $length_in_min Min.");
  #  $rec_recid_value->insert('0', "$recording_id");


$record_channel='';

$start_recording_button->configure(-state => 'normal');
$stop_recording_button->configure(-state => 'disabled');

$CONFERENCE_RECORDING = 0;
$CONFERENCE_RECORDING_CHANNEL = '';

	}
}

















##########################################
##########################################
### open disposition popup 
##########################################
##########################################
sub call_dispo_window
{

	my $dialog_call_dispo = $MW->DialogBox( -title   => "Disposition Call", -background => '#FFFFCC',
					 -buttons => [ "Reset","OK" ],
	);

	my $call_dispo_main_frame = $dialog_call_dispo->Frame( -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $call_dispo_header_row_frame = $call_dispo_main_frame->Frame( -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $call_dispo_buttons_frame = $call_dispo_main_frame->Frame( -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top');
	$call_dispo_header_row_frame->Label(-text => "SELECT A DISPOSITION: ", -background => '#FFFFCC')->pack(-side => 'left');


		### disposition entry fields
		my $dispo_pop_entry_frame = $call_dispo_buttons_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$dispo_pop_entry_frame->Label(-text => "             Stop Dialing:", -background => '#FFFFCC')->pack(-side => 'left');
		my $stopdial_value = $dispo_pop_entry_frame->Entry(-width => '4', -relief => 'sunken')->pack(-side => 'left');
		$stopdial_value->insert('0', 'NO');

		my $stop_dial_yes_button = $dispo_pop_entry_frame->Button(-text => 'YES', -width => -1, -background => '#FFFFCC',
					-command => sub 
					{
						$event_string = "CLICK|stop_dial_yes_button|||";
					 &event_logger();
					$stopdial_value->delete('0', 'end');
					$stopdial_value->insert('0', 'YES');
					});
		$stop_dial_yes_button->pack(-side => 'left', -expand => 'no', -fill => 'both');

		my $stop_dial_no_button = $dispo_pop_entry_frame->Button(-text => 'NO', -width => -1, -background => '#FFFFCC',
					-command => sub 
					{
						$event_string = "CLICK|stop_dial_no_button|||";
					 &event_logger();
					$stopdial_value->delete('0', 'end');
					$stopdial_value->insert('0', 'NO');
					});
		$stop_dial_no_button->pack(-side => 'left', -expand => 'no', -fill => 'both');

		$dispo_pop_entry_frame->Label(-text => "                                ", -background => '#FFFFCC')->pack(-side => 'left');

			$call_dispo_buttons_frame->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'top');


		### disposition select list
		my $dispo_list_frame_L = $call_dispo_buttons_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'left', -anchor   => "nw");
		my $dispo_list_frame_M = $call_dispo_buttons_frame->Frame(-background => '#FFFFCC')->pack(-expand => '0', -fill => 'none', -side => 'left', -anchor   => "nw");
			$dispo_list_frame_M->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'top');
		my $dispo_list_frame_R = $call_dispo_buttons_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'right', -anchor   => "ne");

			$call_dispo_main_frame->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'bottom');

		$status_half = ( ($#DBstatus + 0.25) / 2 );
		$status_list_count=0;
		foreach (@DBstatus)
			{
			if ($status_list_count < $status_half)
				{
				$dispo_list_frame_L->Radiobutton(-text => $_, -value => $_, -variable => \$DISP_val, -borderwidth => 2, -relief => 'groove', -width => 1, -background => '#FFFF99', -command => \&dispo_pop_change_value, -indicatoron => 0)->pack(-expand => '1', -fill => 'both', -side => 'top');
				}
			else
				{
				$dispo_list_frame_R->Radiobutton(-text => $_, -value => $_, -variable => \$DISP_val, -borderwidth => 2, -relief => 'groove', -width => 1, -background => '#FFFF99', -command => \&dispo_pop_change_value, -indicatoron => 0)->pack(-expand => '1', -fill => 'both', -side => 'top');
				}
			$status_list_count++;
			}

	my $call_dispo_result = $dialog_call_dispo->Show;
	if ($call_dispo_result =~ /Reset/i)
		{
		$DISP_val='';
		$dispo_value->delete('0', 'end');
		$dispo_ext_value->delete('0', 'end');
		$open_call_dispo_window_again=0;
		print STDERR "call_dispo window reset\n";
		&call_dispo_window;
		}
	if ($call_dispo_result =~ /OK/i)
		{
		if (length($DISP_val) > 4)
			{
			$stopdial_value_get = $stopdial_value->get;

			if ( (!$logout_hangup_flag) && ($stopdial_value_get =~ /NO/i) && ($auto_dial_next_number) )
				{
				$keep_auto_dial_value=1;
				print STDERR "starting auto_dial\n";
				$start_dialing_button->configure(-state => 'disabled');
				if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
					{
					$keep_auto_dial_value=0;

					$stmtA = "UPDATE vicidial_live_agents set status='READY' where user='$user' and server_ip='$server_ip'";
					print STDERR "|$stmtA|\n";
					$dbhA->query("$stmtA");
					my $affected_rows = $dbhA->get_affected_rows_length;
					print STDERR "vicidial_live_agents rows updated: |$affected_rows|\n";

					$auto_dialing_button_pause->configure(-state => 'normal');
					}
				}
			else
				{
				$keep_auto_dial_value=0;
				print STDERR "stopping auto_dial\n";
				$start_dialing_button->configure(-state => 'normal');
				if ( ($auto_dial_level > 0) && ($active_auto_dial > 0) )
					{
					$keep_auto_dial_value=0;

						&pause_auto_dialing;
					}
				}

				$event_string = "CLICK|dispo_OK_button|$stopdial_value_get|$keep_auto_dial_value|";
			 &event_logger();
			&commit_customer_info_to_db();

			$stopdial_value->delete('0', 'end');
			$stopdial_value->insert('0', 'NO');

			$dispo_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left

			$dispo_value->delete('0', 'end');
			$dispo_ext_value->delete('0', 'end');

			print STDERR "CALL DISPO SET: |$DISP_val|\n";
			$DISP_val='';

			print STDERR "call_dispo window closed\n";
			}
		else
			{
			$DISP_val='';
			$dispo_value->delete('0', 'end');
			$dispo_ext_value->delete('0', 'end');
			$open_call_dispo_window_again=0;
			print STDERR "call_dispo window reset: empty\n";
			&call_dispo_window;
			}
		}
# disposition popup
}

sub dispo_pop_change_value
{
	@selected_dispo_elements = split(/ -- /, $DISP_val);
	$dispo_value->delete("0", "end");
	$dispo_value->insert("0", "$selected_dispo_elements[0]");
	$dispo_ext_value->delete("0", "end");
	$dispo_ext_value->insert("0", "$selected_dispo_elements[1]");
		$event_string = "CLICK|select_from_dispo_list|$DISP_val||";
	 &event_logger();
}






##########################################
##########################################
### open dialpad for sendDTMF in conference window
##########################################
##########################################
sub dtmf_dialpad_window
{

	my $dialog_dtmf_dialpad = $MW->DialogBox( -title   => "DTMF dialpad",
					 -buttons => [ "SEND DTMF","Close" ],
	);

	my $dialpad_numbers_frame = $dialog_dtmf_dialpad->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $dialpad_header_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$dialpad_header_row_frame->Label(-text => "DTMF TONES TO SEND: ")->pack(-side => 'left');
	my $dialpad_dtmf_value = $dialpad_header_row_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
	$dialpad_dtmf_value->insert('0', '');
	my $dialpad_first_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

### keybindings for the popup DTMF dialpad
	$dialog_dtmf_dialpad->bind('<KeyRelease-1>', => [sub {$dialpad_dtmf_value->insert('end', "1");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-2>', => [sub {$dialpad_dtmf_value->insert('end', "2");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-3>', => [sub {$dialpad_dtmf_value->insert('end', "3");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-4>', => [sub {$dialpad_dtmf_value->insert('end', "4");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-5>', => [sub {$dialpad_dtmf_value->insert('end', "5");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-6>', => [sub {$dialpad_dtmf_value->insert('end', "6");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-7>', => [sub {$dialpad_dtmf_value->insert('end', "7");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-8>', => [sub {$dialpad_dtmf_value->insert('end', "8");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-9>', => [sub {$dialpad_dtmf_value->insert('end', "9");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-0>', => [sub {$dialpad_dtmf_value->insert('end', "0");}]);
	$dialog_dtmf_dialpad->bind('<asterisk>', => [sub {$dialpad_dtmf_value->insert('end', '*');}]);
	$dialog_dtmf_dialpad->bind('<slash>', => [sub {$dialpad_dtmf_value->insert('end', '#');}]);
	$dialog_dtmf_dialpad->bind('<KP_1>', => [sub {$dialpad_dtmf_value->insert('end', "1");}]);
	$dialog_dtmf_dialpad->bind('<KP_2>', => [sub {$dialpad_dtmf_value->insert('end', "2");}]);
	$dialog_dtmf_dialpad->bind('<KP_3>', => [sub {$dialpad_dtmf_value->insert('end', "3");}]);
	$dialog_dtmf_dialpad->bind('<KP_4>', => [sub {$dialpad_dtmf_value->insert('end', "4");}]);
	$dialog_dtmf_dialpad->bind('<KP_5>', => [sub {$dialpad_dtmf_value->insert('end', "5");}]);
	$dialog_dtmf_dialpad->bind('<KP_6>', => [sub {$dialpad_dtmf_value->insert('end', "6");}]);
	$dialog_dtmf_dialpad->bind('<KP_7>', => [sub {$dialpad_dtmf_value->insert('end', "7");}]);
	$dialog_dtmf_dialpad->bind('<KP_8>', => [sub {$dialpad_dtmf_value->insert('end', "8");}]);
	$dialog_dtmf_dialpad->bind('<KP_9>', => [sub {$dialpad_dtmf_value->insert('end', "9");}]);
	$dialog_dtmf_dialpad->bind('<KP_0>', => [sub {$dialpad_dtmf_value->insert('end', "0");}]);
	$dialog_dtmf_dialpad->bind('<KP_Multiply>', => [sub {$dialpad_dtmf_value->insert('end', '*');}]);
	$dialog_dtmf_dialpad->bind('<KP_Divide>', => [sub {$dialpad_dtmf_value->insert('end', '#');}]);
### these are for the screwy Gnome handling of the number pad, not necessary for X11 which handles numbers just fine
   if ($^O !~ /MSWin32/i)
	   {
		eval '

		$dialog_dtmf_dialpad->bind("<KP_End>", => [sub {$dialpad_dtmf_value->insert("end", "1");}]);
		$dialog_dtmf_dialpad->bind("<KP_Down>", => [sub {$dialpad_dtmf_value->insert("end", "2");}]);
		$dialog_dtmf_dialpad->bind("<KP_Next>", => [sub {$dialpad_dtmf_value->insert("end", "3");}]);
		$dialog_dtmf_dialpad->bind("<KP_Left>", => [sub {$dialpad_dtmf_value->insert("end", "4");}]);
		$dialog_dtmf_dialpad->bind("<KP_Begin>", => [sub {$dialpad_dtmf_value->insert("end", "5");}]);
		$dialog_dtmf_dialpad->bind("<KP_Right>", => [sub {$dialpad_dtmf_value->insert("end", "6");}]);
		$dialog_dtmf_dialpad->bind("<KP_Home>", => [sub {$dialpad_dtmf_value->insert("end", "7");}]);
		$dialog_dtmf_dialpad->bind("<KP_Up>", => [sub {$dialpad_dtmf_value->insert("end", "8");}]);
		$dialog_dtmf_dialpad->bind("<KP_Prior>", => [sub {$dialpad_dtmf_value->insert("end", "9");}]);
		$dialog_dtmf_dialpad->bind("<KP_Insert>", => [sub {$dialpad_dtmf_value->insert("end", "0");}]);
		$dialog_dtmf_dialpad->bind("<KP_Enter>", => [sub 
			{
			$dialpad_DTMF = $dialpad_dtmf_value->get;
			$xfer_dtmf_value->delete("0", "end");
			$xfer_dtmf_value->insert("end","$dialpad_DTMF");
			conf_send_dtmf;
			print STDERR "DTMF SENT: |$dialpad_DTMF|\n";
			$dialpad_dtmf_value->delete("0", "end");
			}]);

		';
	   }

#	$hash_string = '#';
#	$dialog_dtmf_dialpad->bind("<$hash_string>", => [sub {$dialpad_dtmf_value->insert('end', '#');}]);
	$dialog_dtmf_dialpad->bind('<space>', => [sub {$dialpad_dtmf_value->insert('end', ',');}]);
	$dialog_dtmf_dialpad->bind('<comma>', => [sub {$dialpad_dtmf_value->insert('end', ',');}]);
	$dialog_dtmf_dialpad->bind('<Delete>', => [sub {$dialpad_dtmf_value->delete('0','end');}]);
	$dialog_dtmf_dialpad->bind('<BackSpace>', => [sub {
		$DTMF_string = $dialpad_dtmf_value->get;
		$DTMF_length = ( (length($DTMF_string)) - 1 );
		$dialpad_dtmf_value->delete("$DTMF_length");
		}]);


#1
	my $dialpad_1 = $dialpad_first_row_frame->Button(-text => " \n1\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "1");});
	$dialpad_1->pack(-side => 'left', -expand => '1', -fill => 'both');
#2
	my $dialpad_2 = $dialpad_first_row_frame->Button(-text => " \n2\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "2");});
	$dialpad_2->pack(-side => 'left', -expand => '1', -fill => 'both');
#3
	my $dialpad_3 = $dialpad_first_row_frame->Button(-text => " \n3\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "3");});
	$dialpad_3->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_second_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#4
	my $dialpad_4 = $dialpad_second_row_frame->Button(-text => " \n4\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "4");});
	$dialpad_4->pack(-side => 'left', -expand => '1', -fill => 'both');
#5
	my $dialpad_5 = $dialpad_second_row_frame->Button(-text => " \n5\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "5");});
	$dialpad_5->pack(-side => 'left', -expand => '1', -fill => 'both');
#6
	my $dialpad_6 = $dialpad_second_row_frame->Button(-text => " \n6\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "6");});
	$dialpad_6->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_third_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#7
	my $dialpad_7 = $dialpad_third_row_frame->Button(-text => " \n7\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "7");});
	$dialpad_7->pack(-side => 'left', -expand => '1', -fill => 'both');
#8
	my $dialpad_8 = $dialpad_third_row_frame->Button(-text => " \n8\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "8");});
	$dialpad_8->pack(-side => 'left', -expand => '1', -fill => 'both');
#9
	my $dialpad_9 = $dialpad_third_row_frame->Button(-text => " \n9\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "9");});
	$dialpad_9->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_fourth_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#*
	my $dialpad_star = $dialpad_fourth_row_frame->Button(-text => " \n*\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', '*');});
	$dialpad_star->pack(-side => 'left', -expand => '1', -fill => 'both');
#0
	my $dialpad_0 = $dialpad_fourth_row_frame->Button(-text => " \n0\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "0");});
	$dialpad_0->pack(-side => 'left', -expand => '1', -fill => 'both');
##
	my $dialpad_hash = $dialpad_fourth_row_frame->Button(-text => " \n\#\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', '#');});
	$dialpad_hash->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_fifth_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#, (pause)
	my $dialpad_comma = $dialpad_fifth_row_frame->Button(-text => "one second pause", -width => -1,
				-command => sub {$dialpad_dtmf_value->insert('end', ',');});
	$dialpad_comma->pack(-side => 'left', -expand => '1', -fill => 'both');


	$dialpad_numbers_frame->Label(-text => " ")->pack(-side => 'top');


	my $dialpad_sixth_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#SUBMIT
	my $dialpad_submit = $dialpad_sixth_row_frame->Button(-text => "SEND DTMF", -width => -1,
				-command => sub {
#		$use_dialpad_DTMF=1;
		$dialpad_DTMF = $dialpad_dtmf_value->get;
		$xfer_dtmf_value->delete('0', 'end');
		$xfer_dtmf_value->insert('end',"$dialpad_DTMF");
		conf_send_dtmf;
		print STDERR "DTMF SENT: |$dialpad_DTMF|\n";
		$dialpad_dtmf_value->delete('0', 'end');
								});
	$dialpad_submit->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_result = $dialog_dtmf_dialpad->Show;
	if ($dialpad_result =~ /Close/i)
		{
		$open_dialpad_window_again=0;
		print STDERR "dialpad window closed\n";
		}
	if ($dialpad_result =~ /SEND/i)
		{
#		$use_dialpad_DTMF=1;
		$open_dialpad_window_again=1;
		$dialpad_DTMF = $dialpad_dtmf_value->get;
		$xfer_dtmf_value->delete('0', 'end');
		$xfer_dtmf_value->insert('end',"$dialpad_DTMF");
		conf_send_dtmf;
		print STDERR "DTMF SENT: |$dialpad_DTMF|\n";
		$dialpad_dtmf_value->delete('0', 'end');
		print STDERR "dialpad window closed\n";
		}
# DTMF
}





##########################################
##########################################
### send dtmf tones to conference zap channel
##########################################
##########################################
sub conf_send_dtmf
{

my $XFER_DTMF_CHAN = $session_id;
my $XFER_DTMF_DIGITS = $xfer_dtmf_value->get;

		$event_string = "SUBRT|conf_send_dtmf|$XFER_DTMF_CHAN|$XFER_DTMF_DIGITS|";
	 event_logger;

	### error box if channel to hangup is not live
if ( (length($XFER_DTMF_CHAN)<5) or (length($XFER_DTMF_DIGITS)<1) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Xfer send DTMF Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "You are not sending any DTMF digits\n  |$XFER_DTMF_DIGITS|")->pack;
		$dialog->Show;  
	}
else
	{


		### use manager middleware-app to connect the next call to the meetme room
			$DTqueryCID = "DT$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$DTqueryCID','Exten: 7$session_id','Channel: $dtmf_send_extension','Context: $ext_context','Priority: 1','Callerid: $XFER_DTMF_DIGITS','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query: $stmtA\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|conf_send_dtmf|DT|$DTqueryCID|$stmtA|";
			 &event_logger;

	



	$xfer_dtmf_value->delete('0', 'end');


	}


}




##########################################
### Open an internet browser window
##########################################
sub LaunchBrowser_New 
{
	$url =~ s/\s/+/g;
	print STDERR "OS: |$^O|\n";
   if ($^O =~ /MSWin32/i)
	   {
		eval '
	$url =~ s/\&/\^\&/g;
	   my $process;
#	print STDERR "SR: |$ENV{SYSTEMROOT}|\n";

	   use Win32::Process;
       Win32::Process::Create($process,
                                  "$ENV{SYSTEMROOT}\\\\system32\\\\cmd.exe",
                                  "cmd.exe /c start $url",
                                  0,DETACHED_PROCESS,".") ||
         printError("Unable to launch browser: " . Win32::FormatMessage(Win32::GetLastError()));
	   ';
		}
	else 
		{
		print STDERR "Starting Mozilla...\n";

		eval '
			$no_moz_found=0;
			$url =~ s/\&/\\\&/g;
		my $pid = fork;
		if ($pid == 0)
			{
			$no_moz_found = `$client_browser -remote ping\\\(\\\)`;
			$errcode = $?;
		print STDERR "|$no_moz_found|$?|$!|$errcode|\n";

			if ($errcode !~ /^0/i)
				{
				exec "$client_browser $url";
				print STDERR "|open new|\n";

				}
			else
				{
				exec "$client_browser -remote openURL\\\($url\\\)";
				print STDERR "|open exist|\n";
				}

			}';
	   }
}
