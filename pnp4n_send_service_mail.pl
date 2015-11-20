#!/usr/bin/perl
#
# Test: perl pnp4n_send_service_mail.pl -r my_email@domain.com -f html -t
#
# ######################### pnp4n_send_service_mail.pl ################ #
# Date    : 2015-11-20                                                  #
# Purpose : Script to send out Icinga2 service e-mails                  #
# Author  : Artur Zdolinski                                             #
# URL     : http://artur.zdolinski.com/index.php/icinga2/               #
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt                   #
#           Written for and verified with Icinga version 2.4.0          #
# Help    : ./pnp4n_send_service_mail.pl -h                             #
#                                                                       #
# Version : 1.0 initial release (based on Frank Migge Nagios Script)    #
#                                                                       #
# Depends : perl-Mail-Sendmail (Mail::Sendmail)                         #
#           perl-MIME-tools (MIME::Base64)                              #
#           perl-libwww-perl-6.03-2.1.2.noarch (LWP)                    #
#           libnetpbm (conversion png-to-jpg)                           #
#           netpbm (see above)                                          #
# ##################################################################### #
Getopt::Long::Configure ("bundling");
# Depends
use FindBin qw($Bin);
use Getopt::Long;
use Mail::Sendmail;
use Digest::MD5 qw(md5_hex);
use MIME::Base64;
use File::Temp;
use vars qw( $logo_id $graph_id $link_id $tmpfile $land $tbl $var %param_vars $elapse $tstamp $tstart $img_get);

# The version of this script
my $Version            ='1.0.0';

# ########################################################################
# language translated 
# ########################################################################
require "$Bin/lang/service.languages.config.pm";

# ########################################################################
# subroutine defintions below
# ########################################################################

# ########################################################################
# p_version returns the program version
# ########################################################################
sub p_version { print "$0 pnp4n_send_service_mail.pl version : $Version\n"; }

# ########################################################################
# print_usage returns the program usage
# ########################################################################
sub print_usage {
    print "Usage: $0 [-v] [-V] [-h] [-t] [-s] [-H <SMTP host>] [-p <customername>]
       [-r <to_recipients> or -g <to_group>] [-c <cc_recipients>] [-b <bcc_recipients>] 
       [-f <text|html|multi|graph>] [-u] [-l <en|jp|fr|de|(or other languages if added)>]\n";
}

# ########################################################################
# help returns the program help message
# ########################################################################
sub help {
   print "\nIcinga2 e-mail notification script for service events, version ",$Version,"\n";
   print "This version was developed for inclusion of PNP4Nagios performance graphs.\n";
   print "GPL licence, (c)2015 Artur Zdolinski\n\n";
   print_usage();
   print <<EOT;

This script takes over Icinga2 e-mail notifications by receiving the Icinga2 state
information, formatting the e-mail and sending it out through an SMTP gateway.

-v, --verbose
    print extra debugging information 
-V, --version
    prints version number
-h, --help
    print this help message
-t, --test
    generates a test message together with -r, --to-recipients
-s, --settings
    name of filename with setttings [ie. default]
-H, --smtphost=HOST
    name or IP address of SMTP gateway
-p, --customer="customer name and contract #"
    optionally, add the customer name and contract for service providers
-r, --to-recipients
   override the Icinga2-provided \$CONTACTEMAIL\$ list of to: recipients
-g, --to-group-recipients \$CONTACTGROUPMEMBERS\$
    instead of -r, use the list of contactgroup members and complete the mail
    address with the hard defined \$domain in this script. This is only possible
    when the contact name "abcd" works under the address "abcd\@domain".
-c, --cc-recipients
    the Icinga2-provided \$CONTACTADDRESS1\$ list of cc: recipients
-b, --bcc-recipients
    the Icinga2-provided \$CONTACTADDRESS2\$ list of bcc: recipients
-f, --format='text|html|multi|graph'
    the email format to generate: plain ASCII text, HTML, multipart S/MIME with
    a logo, or multipart S/MIME - adding the PNP4Nagios performance graph image
-u, --addurl
   this adds URL's to the Icinga2 web GUI for check status, host and hostgroup
   views into the html mail, requires -f html, multi or graph
-l, --language='en|pl|jp|fr|de|(or what you defined in this script)'
    the prefered e-mail language. The content-type header is hard-coded to UTF-8.
    Check if your recipients require a different characterset encoding.

Extra: Additional debug output can be generated. Within Icinga2, select a host
       and choose "Send custom host notification". Entering text, including the
       keyword "email-debug" into the "Comment" field will add additional tables
       containing a list of values for important Icinga2 and script variables.

Extra: Be aware that if you use [-s] option most of all args parameters will be
       overwrite by parameters defined in setting file.
EOT
}

