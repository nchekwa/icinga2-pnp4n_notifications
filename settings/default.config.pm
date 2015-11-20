# The next variables are provided through args
# used only when are not set via args

if (!defined($o_to_group))			{	$o_to_group         = undef;     }# this flag is only set with the -g option
if (!defined($o_cc_recipients))		{	$o_cc_recipients    = undef;     }# The recipients defined in $CONTACTADDRESS1$
if (!defined($o_bcc_recipients))	{	$o_bcc_recipients   = undef;     }# The recipients defined in $CONTACTADDRESS2$
if (!defined($o_format))			{	$o_format           = "graph";     }# The e-mail output format (default: graph) (text|html|multi|graph)
if (!defined($o_addurl))			{	$o_addurl           = "http://icinga.mydomain.com";     }# flag to add Icinga2 GUI URLs to HTML e-mails
if (!defined($o_language))			{	$o_language         = undef;     }# The e-mail output language
if (!defined($o_customer))			{	$o_customer         = "Company XYZ International";     }# Company name and contract number for service providers
if (!defined($o_help))				{	$o_help             = undef;     }# We want help
if (!defined($o_verb))				{	$o_verb             = undef;     }# verbose mode 
if (!defined($o_version))			{	$o_version          = undef;     }# print version
if (!defined($o_test))				{	$o_test             = undef;     }# generate a test message

# ####################################################################################################################################
# The e-mail output language default
$o_lang_def         = "en"; 
# the sender e-mail address to be seen by recipients
$mail_sender        = "Icinga2 Monitoring <icinga\@mydomain.com>";
# The Icinga2 CGI URL for integrated host and service links
$icinga2_cgiurl      = "http://icinga.mydomain.com/icingaweb2";
# Here we define a simple HTML stylesheet to be used in the HTML header.
$html_style         = "body {text-align: center; font-family: Verdana, sans-serif; font-size: 10pt;}\n"
                       . "img.logo {float: left; margin: 10px 10px 10px; vertical-align: middle}\n"
                       . "img.link {float: right;  margin: 0px 1px; vertical-align: middle}\n"
                       . "span {font-family: Verdana, sans-serif; font-size: 12pt;}\n"
                       . "table {text-align:center; margin-left: auto; margin-right: auto; border: 1px solid black;}\n"
                       . "th {white-space: nowrap;}\n"
                       . "th.even {background-color: #D9D9D9;}\n"
                       . "td.even {background-color: #F2F2F2;}\n"
                       . "th.odd {background-color: #F2F2F2;}\n"
                       . "td.odd {background-color: #FFFFFF;}\n"
                       . "th,td {font-family: Verdana, sans-serif; font-size: 10pt; text-align:left;}\n"
                       . "th.customer {width: 600px; background-color: #004488; color: #ffffff;}\n"
                       . "p.foot {width: 602px; background-color: #004488; color: #ffffff; "
                       . "margin-left: auto; margin-right: auto;}\n";
$table_size         = "600px";
$header_size        = "180px";
$data_size          = "420px";
$debugtables        = "<br>\n";

# ######################################################################################################
# For tests using the -t/--test option, if we want to see PNP4Nagios
# graphs we need to set a valid host name and service name below.
# ######################################################################################################
$test_host          = "MyIcingaHost";    		# existing host in PNP4Nagios
$test_service       = "ping4"; 					# existing services in PNP4nagios

# ######################################################################################################
# Here we set the URL to pick up the RRD data files for the optional graph
# image generation. Modified by Robert Becht for use with PNP4Nagios.
# The PNP4Nagios URL : if not used we can set $pnp4nagios_url = undef;
# ######################################################################################################
$pnp4nagios_url     = "http://icinga.mydomain.com/pnp4nagios";
$graph_history      = 48; # in hours, a good range is between 12...48

