#!/opt/bin/bash

###############################################################################################
Mypath="/opt/bin/"

Program="ping"
###############################################################################################
# Возвращаемый статус (код результата работы скрипта)
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

# Вспомогательные переменныe

WL=0.00                          # цифровая часть параметра LEVEL_WARNING
WC=0.00                          # цифровая часть параматра LEVEL_CRITICAL
PWL=0                            # цифровая часть параметра % LEVEL_WARNING
PCL=0                            # цифровая часть параметра % LEVEL_CRITICAL
WCparam=0.00                     # значение average из вывода команды ping
                                 # с ним будет сравниваться значение передаваемых параметров
PWCparam=0                       # % loss packets

Crst=0                           # флаг сравнения с критическим значением параметров
Wrst=0                           # флаг сравнения с предупредительным значением параметров
PCrst=0                          # флаг сравнения с критическим значением % потерь
PWrst=0                          # флаг сравнения с предупредительным значением % потерь
Flag=""                          # Для отдадки 4 строки вывода команды ping 
flag=""                          # Управляющий флаг для вывода сообещенй в телеграм бот                          
Site_Name=""                     # Название устройства для вывода статусного сообщения, из /etc/hosts

# PING variables
PING_HOST=""
PING_SOURCE=""
PING_PACKETS=5
PING_TIMEOUT=10
PingOut="_ 0 _"
PING_PrLOSS=0

# Check variables
LEVEL_WARNING=300.10,10%i        # соответствует значению парметра ключа -w по умолчанию
LEVEL_CRITICAL=500.20,40%        # соответствует значению парметра ключа -c по умолчанию
PING_PL=99 # Default value to package lost # соответствует значению парметра ключа -p по умолчанию
PING_AT=0.00 # Default value to averange time # пока не используется - используется аналог WCparam

##########################################################################################
#source /opt/lib/check_ip.sh     #  в случае выноса функции в отдельную библиотеку
##########################################################################################

check_ip() {
  local ip=$PING_HOST
  # Регулярное выражение для проверки формата IPv4
  if [[ $ip =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
    for i in {1..4}; do
      if [[ ${BASH_REMATCH[$i]} -gt 255 || ${BASH_REMATCH[$i]} -lt 0 ]]; then
        echo "Некорректный IP адрес."
        return 1
      fi
    done
#    echo "IP адрес корректен."   #  не загромождать вывод ,  использовать только для отладки
    return 0
  else
    echo "Некорректный формат IP адреса."
    return 1
  fi
}

##########################################################################################
help_usage() {
    echo "Usage:"
        echo " $0 -H (PING_HOST) -w (LEVEL_WARNING) -c (LEVEL_CRITICAL) -p (PING_PACKETS)"
        echo " $0 (-v | --version)"
        echo " $0 (-h | --help)"
    echo "_______________________________________________________" 
 
}
##########################################################################################
help_version() {
    echo "_______________________________________________________"
    echo "ping_test.sh ( это аналог плагина nagios-plugins check_ping ) v. 0.01"
    echo "автор Ptah57 Oziris <ptah57@mail.ru 2024 г. >"
}
##########################################################################################
exit_abnormal() {                         # Функция для выхода в случае ошибки.
  help_version
  help_usage
  exit 2
}
##########################################################################################
check_w_arg() {
# Регулярное выражение
  regex='^[0-9]{1,4}\.[0-9]{1,2},[0-9]{1,2}%+$' 
  if [[ $LEVEL_WARNING =~ $regex ]]; then
     :
#    echo "Строка аргумента параметра -w соответствует шаблону."
  else
    echo "Строка аргумента параметра -w не соответствует шаблону."
    exit_abnormal
  fi
}
##########################################################################################
check_c_arg() {
# Регулярное выражение
  regex='^[0-9]{1,4}\.[0-9]{1,2},[0-9]{1,2}%+$'
  if [[ $LEVEL_CRITICAL =~ $regex ]]; then
     :
#    echo "Строка аргумента параметра -c соответствует шаблону."
  else
    echo "Строка аргумента параметра -c не соответствует шаблону."
    exit_abnormal
  fi
}
##############################################################################################

check_p_arg() {
# Регулярное выражение
  regex='[0-9]'
  if [[ $PING_PACKETS =~ $regex ]]; then
         :
#   echo "Строка аргумента параметра -p соответствует шаблону."
  else
    echo "Строка аргумента параметра -p не соответствует шаблону."
    exit_abnormal
fi
}
#############################################################################################
#  Вывод только для отладки
#################################################################################################
pr_deb_f() {

echo "ping_test.sh $@"
echo "--------------------------------------------------------"
echo "$Flag"
echo "WCparam=$WCparam"
echo "PING_PrLOSS=$PING_PrLOSS"
echo "LEVEL_WARNING = $LEVEL_WARNING"
echo "LEVEL_CRITICAL= $LEVEL_CRITICAL"
echo "WC = $WC"
echo "WL = $WL"
echo "Crst=$Crst"
echo "Wrst=$Wrst"
echo "$flag -> cr_flag_$PING_HOST"
echo "--------------------------------------------------------"
}
##################################################################################################
##############################################################################################
#  Main  проверка есть ли вообще параметры
##############################################################################################
if [[ -z "$1" ]] 
then
        echo "Отсутствуют параметры ! Используется форма: ./`basename $0` < -h или --help> <-v или --version> -H PING_HOST -w (warning,%) -c (critical,%) -p (ping count)"
	help_version
	help_usage
        exit 3
fi
##############################################################################################
if [ "$1" = "-h" -o "$1" = "--help" -o "$1" = "-v" -o "$1" = "--version" ]
then
	help_version
	echo ""
	help_usage
	echo ""
	echo "Используется форма: ./`basename $0` < -h или --help> <-v или --version> -H PING_HOST -w (warning,%) -c (critical,%) -p (ping count)"
	echo ""
	exit 3
fi
##############################################################################################
##############################################################################################
#  Разбор ключей и параметров
##############################################################################################
while getopts "H:w:c:p:" options; do         # Цикл: выбора опций по одной,
               # с использованием silent-проверки
	       # ошибок. Опции -H, -w и -c -p должны
	       # принимать аргументы.
  case "${options}" in    # 
    H)                    # Если это опция H, то установка
      PING_HOST=${OPTARG}                      # $PING_HOST в указанное значение.
      check_ip
      ;;
    w)                                  # Если это опция t, то установка
      LEVEL_WARNING=${OPTARG}           # $LEVEL_WARNING в указанное значение.
      check_w_arg                       # Regex: ожидается совпадение
                                        # только с цифрами.
      ;;
    c)
      LEVEL_CRITICAL=${OPTARG}          # $LEVEL_CRITICAL в указанное значение.
      check_c_arg                       # Regex: ожидается совпадение
                                        # только с цифрами.
      ;;
    p)
      PING_PACKETS=${OPTARG}            # $PING_PACKETS в указанное значение
      check_p_arg

      ;;
    :)                                    # Если ожидаемый аргумент опущен:
      echo "Error: -${OPTARG} здесь требуется параметр ."
      exit_abnormal                       # Ненормальный выход.
      ;;
    *)                                    # Если встретилась неизвестная опция:
      exit_abnormal                       # Ненормальный выход.
      ;;
  esac
  done