# ########################################################################
# verb creates verbose output
# ########################################################################
sub verb { my $debug_output=shift; print $debug_output,"\n" if defined($o_verb); }

# ########################################################################
# unique content ID are needed for multipart messages with inline logos
# ########################################################################
sub create_content_id {
  my $unique_string  	= rand(100);
  $unique_string     	= $unique_string . substr(md5_hex(time()),0,23);
  $unique_string     	=~ s/(.{5})/$1\./g;
  my $content_id     	= qq(part.${unique_string}\@) . "MAIL";
  $unique_string     	= undef;
  return $content_id;
}

# ########################################################################
# create_boundary creates the S/MIME multipart boundary strings
# ########################################################################
sub create_boundary {
  my $unique_string  	= substr(md5_hex(time()),0,24);
  $boundary          	= '======' . $unique_string ;
  $unique_string     	= undef;
}

sub unknown_arg {
  print_usage();
  exit -1;
}

# ########################################################################
# create_address from the groupmembers list (Add by Robert Becht)
# ########################################################################
sub create_address {
  chomp($recipient_group);
  my @mlist = split(",",$recipient_group);
  foreach (@mlist) {
    my $maddress = "$_"."$domain";
    push(@listaddress,$maddress);
  }
  $recipient_group = join(",",@listaddress);
  return ($recipient_group);
}

# ########################################################################
# check_options checks and processes the commandline options given
# ########################################################################
sub check_options {
  GetOptions(
      'v'     => \$o_verb,            	'verbose'           	=> \$o_verb,
      'V'     => \$o_version,         	'version'           	=> \$o_version,
      'h'     => \$o_help,            	'help'              	=> \$o_help,
      't'     => \$o_test,            	'test'              	=> \$o_test,
      's:s'   => \$o_settings,		'settings'              => \$o_settings,
      'H:s'   => \$o_smtphost,        	'smtphost:s'        	=> \$o_smtphost,
      'p:s'   => \$o_customer,        	'customer:s'        	=> \$o_customer,
      'r:s'   => \$o_to_recipients,   	'to-recipients:s'   	=> \$o_to_recipients,
      'g:s'   => \$o_to_group,	      	'to-group-recipients' 	=> \$o_to_group,
      'c:s'   => \$o_cc_recipients,   	'cc-recipients:s'   	=> \$o_cc_recipients,
      'b:i'   => \$o_bcc_recipients,  	'bcc-recipients:s'  	=> \$o_bcc_recipients,
      'f:s'   => \$o_format,          	'format:s'          	=> \$o_format,
      'u'     => \$o_addurl,          	'addurl'            	=> \$o_addurl,
      'l:s'   => \$o_language,        	'language:s'        	=> \$o_language
  ) or unknown_arg();
  
  if (defined($o_settings))
		{
		$setting_file = "$Bin/settings/".$o_settings.".config.pm";
		unless (-e $setting_file)
				{	
				print "Error: Settings file [$setting_file] doesn't exist!\n"; 
				print_usage(); exit -1
				}
		}
  else
		{
		$setting_file = "$Bin/settings/default.config.pm";
		}
  
  require $setting_file;

  # Basic checks
  if (defined ($o_help)) { help(); exit 0};
  if (defined($o_version)) { p_version(); exit 0};
  if ((! defined($o_to_recipients)) && (! defined($o_to_group))) { # no recipients provided
    print "Error: no recipients have been provided\n"; print_usage(); exit -1}
  else {
    if (! defined($o_to_group)) {
      %mail = ( To     => $o_to_recipients,
                From   => $mail_sender,
                Sender => $mail_sender ); }
    else { 
      &create_address;
      %mail = ( To     => $recipient_group,
                From   => $mail_sender,
                Sender => $mail_sender ); }
  }

  if ( $o_format ne "text"  && $o_format ne "html"
    && $o_format ne "multi" && $o_format ne "graph") # wrong mail format
    { print "Error: wrong e-mail format [add -f html].\n"; print_usage(); exit -1}

  if (defined($o_addurl) && $o_format eq "text")
    { print "Error: cannot add URL's to text.\n"; print_usage(); exit -1}
  if (defined($o_test)) { create_test_data(); };

  # Modified by Robert Becht to support additional languages
  # if no language has been requested, try to determine default from OS
 if (! defined($o_language)) {
    # if environment $LANG is set, try to extract the first two country chars, i.e. "en|de|fr"
    if ($ENV{LANG} eq "C" || $ENV{LANG} eq "POSIX") { $land = "en"; }
    else { ($land, my $rem) = split('_',$ENV{LANG}, 2); }
  } else { $land = $o_language; }
  # Last resort: Set "English" if the requested language is not supported by our script
  if (! $language{$land}{'A'}) { $land = $o_lang_def; }
}