# ######################################################################################################
# If web authentication is needed, configure the access parameters below:
# ######################################################################################################
$pnp4nagios_auth    = undef; # $pnp4nagios_auth    = "true";
$server_port        = undef; # $server_port        = "nagios.frank4dd.com:80";
$auth_name          = undef; # $auth_name          = "pnp4nagios";
$web_user           = undef; # $web_user           = "pnp4nget";
$web_pass           = undef; # $web_pass           = "mypass";

# ######################################################################################################
# SMTP related data: If the commandline argument -H/--smtphost was not
# given, we use the provided value in $o_smtphost below as the default.
# If the mailserver requires auth, an example is further down the code.
# ######################################################################################################
$o_smtphost			= "mailserver.mydomain.com";
$domain				= "\@mydomain.com"; # this is only for -g groups
@listaddress		= ();

# ######################################################################################################
# This is the logo image file, the path must point to a valid JPG, GIF or
# PNG file, i.e. the nagios logo. Best size is rectangular up to 160x80px.
# example: [nagioshome]/share/images/NagiosEnterprises-whitebg-112x46.png
# ######################################################################################################
$logofile = "";   # i.e. $Bin/img/icinga.logo.png

# ######################################################################################################
# Because our mail system being Lotus Notes, which is not supporting PNG
# images, we must convert them from PNG to JPG before we can continue.
# Set $jpg_workaround = true if your mail client has the same trouble.
# ######################################################################################################
$jpg_workaround = undef;

# ######################################################################################################
# Here I define the HTML color values for each Icinga2 notification type.
# There is one extra called TEST for sending a test e-mail from the cmdline
# outside of Icinga2. The color values are used for highlighting the
# background of the notification type cell.
# ######################################################################################################
%NOTIFICATIONCOLOR=(	'PROBLEM'           =>'#FF8080',
                        'RECOVERY'          =>'#80FF80',
                        'ACKNOWLEDGEMENT'   =>'#FFFF80',
                        'DOWNTIMESTART'     =>'#80FFFF',
                        'DOWNTIMEEND'       =>'#80FF80',
                        'DOWNTIMECANCELLED' =>'#FFFF80',
                        'FLAPPINGSTART'     =>'#FF8080',
                        'FLAPPINGSTOP'      =>'#80FF80',
                        'FLAPPINGDISABLED'  =>'#FFFF80',
                        'TEST'              =>'#80FFFF',
                        'CRITICAL'          =>'#FFAA60',
                        'WARNING'           =>'#FFFF80',
                        'OK'                =>'#80FF80',
                        'UNKNOWN'           =>'#80FFFF',
                        'UP'                =>'#80FF80',
                        'DOWN'              =>'#FFAA60',
                        'UNREACHABLE'       =>'#80FFFF',
                        'CUSTOM'            =>'#000000'
                       	);

$cellcolor = '#FFFFFF';