#################################################################################################
#  проверяем и выводим результат 
#################################################################################################

if [ -f /storage/cr_flag_$PING_HOST ]; 
   then 
     :
   else
     touch /storage/cr_flag_$PING_HOST 
     chmod 777 /storage/cr_flag_*
     echo "1" > /storage/cr_flag_$PING_HOST 
fi     

WL=$( echo $LEVEL_WARNING  | cut -f1 -d ',')
WC=$( echo $LEVEL_CRITICAL | cut -f1 -d ',')
PWL=$( echo $LEVEL_WARNING  | cut -f2 -d ',' | sed 's/%//g' )
PCL=$( echo $LEVEL_CRITICAL | cut -f2 -d ',' | sed 's/%//g' )
PingOut="$($Mypath$Program -c $PING_PACKETS -4 $PING_HOST)"
Flag=$( echo "$PingOut" | tail -4)
WCparam="$(echo "$PingOut" | grep min/avg/max | cut -f2 -d '=' | cut -f2 -d '/' ) "
PING_PrLOSS="$(echo "$PingOut" | grep -oP '\d+(?=% packet loss)')"
Crst=$( /opt/bin/echo "$WCparam>$WC" | /opt/bin/bc -l )
Wrst=$( echo "$WCparam>$WL" | /opt/bin/bc -l )
PCrst=$( echo "$PING_PrLOSS>$PCL" | /opt/bin/bc -l )
PWrst=$( echo "$PING_PrLOSS>$PWL" | /opt/bin/bc -l )

flag=$(cat /storage/cr_flag_$PING_HOST)

Site_Name="$( grep $PING_HOST /etc/hosts | awk '{print $2}' )"


if [ $Crst -eq 1 ] || [ $PCrst -eq 1 ] 
  then
  echo "SERVICE STATUS: CRITICAL устройство $Site_Name недоступно в сети $PingOut"

  [[ "$flag" = "0" ]] || { /opt/lib/send2tg.sh "$( echo $(date) " SERVICE STATUS: CRITICAL устройство $Site_Name недоступно в сети $PingOut")" ; echo "0" > /storage/cr_flag_$PING_HOST ; } 

  exit $CRITICAL
fi


if [ $Wrst -eq 1 ] || [ $PWrst -eq 1 ]
  then
  echo "SERVICE STATUS: WARNING у устройства $Site_Nam есть проблемы  в сети $PingOut"
  exit $WARNING
fi

echo "OK: устройство ${Site_Name} доступно в сети \n $PingOut"

if [ "$flag" = "0" ]; 
   then
     echo "flag=$flag , cod =$?"
     echo "1" > /storage/cr_flag_$PING_HOST
     echo "файл /storage/cr_flag_$PING_HOST содержит $(cat /storage/cr_flag_$PING_HOST)"
     /opt/lib/send2tg.sh "$( echo $(date) " Ping восстановлен для $Site_Name $PING_HOST" )"
fi
exit $OK