# ########################################################################
# if -t or --test, we need to create sample test data to for sending out.
# Most data is hardcoded. For graph generation, host and service names
# must be valid so the script can pick up the graph image from PNP4Nagios.
# ########################################################################
sub create_test_data {
  if (! defined($o_customer)){         $o_customer         = "Company XYZ International";}
  if (! defined($o_notificationtype)){ $o_notificationtype = "TEST";}
  if (! defined($o_servicestate)){     $o_servicestate     = "UNKNOWN";}
  if (! defined($o_hostname)){         $o_hostname         = $test_host;}
  if (! defined($o_hostalias)){        $o_hostalias        = "Test host alias (placeholder)";}
  if (! defined($o_hostaddress)){      $o_hostaddress      = "127.0.0.1";}
  if (! defined($o_hostgroup)){        $o_hostgroup        = "Linux Servers";}
  if (! defined($o_servicedesc)){      $o_servicedesc      = $test_service;}
  if (! defined($o_servicegroup)){     $o_servicegroup     = "performance checks";}
  if (! defined($o_datetime)){         $o_datetime         = `date`;}
  if (! defined($o_serviceoutput)){    $o_serviceoutput    = "Test output for this service";}
  if (! defined($o_notificationauth)){ $o_notificationauth = "Icinga2 Service Administrator";}
  # Setting the keyword "email-debug" in the notification comment below triggers the creation of debug tables
  if (! defined($o_notificationcmt)){  $o_notificationcmt  = "Service notification test message including email-debug";} 
}

# ########################################################################
# Create a plaintext message -> $text_msg
# ########################################################################
sub create_message_text {
  $text_msg = $language{$land}{'N'}."\n"
            . "=====================================\n\n";

  # if customer name was given for service providers, display it here
  if ( defined($o_customer)) {
    $text_msg .= $language{$land}{'A'} . ": $o_customer\n";
  }

  $text_msg = $text_msg
  		    . $language{$land}{'B'} . ": $o_notificationtype\n"
            . $language{$land}{'C'} . ": $o_servicedesc\n"
            . $language{$land}{'D'} . ": $o_servicestate\n"
            . $language{$land}{'E'} . ": $o_servicegroup\n"
            . $language{$land}{'F'} . ": $o_serviceoutput\n\n"
            . $language{$land}{'G'} . ": $o_hostname\n"
            . $language{$land}{'H'} . ": $o_hostalias\n"
            . $language{$land}{'I'} . ": $o_hostaddress\n"
            . $language{$land}{'J'} . ": $o_hostgroup\n"
            . $language{$land}{'K'} . ": $o_datetime\n\n";

  # if author and comment data has been passed from Icinga2
  # and these variables have content, then we add two more columns
  if ( ( defined($o_notificationauth) && defined($o_notificationcmt) ) &&
       ( ($o_notificationauth ne "") && ($o_notificationcmt ne "") ) ) {
    $text_msg .= $language{$land}{'L'} . ": $o_notificationauth\n"
              .  $language{$land}{'M'} . ": $o_notificationcmt\n\n";
  }

  $text_msg .= "-------------------------------------\n"
            . $language{$land}{'O'} . "\n";
}