if (! defined($o_test))
{
####### Global Variables - No changes necessary below this line ##########
# ICINGA: grep "#ENV" pnp4n_send_host_mail.pl
# ------------------------------------------------------------------------
####### Notification type, i.e. PROBLEM
#ENV:   NOTIFICATIONTYPE        = "$notification.type$"
$o_notificationtype = $ENV{NOTIFICATIONTYPE};
# ------------------------------------------------------------------------
####### Notification author                                     (if avail.)
#ENV:   NOTIFICATIONAUTHOR      = "$notification.author$"
$o_notificationauth = $ENV{NOTIFICATIONAUTHOR};
# ------------------------------------------------------------------------
####### Notification comment                                    (if avail.)
#ENV:   NOTIFICATIONCOMMENT     = "$host.notes | $service.notes$"
$o_notificationcmt  = $ENV{NOTIFICATIONCOMMENT};
# ------------------------------------------------------------------------
####### Monitored host name
#ENV:   HOSTNAME                = "$host.name$"
$o_hostname = $ENV{HOSTNAME};
# ------------------------------------------------------------------------
####### Monitored host alias
#ENV:   HOSTDISPLAYNAME         = "$host.display_name$"
$o_hostalias        = $ENV{HOSTDISPLAYNAME};
# ------------------------------------------------------------------------
####### Host group the host belongs to
#ENV:   HOSTGROUPNAME		= "$host.display_name$"
$o_hostgroup        = $ENV{HOSTGROUPNAME};
($o_hostgroup_first, $o_hostgroup_rest) = split /;/, $o_hostgroup, 2;
# ------------------------------------------------------------------------
####### Monitored host IP address
#ENV:   HOSTADDRESS		= "$host.address$"
$o_hostaddress      = $ENV{HOSTADDRESS};
# ------------------------------------------------------------------------
####### Monitored host state, i.e. DOWN
#ENV:   HOSTSTATE		= "$host.state$"
$o_hoststate        = $ENV{HOSTSTATE};
# ------------------------------------------------------------------------
####### Monitored host check output data
#ENV:   HOSTOUTPUT		= "$host.output$"
$o_hostoutput       = $ENV{HOSTOUTPUT};
# ------------------------------------------------------------------------
######## Date when the event was recorded
#ENV:   LONGDATETIME		= "$icinga.long_date_time$"
$o_datetime         = $ENV{LONGDATETIME};
# ------------------------------------------------------------------------
####### The recipients defined in $CONTACTEMAIL$
#ENV:   CONTACTEMAIL		= "$user.email$"
$o_to_recipients    = $ENV{CONTACTEMAIL};
# ------------------------------------------------------------------------
# Modified by Robert Becht for using $CONTACTGROUPEMEMBERS$ in nagios.conf
#ENV:   CONTACTGROUPMEMBERS	= ""
$recipient_group    = $ENV{CONTACTGROUPMEMBERS};
# ------------------------------------------------------------------------
####### Service description
#ENV:   SERVICEDESC		= "$service.name$"
$o_servicedesc = $ENV{SERVICEDESC};
# ------------------------------------------------------------------------
####### Service state
#ENV:   SERVICESTATE		= "$service.state$"
$o_servicestate	= $ENV{SERVICESTATE};
# ------------------------------------------------------------------------
####### Service group the service belongs to
#ENV:   SERVICEGROUPNAME	= ""
$o_servicegroup     	= $ENV{SERVICEGROUPNAME};
# ------------------------------------------------------------------------
####### Service check output data
#ENV:   SERVICEOUTPUT		= "$service.output$"
$o_serviceoutput		= $ENV{SERVICEOUTPUT};
# ------------------------------------------------------------------------
}


