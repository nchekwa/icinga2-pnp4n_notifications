# icinga2-pnp4n_notifications
Icinga2 Notifications Script


<b>Where file should be installed:</b>

	bash# ls -al /etc/icinga2/scripts/
	drwxr-xr-x 2 www-data icingaweb2  4096 lis 20 15:18 lang
	-rwxr-xr-x 1 www-data icingaweb2 30901 lis 20 20:04 pnp4n_send_host_mail.pl
	-rwxr-xr-x 1 www-data icingaweb2 31266 lis 20 20:08 pnp4n_send_service_mail.pl
	drwxr-xr-x 2 www-data icingaweb2  4096 lis 20 19:41 settings
	bash#

<b>How to define NotificationCommand:</b>


	bash# cat  /etc/icinga2/conf.d/notifications.conf
	/** ------------------------------------------------------------------------ **/
	/**
	 * PNP4N Notification
	 * Only applied if host/service objects have the custom attribute `sla` set to `24x7`.
	 **/
	/** ------------------------------------------------------------------------ **/
	
        object NotificationCommand "notify-host-en" {
                import "plugin-notification-command"
        
                command = [ SysconfDir + "/icinga2/scripts/pnp4n_send_host_mail.pl" ]
                arguments = {"-l" = "en" }
                env = {
                        NOTIFICATIONTYPE        = "$notification.type$"
                        NOTIFICATIONAUTHOR      = "$notification.author$"
                        NOTIFICATIONCOMMENT     = "$host.notes$"
                        HOSTNAME                = "$host.name$"
                        HOSTDISPLAYNAME         = "$host.display_name$"
                        HOSTGROUPNAME           = "$host.groups$"
                        HOSTADDRESS             = "$host.address$"
                        HOSTSTATE               = "$host.state$"
                        HOSTOUTPUT              = "$host.output$"
                        LONGDATETIME            = "$icinga.long_date_time$"
                        CONTACTEMAIL            = "$user.email$"
                        CONTACTGROUPMEMBERS     = ""
                        }
        }

        object NotificationCommand "notify-service-en" {
                import "plugin-notification-command"
        
                command = [ SysconfDir + "/icinga2/scripts/pnp4n_send_service_mail.pl"]
                arguments = {"-l" = "en" }
                env =   {
                        NOTIFICATIONTYPE        = "$notification.type$"
                        NOTIFICATIONAUTHOR      = "$notification.author$"
                        NOTIFICATIONCOMMENT     = "$service.notes$"
                        HOSTNAME                = "$host.name$"
                        HOSTDISPLAYNAME         = "$host.display_name$"
                        HOSTGROUPNAME           = "$host.groups$"
                        HOSTADDRESS             = "$host.address$"
                        SERVICEDESC             = "$service.name$"
                        SERVICESTATE            = "$service.state$"
                        SERVICEGROUPNAME        = ""
                        SERVICEOUTPUT           = "$service.output$"
                        LONGDATETIME            = "$icinga.long_date_time$"
                        CONTACTEMAIL            = "$user.email$"
                        CONTACTGROUPMEMBERS     = ""
                        }
        }



<b>After add this settings - when host or service will have sla="24x7 and will belong to group "Icinga Admins" autmaticly will recived emails:</b>

        bash# cat /etc/icinga2/conf.d/users.conf
        /** ------------------------------------------------------------------------ **/
        /** --- Icinga Admins ------------------------------------------------------ **/
        /** ------------------------------------------------------------------------ **/
        object UserGroup "Icinga Admins" {
                display_name = "Icinga 2 Admin Group"
                }
        
        object HostGroup "Icinga Admins" {
                display_name = "UPC Poland Icinga Admins"
                }
        
        apply Notification "Icinga Admins - Host Notification" to Host {
                command = "notify-host-en"
                user_groups = [ "Icinga Admins" ]
                assign where host.vars.sla == "24x7" && "Icinga Admins" in host.groups
                }
        
        apply Notification "Icinga Admins - Service Notification" to Service {
                command = "notify-service-en"
                user_groups = [ "Icinga Admins" ]
                assign where host.vars.sla == "24x7" && "Icinga Admins" in host.groups
                }
        
        --- end ---
        bash#



<b>Exemple host configuration:</b>

        bash# cat /etc/icinga2/hosts/myhost.conf
        object Host "myhost" {
                import "generic-host"
                address                 = "1.1.1.1"
                vars.hardware           = "HP"
                vars.os                 = "Linux"
                vars.snmp_community     = "myROcommunity"
                vars.sla                = "24x7"
        
                /* Define http vhost attributes for service apply rules in `services.conf`. */
                vars.http_vhosts["myhost.domain.com HTTP"] = {
                        http_address    = "myhost.domain.com"
                        http_uri        = "/"
                        http_port       = 80
                        }
        
                vars.http_vhosts["myhost.domain.com HTTPS"] = {
                        http_address    = "imyhost.domain.com"
                        http_uri        = "/"
                        http_port       = 443
                        http_ssl        = "true"
                        }
        
                groups = [ "Icinga Admins" ]
                notes = "Location: Beverly Hills, 90210"
                }

