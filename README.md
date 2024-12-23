# ping_test
Плагин для Nagios 3.5.1 для роутера Keenetic GIGA III с установленной средой entware
Написан на bash для замены плагина check_ping, который не работает из-за отcуствующего модуля /bin/ping 
Требует установки пакетов bash , bc entware - opkg install bash ; opkg install bc

В конфигурационных файлах в /opt/etc/nagios необходимо мделать изменения:

command.cfg:

# 'check-host-alive' command definition
define command{
        command_name    check-host-alive
#        command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w 3000.0,80% -c 5000.0,100% -p 5
         command_line    $USER1$/ping_test.sh -H $HOSTADDRESS$ -w 3000.10,80% -c 5000.10,99% -p 5 
}

# 'check_ping' command definition
define command{
        command_name    check_ping
#        command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p 5
         command_line    $USER1$/ping_test.sh -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p 5
}

# 'ping_test' command definition
define command{
        command_name    ping_test
        command_line    $USER1$/ping_test.sh -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p 5
}


localhost.cfg:

# Define a service to "ping" the local machine

define service{
        use                             local-service         ; Name of service template to use
        host_name                       localhost
        service_description             PING
        check_command                   check_ping!100.0,20%!500.0,60%
        }

далее перезапуск сервиса:

sh /opt/etc/init/S82nagios restart