# These variables are used in various subroutines
$text_msg           = undef; # the plaintext notification
$html_msg           = undef; # the HTML-formatted notification
$graphfile          = undef; # if we generate graphs, the tmp file location
$logo_img           = 	  "iVBORw0KGgoAAAANSUhEUgAAAKAAAAA6CAMAAAAA7KI6AAADAFBMVEWDfoLV1NWloaRiXWH6+vq+"
						. "vL7S0NFYUVainqH29vZuaWwqJipeWlxTTVLOzM6opKfa2dlbVlqZlZhHQEVFQkDx8PCVkZTKycpR"
						. "Sk2KhomysLG1s7Ty8vIuKi719PRVUVSRjZDFxMVmYGWdmp16dXnu7u5qZWloYmaYlJdgXF7t7Ozp"
						. "6Oi2tLV+eX3l5ORzbXFNSEiqqKp5c3a6uLqurK5JRkWppqjJxsh2cXWFgYRMRkmBfH9PSE2Oio3j"
						. "4uMgHCA+NzzBv8GmpKXf3t8bFxxva26tqq2Ig4dLRUk4MDYsKS0oJSnAvsC4trhBOT+NiIuxrrCf"
						. "nZ01LTO4tbc0LDImIiaEgoE9Oj48NDrr6uuioaGgnJ/h4OHd3N00MTXEwcObmJs1Mzako6IyLzMw"
						. "LDBMR0aPjY7c2tvEwsS0sbKTkZLHxcaWlJfNy8y9urw2NDc6ODtEPEKSkZA8Oj28ubs4NTiRjo5Z"
						. "VlVAPUCamZmCf4PAv744Njnn5ud8ennX1tfZ19iwra45MjfT0tNFPUPMystBPkFJQUerqap+fH5K"
						. "Q0hCP0KHhoSLiYnPzs50cnAkICRMSEZNRkzh3+BCQD5TUE6trKvV09Q3NThiYF52dHJCO0CJiIZ2"
						. "dHZbWFY/PD9CPkCWlZNycHLExMOFg4OwsK9QTUydnJuZmJdOTEppZ2XQz9Bxb23JyMdnZWNmY2G8"
						. "vLtnZGd6eHcuKy88ODx/fXxXVFJ3dHg0MjU2MjY6NzstKi4zMDQ5NzolIiYrKCsxLjEpJio7OTz4"
						. "+Pg+Oz/m5eb5+fn8/PwxLjL9/f0/PEBDPEH5+Pne3d7k4+T+/v7o5+jq6erd29zs6+zw7/Di4eLz"
						. "8/Pg39/BwL/7+/tHREKHhYji4eHw7++vrrClpKOhoJ8pJin19fXe3t2NjIorKCxzcXQzMDMnIye7"
						. "ury5uLf29fXQ0M9HREZYU1fo5+cwLTDY2Nd8eHyBf37g4N8tKS2npqbPzc9EQEJQTFAlISVBP0Lj"
						. "4+M6NzkzKzH///9Dqk4XAAAAAXRSTlMAQObYZgAAAAFiS0dEAIgFHUgAAAAJcEhZcwAACxMAAAsT"
						. "AQCanBgAAAAHdElNRQffCxQPCAqkR9GoAAAE60lEQVRo3u2YX2gcRRjAN6UE020V49nYnu2DRKVU"
						. "aWq0VzVtShJiuktVCmqlcLCs96Cgm3o9CWHbxKamyoEcguGgUhCffBCEA1/2bzab9qzin4eqRZ9E"
						. "ZF9MF4tK+7C4M3e7OzO7e3+wuVuw83LfzDd/fvfNzDfftxR1u/yfi0UvW5uTizdM8xwnS1ZiAdVK"
						. "2ciLspZJKiCrG4vFPCfdSCxgtQa4JbFbLBUMQ+S18aQCjtN6NsszanKv8T6aYbQE81HUIwn30z8l"
						. "/SFJJYhlVgu/GPPXEgQoladlIcEGfF1/qVhm8bZrPUk6bkxB4Z9qwYB9XSOctoY9pHcuDA3tml+6"
						. "Gu5EV+zu+m1A+NqOmxbLWiVhKRwe8mVFkLZ2lzCn0hojSYxGl54IRQ/C5eI0392nJWdpUqXK81Vb"
						. "0qxcCNBc7DLgRy9oUlXOclxWrkpaCVV9+2Zqh14Ws1K6u0mIyyeIiiIKLiH9Rb35y99SHw4AE0oV"
						. "5pVu8n2uahVZUAwzbyiCbGvQM76aSt3pdRib7evqCRxiJZ0TDXNx0TRETpdKqQtziYoO/mAlnlPM"
						. "mWJxxlQ4XlI/SVj4MgUB8wAwDwBvftaw+6QDy77YDvuh/tDBkGILVNwTOWhnIyfDMnoWbPFMbYtH"
						. "V3D9BndWv3KX4xe/bQ+66uO+/jA+zcO+4mwIYQ2dLlSWLM1GL0mJ0IM599blow5S9iIdrkR1uJ+Y"
						. "JfzfEOW2eMJR181ka24m67qZTyNGPxCxiuM8DxtXgLghssOv0Xwk4eZI6qBsslBHrVKxgPvr05/B"
						. "1kEA73ZiQBynEaHTBNB1NJpk6zyvu08dm4sHRCZ6OZARwBo+FLdD+XxtigFYqX2R+hPKTyILpJtd"
						. "O4o6PcEua262ucxOfEzFAsJpznnNH4BaLwboIKehXusLRK/9CmmvuJOJBTRDEyprqRO5iIAVB8Tb"
						. "3wgD+npoQ/gF5TtccQ6fJ+0BTsbzXd9IUe9ffws8ILsaA67h7dgWnwLCc4RlgPAYEL4JjyTPZyzf"
						. "pdOB/GIs4I9AGEAUmUn8krwNhJUIwPPk6luPkDvcT7ql+EQkFQc4DoTV8GgfEDrxSxGAhxqZZwEo"
						. "F6hGJsS/9/7SYcB6r5H4Prv/xqoXbabjgM/Uf4kL0FNS1VIveer+mpm+vJ6AJ2DzWKjTjdC/KLnu"
						. "2XXMo8R6B3l75zoCejf2AFLvJ59UWI4sV3RZ5iv09ibh2C0F/J7wKScCkbwmqiQXRLEgV9ROAlIE"
						. "IBRHYIHiyeBTL6sLhmkags7OdRKwHwM8EB9FvKfJolksmoqs/d5JQHwzQ3yBo58NAAfbAOy5pYDj"
						. "YcAgDmdtNxHJK0KVbfEMQuG+Bm9xLOAeIOzGFc9GG9Bxvva9jJsqCQU3SSq1A0g88idbAlzFR06B"
						. "2rsRgdcCYULG1nWbaWbAAPBoEI665StQm28JEP9rD/o1KJyKPJyg9Kq0ptHWPy0DbkQC5tq5anGL"
						. "6xndCtJ8LMrzUU8TDavbfl5tnjcHHr6eiwz2ZNZq0nCLgN5hG5tLHw68CYzJj4fWOttuYh+f1Z2h"
						. "WgW8lxiZiTQgRR1rFvrHAQ5GZme1tqtATHsxfsyJ6sUGBinWVMRi7QLegR3cYJWLftrq2dLdvk3E"
						. "aj/4lYf8gR7U8QgYd65H/+OnnAxqhLbKCJqJ3i7rW/4FRdpTGGshlroAAAAASUVORK5CYII="; # base64-encoded Icinga 128x80 logo