# ########################################################################
# Create a HTML message -> $html_msg, per flags include URL's and IMG's
# ########################################################################
sub create_message_html {
  my $cellcolor = $NOTIFICATIONCOLOR{$o_notificationtype};

  # Start HTML message definition
  $html_msg = "<html><head><style type=\"text/css\">$html_style</style></head><body>\n"
            . "<table width=$table_size><tr>\n";

  if ($o_format eq "multi" || $o_format eq "graph") {
    $logo_id  = create_content_id();
    $html_msg .= "<td style=\"text-align: center;\"><img class=\"logo\" src=\"cid:$logo_id\" border=0></td>"
              .  "<td><span>$language{$land}{'N'}</span></td></tr><tr>\n";
  } else {
    $html_msg .= "<th colspan=\"2\"><span>$language{$land}{'N'}</span></th></tr><tr>\n"; }

  if ( defined($o_customer)) {
    $html_msg .= "<th colspan=2 class=customer>$o_customer</th></tr><tr>\n"; }

  $html_msg .= "<th width=$header_size class=even>$language{$land}{'B'}:</th>\n"
            . "<td bgcolor=$cellcolor>\n"
            . "$o_notificationtype</td></tr>\n"
            . "<tr><th class=odd>$language{$land}{'C'}:</th><td>$o_servicedesc</td></tr>\n"
            . "<tr><th class=even>$language{$land}{'E'}:</th><td class=even>\n";

  # The Servicegroup URL http://<nagios-web>/cgi-bin/status.cgi?servicegroup=$SERVICEGROUPNAME$&style=overview
  # This URL shows the service group table listing ofthe hosts that have this service
  if (defined($o_addurl)) {
    $html_msg .= "<a href=\"$icinga2_cgiurl/status.cgi?servicegroup=" . $o_servicegroup . "&style=overview\">$o_servicegroup</a>";
  }
  else { $html_msg  .= $o_servicegroup; }

  # Print the service state, set the cell color based on the value CRITICAL, WARNING, OK, UNKNOWN
  $cellcolor = $NOTIFICATIONCOLOR{$o_servicestate};
  $html_msg .= "</td></tr>\n"
            . "<tr><th class=odd>$language{$land}{'D'}:</th><td bgcolor=$cellcolor>$o_servicestate</td></tr>\n"
            . "<tr><th class=even>$language{$land}{'F'}:</th><td class=even>\n";

  # The ServiceOutput URL
  # This URL shows the full service details and commands for service management (ack, re-check, disable, etc)
  if (defined($o_addurl)) {
    $html_msg .= "<a href=\"$icinga2_cgiurl/monitoring/service/show?host=" . $o_hostname . "&service=" . $o_servicedesc . "\">$o_serviceoutput</a>\n";

    # If the graph image wasn't empty, We add an additional link for PNP4Nagios
    if ($o_format eq "graph" && $graph_type ne "gif") {
      $link_id  = create_content_id();
      $html_msg .=  " <a href=\"$pnp4nagios_url/graph?host=" . $o_hostname
                . "&srv=" . $o_servicedesc . "\">"
                . "<img class=\"link\" src=\"cid:$link_id\"></a>\n"; }
  }
  else { $html_msg .= $o_serviceoutput; }
  
  $html_msg .= "</td></tr>\n"
            .  "<tr><th class=odd>$language{$land}{'G'}:</th><td>\n";

  # The Hostname URL http://<nagios-web>/cgi-bin/status.cgi?host=$HOSTNAME$
  # this URL shows the host and all services underneath it
  if (defined($o_addurl)) {
    $html_msg .= "<a href=\"$icinga2_cgiurl/monitoring/host/show?host=" . $o_hostname
              . "\">$o_hostname</a>";
  }
  else { $html_msg .= $o_hostname; }
  
  $html_msg .= "</td></tr>\n"
            . "<tr><th class=even>$language{$land}{'H'}:</th><td class=even>$o_hostalias</td></tr>\n"
            . "<tr><th class=odd>$language{$land}{'I'}:</th><td>$o_hostaddress</td></tr>\n"
            . "<tr><th class=even>$language{$land}{'J'}:</th><td class=even>\n";
  
  # The Hostgroup URL http://<nagios-web>/cgi-bin/status.cgi?hostgroup=$HOSTGROUPNAME$&style=overview
  # This URL shows the hostgroup table listing for all individual hosts that belong to it
  if (defined($o_addurl)) {
    $html_msg .= "<a href=\"$icinga2_cgiurl/monitoring/list/hosts?hostgroup_name=" . $o_hostgroup_first ."\">$o_hostgroup</a>";
  }
  else { $html_msg .= $o_hostgroup; }
  
  $html_msg .= "</td></tr>\n"
            .  "<tr><th class=odd>$language{$land}{'K'}:</th><td>$o_datetime</td></tr>\n";

  # If the author and comment data has been passed from Icinga2
  # and these variables have content, then we add two more columns
  if ( ( defined($o_notificationauth) && defined($o_notificationcmt) ) &&
       ( ($o_notificationauth ne "") && ($o_notificationcmt ne "") ) ) {
    $html_msg .= "<tr><th class=even>$language{$land}{'L'}:</th>\n"
              . "<td class=even>$o_notificationauth</td></tr>\n"
              . "<tr><th class=odd>$language{$land}{'M'}:</th>\n"
              . "<td>$o_notificationcmt</td></tr>\n";
  }

  $html_msg .= "</table>\n";

  # if we got the graph format and a image has been generated, we add it here
  if (defined($graph_img) && $o_format eq "graph") {
    $graph_id = create_content_id();
    $html_msg .= "<br><img src=\"cid:$graph_id\">\n";
  } 

  # add the Icinga2 footer tag line here
  $html_msg .= "<p class=\"foot\">\n$language{$land}{'O'}\n</p>\n";

  # add the extra debugtables if verbose output had been requested,
  # or if the notification command contains the keyword "email-debug"
  if (defined($o_notificationcmt) && ($o_notificationcmt =~ m/email-debug/i)
  || defined($o_verb)) {
    &create_debugtable;
    $html_msg .= $debugtables;
  }

  # End HTML message definition
  $html_msg .= "</body></html>\n";
}

