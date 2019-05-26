#!/bin/bash
clear
#-----------------------------------------------------
# VARIABLES
#-----------------------------------------------------
DEBUG=0
ISS_URL="https://issmenuplan.dk/Kundelink?GUID=e39c9499-5e0a-4895-8d4f-4391130e16a2"
PROWL_URL="https://prowl.weks.net/publicapi/add"
PROWL_LINE="
 /usr/bin/timeout --kill-after=15 --signal 9 10     \
 /usr/bin/curl                                      \
 -k ${PROWL_URL}                                    \
 -F priority=2                                      \
 -F application=\"BurgerDetektor\"                  \
 -F apikey=HERE_GOES_YOUR_prowlapp.com_API_KEY" 
#-----------------------------------------------------
# MAIN
#-----------------------------------------------------
cat << "EOF"

 Dette er Burger detektoren for ISS kantinen i Søborg
     (C)opyright Keld Norman, Dubex A/S May 2019
       __
      /
   .-/-.
   |'-'|
   |   |
   |   |   .-""""-.
   \___/  /' .  '. \   \|/\//
         (`-..:...-')  |`""`|
          ;-......-;   |    |
           '------'    \____/

EOF
#---------------------------------------
# READ THE HOMEPAGE
#---------------------------------------
HOMEPAGE_CONTENT="$(/usr/bin/curl \
  -Ss "${ISS_URL}"                \
| sed -e 's%</span>%:%g'          \
| html2text -utf8                 \
| sed -e 's/\[[^][]*\]//g'        \
| grep -v ^$                      \
| grep -v \=)"
#---------------------------------------
# FILL IN MENU / DAY
#---------------------------------------
MAN="$(echo "${HOMEPAGE_CONTENT}"|awk '/:/{i++}i==1')"
TIR="$(echo "${HOMEPAGE_CONTENT}"|awk '/:/{i++}i==2')"
ONS="$(echo "${HOMEPAGE_CONTENT}"|awk '/:/{i++}i==3')"
TOR="$(echo "${HOMEPAGE_CONTENT}"|awk '/:/{i++}i==4')"
FRE="$(echo "${HOMEPAGE_CONTENT}"|awk '/:/{i++}i==5')"
# 
if [ ${DEBUG:-0} -eq 1 ]; then 
 printf "${MAN}\n\n${TIR}\n\n${ONS}\n\n${TOR}\n\n${FRE}\n\n"
fi
#---------------------------------------
# FIND TODAYS DAY AND MENU
#---------------------------------------
DAG_I_TAL=$(/bin/date "+%w")
case ${DAG_I_TAL} in
 1) DAG="Mandag"  ; DAGENS_MENU="${MAN}" ;;
 2) DAG="Tirsdag" ; DAGENS_MENU="${TIR}" ;;
 3) DAG="Onsdag"  ; DAGENS_MENU="${ONS}" ;;
 4) DAG="Torsdag" ; DAGENS_MENU="${TOR}" ;;
 5) DAG="Fredag"  ; DAGENS_MENU="${FRE}" ;;
 *) DAG="Fridag"  ; printf " I dag er det ${DAG}\n\n" ; exit ;;
esac
if [ ${DEBUG:-0} -eq 1 ]; then 
 printf " I dag er det ${DAG}\n\n"
fi
#---------------------------------------
# FIND OUT WHAT THEY SERV TODAY
#---------------------------------------
printf " Vent velingst mens jeg checker om der er burgere på menuen..\n\n $(date)\n"
COUNT_BURGERS="$(echo ${DAGENS_MENU:-Ingen}|grep -c -E 'Burger| burger|hamburger|Hamburger')"
COUNT_FISK="$(echo ${DAGENS_MENU:-Ingen}|grep -c -i -E 'fisk')"
#---------------------------------------
# TEST ALL ALERTS FUNKTION
#---------------------------------------
if [ $# -ne 0 ]; then COUNT_BURGERS=1; COUNT_FISK=1 ; fi
#---------------------------------------
# TEST FOR BURGERS
#---------------------------------------
if [ ${COUNT_BURGERS:-0} -ne 0 ]; then 
 cat << "EOF"
      __________
     /          \
     !    ..__. !
     !    |[__] !
     ! \__||  | !
     !          !
     \__________/
         L_ ! 
        / _)!
       / /__L
 _____/ (____)
        (____)
 _____  (____)
      \_(____)
         \__/   

EOF
#---------------------------------------
# SEND THE BURGER ALERT
#---------------------------------------
 ${PROWL_LINE} -F event="Husk frokosten i dag." -F description="DER ER BURGER I KANTINEN !!! 
 ${ISS_URL}"      > /dev/null 2>&1 
else
 cat << "EOF"
    ______________
   /              \
   ! .  ..___   . !
   ! |\ |[__    | !
   ! | \|[___\__| !
   !              !
   \______________/
         L_ !  ... Der serveres desværre
        / _)!          ikke BURGERE
       / /__L           i kantinen 
 _____/ (____)           i dag !
        (____)
 _____  (____)
      \_(____)
         \__/   

EOF
fi
#---------------------------------------
# SEND AN EXTRA ALERT IF THEY SERV FISH
#---------------------------------------
if [ ${COUNT_FISK:-0} -ne 0 ]; then 
 ${PROWL_LINE} -F event="Advarsel vedrørende frokost" -F description="DET ER FISKE DAG!!!
 ${ISS_URL}"      > /dev/null 2>&1 
fi
#-----------------------------------------------------
# END OF SCRIPT
#-----------------------------------------------------