$logo_type          = undef; # logo image file format (jpg, gif, or png)
$graph_img          = undef; # base64-encoded graph
$graph_type         = undef; # graph image file format (jpg, gif, or png)
$boundary           = undef; # unique string for multi-part emails
%mail;

# $empty_img is a base64-encoded, white 1x1 pixel gif image, we
# use it if the logo or the pnp4nagios graph cannot be found.
$empty_img          = "R0lGODlhAQABAJEAAAAAAP///////wAAACH5BAEAAAIALAAAAAABAAEAAAICTAEAOw==";

# $link_img is base64-encoded image representing a graph, and used as a icon
# to have a clickable link back to Nagiosgraph.
$link_img           = "R0lGODlhFAAQAKIAAMy2vFxaXOTW1MSmnPz29JxKVLR+hKyipCwAAAAAFAAQAAAD"
                       . "eRi63E4QQCFmHcZIBYkkwkcJmTAARdB9aAVQWmUoR12jhVEPxWDzKpBEUEB5MJ4K"
                       . "gRMBFUynp6cTKKwImldv0IQodLYtwJCz2RSDgQmgHhqUn6VqjBlZunJI7x26g5Q0"
                       . "GDk+ZgcAZgBMWENKFBNUQVNCEUoHkA6YDgkAOw==";
$link_type          = "gif";

# ######################################################################################################
# ##################### End of *.config.pl #############################################################
# ######################################################################################################