#!/opt/bin/bash
#===============================================================================
#
#          FILE:  send2tg.sh
# 
#         USAGE:  ./send2tg.sh 
# 
#   DESCRIPTION: Пересылка сообщений в телеграм бот 
# 
#       OPTIONS:  --- send2tg.sh <Message>
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Ptah57 Oziris (), ptah57@yandex.ru
#       COMPANY:  Ra&Pt
#       VERSION:  1.0
#       CREATED:  01/17/2025 03:54:38 PM MSK
#      REVISION:  ---
#===============================================================================
##########################################################################################
#source /opt/lib/check_ip.sh     #  в случае выноса функции в отдельную библиотеку
##########################################################################################
# Раздел переменных - отдадим дань Коболу 8)
##########################################################################################
# Возвращаемый статус (код результата работы скрипта)
##########################################################################################
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3
##########################################################################################
PING_HOST=127.0.0.1                # по умолчанию работаем с локальным сервером
T_K="botTocken"
CH_ID="botChat_ID"
Message=""
##########################################################################################
if [[ -z "$1" ]];
  then
    exit 3
  else
    Message=$1
    curl -X POST https://api.telegram.org/bot$T_K/sendMessage -d chat_id=$CH_ID -d text="$Message"
fi
exit 0