# #######################################################################
# urlencode() URL encode a string
# #######################################################################
sub urlencode {
  my $urldata = $_[0];
  my $MetaChars = quotemeta( ';,/?\|=+)(*&^%$#@!~`:');
  $urldata =~ s/([$MetaChars\"\'\x80-\xFF])/"%" . uc(sprintf("%2.2x",         ord($1)))/eg;
  $urldata =~ s/ /\+/g;
  return $urldata;
}

# ########################################################################
# b64encode_image(filename) converts a existing binary source image file
# into a base64-image string.
# ########################################################################
sub b64encode_img {
  my($inputfile) = @_;
  open (IMG, $inputfile) or verb("b64encode_img: Cannot read source image file: $inputfile - $!");
  binmode IMG; undef $/;
  my $b64encoded_img = encode_base64(<IMG>);
  close IMG;
  verb("b64encode_img: completed conversion of source image file: $inputfile - $!");
  return $b64encoded_img;
}

# ########################################################################
# import_pnp_graph collects the PNP4Nagios host graph via its web URL
# ########################################################################
sub import_pnp_graph { 
  use LWP;
  use FileHandle;
  $tstamp = time();

  # This sets the graph history
  $elapse = ($graph_history * 3600);
  $tstart = ($tstamp - $elapse);

  # generate temporary graph file
  my $fhandle = File::Temp->new(UNLINK =>1) or verb("import_pnp_graph: Cannot create temporary image file.");
  $fhandle->autoflush(1);
  $tmpfile = $fhandle->filename;

  # Download the image
  my $ua = LWP::UserAgent->new( );

  # Check if web authentication is required
  if (defined($pnp4nagios_auth)) {
    $ua->credentials("$server_port", "$auth_name", "$web_user" => "$web_pass");
  }

  $img_get = "$pnp4nagios_url/image?host=" . $o_hostname . "&srv=" . $o_servicedesc . "&source=0&start=$tstart&end=$tstamp";

  my $res = $ua->get($img_get);
  if ($res->is_success) {
    verb("import_pnp_graph: Downloaded PNP4Nagios image file. Server response: ".$res->status_line."\n");
    # write the graph file to $tmpfile and set the graph format
    print $fhandle $res->content;
    $graph_type = "png";

    # Because our mail system being Lotus Notes, which is not supporting PNG
    # images, we must convert them from PNG to JPG before we can continue.
    # Set $jpg_workaround = true if your mail client has the same trouble.
    if (defined($jpg_workaround)) {
      my $tmpfile_new = $tmpfile.".jpg";
      `pngtopnm $tmpfile | pnmtojpeg >$tmpfile_new`;
      `mv $tmpfile_new $tmpfile`;
      $graph_type = "jpg";
    }

    $graph_img = b64encode_img($tmpfile);
    verb("import_pnp_graph: Encoded PNP4Nagios image file, format: ".$graph_type."\n");
  # Next is what we do if we cannot get a image from PNP4Nagios
  } else {
    verb("import_pnp_graph: Cannot download PNP4Nagios image file. Server response: ".$res->status_line);
    # In this case, we create a 1x1px empty image to be included
    $graph_type = "gif";
    $graph_img = $empty_img;
    verb("import_pnp_graph: Returning empty image file, format: ".$graph_type."\n");
  }
  return $graph_img;
}

# ########################################################################
# language translated email subject: $lang{$land}
# ########################################################################
sub set_subject {
  my $subject;
  my $b64_sub = "";

  # special base64 encoding is required for subject parts send in Japanese
  if ($land eq "jp") {
    $b64_sub = " =?utf-8?B?" . encode_base64("のサービス");
    chomp $b64_sub;
    $b64_sub = $b64_sub . "?= ";
  }

  my %lang =  ('en' => "Icinga2: $o_notificationtype service $o_servicedesc on $o_hostname ($o_hostgroup) is $o_servicestate",
               'pl' => "Icinga2: $o_notificationtype usługa $o_servicedesc na $o_hostname jest w statusie: $o_servicestate",
               'de' => "Icinga2: $o_notificationtype $o_hostname($o_hostgroup) mit Dienst $o_servicedesc ist $o_servicestate",
               'jp' => "Icinga2: $o_notificationtype $o_hostname($o_hostgroup) ".$b64_sub." $o_servicedesc $o_servicestate",
               'fr' => "Icinga2: $o_notificationtype : le service $o_servicedesc sur $o_hostname ($o_hostgroup) est $o_servicestate" );

  if (!defined($lang{$land})) { $subject = $lang{'en'}; }
  else { $subject = $lang{$land}; }

  return $subject;
}

# ########################################################################
# main
# ########################################################################
check_options();

if (defined($o_settings))
	{
	my $setting_file = "$Bin/settings/".$o_settings.".config.pm";

	unless (-e $setting_file)
			{	
			print "Error: Settings file [$setting_file] doesn't exist!\n"; 
			print_usage(); exit -1
			}
	require $setting_file;
	}

if (! defined ($o_notificationtype) && ! defined($o_test)) {
  p_version();
  print "\nError, no notification type available. Are you trying to send a test message?\n";
  print "For a manual test from the commandline, we need to give the -t option.\n";
  exit -1;
}

$mail{Cc}   = $o_cc_recipients if ($o_cc_recipients);
$mail{Bcc}  = $o_bcc_recipients if ($o_bcc_recipients);
$mail{smtp} = $o_smtphost;
$mail{subject} = set_subject();

# If the mail server requires authentication, try this line:
# $mail{auth} = {user => "<username>", password => "<mailpw>", method="">"LOGIN PLAIN", required=>1};

if ($o_format eq "graph") {
  verb("main: trying to create the PNP4Nagios graph image.");
  $graph_img = import_pnp_graph();
}

if ($o_format eq "multi" || $o_format eq "graph") {
  verb("main: Sending HTML email (language: $land) with inline logo.");

  # check if the logo file exists
  if (-e $logofile) {
    # In e-mails, images need to be base64 encoded, we encode the logo here
    $logo_img = b64encode_img($logofile);
    # extract the image format from the file extension
    $logo_type = ($logofile =~ m/([^.]+)$/)[0];
    verb("main: Converted inline logo data to base64 and set type to $logo_type.");
    # create the second boundary marker for the logo
  } else {
if (defined($logo_img) && $logo_img ne "")
    	{
    	# If $logo_img (base64) is defined or not empty - we will use it
    	$logo_type = "png";
    	verb("main: Using defult Icinga image $logo_type.");
    	}
    else
    	{
	    # If the logo file cannot be found, we send a 1x1px empty logo image instead
	    $logo_img = $empty_img;
	    $logo_type = "gif";
	    verb("main: Could not find inline logo file at $logofile, setting empty logo image.");
    	}
  }

  create_boundary();
  create_message_html();
  $mail{'content-type'} = qq(multipart/related; boundary="$boundary");
  $boundary = '--' . $boundary;

  # Here we define the mail content to be send
  my $mail_content = "This is a multi-part message in MIME format.\n"
  # create the first boundary start marker for the main message
          . "$boundary\n"
          . "Content-Type: text/html; charset=utf-8\n"
          . "Content-Transfer-Encoding: 8bit\n\n"
          . "$html_msg\n";

  # create the second boundary marker for the logo image
  $mail_content = $mail_content . "$boundary\n"
          . "Content-Type: image/$logo_type; name=\"logo.$logo_type\"\n"
          . "Content-Transfer-Encoding: base64\n"
          . "Content-ID: <$logo_id>\n"
          . "Content-Disposition: inline; filename=\"logo.$logo_type\"\n\n"
          . "$logo_img\n";

  # if we got the graph format and a image has been generated, we add it here
  if (defined($graph_img) && $o_format eq "graph") {

    # create the third boundary marker for the graph link image
    $mail_content = $mail_content . "$boundary\n"
          . "Content-Type: image/$link_type; name=\"logo.$link_type\"\n"
          . "Content-Transfer-Encoding: base64\n"
          . "Content-ID: <$link_id>\n"
          . "Content-Disposition: inline; filename=\"link.$link_type\"\n\n"
          . "$link_img\n";

    # create the fourth boundary marker for the graph image
    $mail_content = $mail_content . "\n" . "$boundary\n"
          . "Content-Type: image/$graph_type; name=\"graph.$graph_type\"\n"
          . "Content-Transfer-Encoding: base64\n"
          . "Content-ID: <$graph_id>\n"
          . "Content-Disposition: inline; filename=\"graph.$graph_type\"\n\n"
          . "$graph_img\n";
   }
   # create the final end boundary marker
   $mail_content = $mail_content . $boundary . "--\n";
   # put the completed message body into the mail
   $mail{body} = $mail_content ;
}
elsif ($o_format eq "html") {
  create_message_html();
  $mail{'content-type'} = qq(text/html; charset="utf-8");
  $mail{body} = $html_msg ;
} else {
  create_message_text();
  $mail{'content-type'} = qq(text/plain; charset="utf-8");
  $mail{body} = $text_msg ;
} 

sendmail(%mail) or die $Mail::Sendmail::error;
verb("Sendmail Log says:\n$Mail::Sendmail::log\n");
exit 0;

# #######################################################################
# Create a debugging table to check on Icinga2 and script variables
# Added by Robert Becht to create a HTML table for debugging
# #######################################################################

sub create_debugtable() {
  my $varcount = 0;
  my $oddcheck = "odd";
  
  # Check if the following variables are defined
  my %param_vars = (
				'script'  => {	"title"					=>  'Script debug data',
								"o_verb"          		=>  \$o_verb,
								"o_version"       		=>  \$o_version,
								"o_help"          		=>  \$o_help,
								"o_smtphost"      		=>  \$o_smtphost,
								"o_customer"      		=>  \$o_customer,
								"o_to_recipients" 		=>  \$o_to_recipients,
								"o_to_group"      		=>  \$o_to_group,
								"o_cc_recipients" 		=>  \$o_cc_recipients,
								"o_bcc_recipients"		=>  \$o_bcc_recipients,
								"o_format"	 			=>  \$o_format,
								"o_addurl"	 			=>  \$o_addurl,
								"o_language"	 		=>  \$o_language,
								"o_test"				=>  \$o_test,
								"o_smtphost"	 		=>  \$o_smtphost,
								"domain"				=>  \$domain,
								"land"		 			=>  \$land, 
								"logo file"				=>  \$logofile,
								"logo format"			=>  \$logo_type,
								"temporary file"		=>  \$tmpfile,
								"boundary"				=>  \$boundary },
				'icinga2'  => {	"title"		   			=>  'Icinga2 debug data',
								"o_notificationtype"	=>  \$o_notificationtype,
								"o_notificationauth"	=>  \$o_notificationauth,
								"o_notificationcmt" 	=>  \$o_notificationcmt,
								"o_servicedesc"     	=>  \$o_servicedesc,
								"o_servicestate"    	=>  \$o_servicestate,
								"o_servicegroup"    	=>  \$o_servicegroup,
								"o_hostname"        	=>  \$o_hostname,
								"o_hostalias"       	=>  \$o_hostalias,
								"o_hostgroup"       	=>  \$o_hostgroup,
								"o_hostaddress"     	=>  \$o_hostaddress,
								"o_serviceoutput"   	=>  \$o_serviceoutput,
								"o_datetime"        	=>  \$o_datetime,
								"o_to_recipients"   	=>  \$o_to_recipients,
								"o_to_group"        	=>  \$o_to_group },
	      	  'pnp4nagios' => { "title"					=>  'PNP4Nagios debug data',
								"access URL"			=>  \$pnp4nagios_url,
								"img_get"				=>  \$img_get,
								"interval(s)"			=>  \$elapse,
								"time start"			=>  \$tstamp }  );
  
  # loop to display the script variable tables
  foreach $tbl (keys %param_vars) {
    $debugtables .= "<br>\n"
                 . "<table width=$table_size>\n"
                 . "<tr><th colspan=2 class=customer>$param_vars{$tbl}->{'title'}</th></tr>\n";

    $varcount = 0;
    # Data loop
    foreach $var (keys %{$param_vars{$tbl}}) {
      if ($var ne 'title') {
        if ($varcount%2) {$oddcheck = "odd";} else {$oddcheck = "even";}
        $debugtables .= "<tr><th class=$oddcheck>$var</th>";

        if ((! defined(${$param_vars{$tbl}->{$var}})) || (${$param_vars{$tbl}->{$var}} eq '')) {
          $debugtables .= "<td class=$oddcheck>&nbsp;</td></tr>\n";
        } else {
          $debugtables .= "<td class=$oddcheck>${$param_vars{$tbl}->{$var}}</td></tr>\n";
        }
        $varcount++;
      }
    }
    $debugtables .= "</table>";
    $debugtables .="<br>\n";
  }
}
# ##################### End of pnp4n_send_service_mail.pl ####################
