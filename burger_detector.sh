#!/bin/bash
#-----------------------------------------------------
# Burger detector v2.0 - 2023 update
#-----------------------------------------------------
if tty > /dev/null; then
 clear
fi
#-----------------------------------------------------
# VARIABLES
#-----------------------------------------------------
LANGUAGE="DK"                                         # Define the LANGUAGE ("UK" or "DK")
#LANGUAGE="UK"                                        # Define the LANGUAGE ("UK" or "DK")
URL="https://www.guckenheimer.dk/banner/weekmenu/44"  # URL where the menu is hosted
#-----------------------------------------------------
# Banner for the 1337'ishness
#-----------------------------------------------------
cat << "EOF"

  Burger detektoren for ISS cantina in Søborg DK
       (C)opyleft Keld Norman, May 2019

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
#-----------------------------------------------------
# PROWL
#-----------------------------------------------------
PROWL_URL="https://prowl.weks.net/publicapi/add"
PROWL_LINE="
 /usr/bin/timeout --kill-after=15 --signal 9 10     \
 /usr/bin/curl                                      \
 -k ${PROWL_URL}                                    \
 -F priority=2                                      \
 -F application=\"BurgerDetektor\"                  \
 -F apikey=put-your-prowl-api-key-here-see-install-txt-for-how-to-get-the-free-key"  # Used for push messages to your iPhone (sorry android's I do not have an Android phone)
#-------------------------------------
# CHECK FOR NEEDED UTILS
#-------------------------------------
if [ ! -x /usr/bin/curl ]; then 
 printf "\n ### ERROR - Missing /usr/bin/curl (run apt-get update && apt-get install curl)\n\n"
 exit 1
fi
if [ ! -x /usr/bin/html2text ]; then 
 printf "\n ### ERROR - Missing /usr/bin/html2text (run apt-get update && apt-get install html2text)\n\n"
 exit 1
fi
if [ ! -x /usr/bin/sed ]; then 
 printf "\n ### ERROR - Missing /usr/bin/sed (run apt-get update && apt-get install sed)\n\n"
 exit 1
fi
#-------------------------------------
# GET CURRENT DAY IN SELECTED LANGUAGE
#-------------------------------------
# Get the English day name from the date command
english_day=$(LC_TIME=en_US.UTF-8 date +%A)
if [ "${LANGUAGE}" == "DK" ]; then
 # Define a mapping of English day names to Danish day names
 declare -A danish_days
 danish_days["Monday"]="Mandag"
 danish_days["Tuesday"]="Tirsdag"
 danish_days["Wednesday"]="Onsdag"
 danish_days["Thursday"]="Torsdag"
 danish_days["Friday"]="Fredag"
 danish_days["Saturday"]="Lørdag"
 danish_days["Sunday"]="Søndag"
 # Map the English day name to the Danish day name using the defined mapping
 day="${danish_days[$english_day]}"
else
 day="${english_day}"
fi
#-------------------------------------
# Read the URL HTML into a variable
#-------------------------------------
menu_content=$(/usr/bin/curl -Ss "${URL}" | \
 /usr/bin/sed 's/ - /<br>/g'              | \
 /usr/bin/sed 's/ – /<br>/g'              | \
 /usr/bin/sed -e 's/\ \///g'              | \
 /usr/bin/html2text -utf8                 | \
 /usr/bin/sed "s/\*//g"                   | \
 /usr/bin/sed "s/^[[:space:]]*//"         | \
 egrep -E -v "Velkommen til\!|\[logo]|Ugens menu 35|^DK$|^UK$|^Download ISS Take|^Made fresh in our kitchen|^to-go\!" | \
 /usr/bin/sed -e 's/• //'                                                                      | \
 /usr/bin/sed -e 's/Go Green:/--------------------\nGo Green:\n--------------------\n/'        | \
 /usr/bin/sed -e 's/Comfort Food:/--------------------\nComfort Food\n--------------------\n/' | \
 /usr/bin/sed -e 's/Deli:/--------------------\nDeli:\n--------------------\n/'                | \
 /usr/bin/sed -e 's/( Allergener: Ingen allergener i denne ret )//'                            | \
 /usr/bin/sed -e 's/( Allergens: No allergens in this dish )//'                                | \
 /usr/bin/sed -e 's/Oste bord/\n--------------------\nOste bord:\n--------------------/'       | \
 /usr/bin/sed -E 's/\( Allergener: (.*) \)/\n# Allergener:\1/g'                                | \
 /usr/bin/sed -E 's/\( Allergens: (.*) \)/\n# Allergens:\1/g'                                  | \
 /usr/bin/sed "s/^[[:space:]]*//"                                                     )
#-------------------------------------
# Find the current day's menu
#-------------------------------------
day_index=$(echo "$menu_content" | grep -E -n "^${day^^}$" | cut -d ':' -f 1)
if [ ! -n "$day_index" ]; then
 printf "\n ### ERROR - Day index empty!\n\n"
 exit 1
fi
#-------------------------------------
# Extract the current day's menu section
#-------------------------------------
TODAYS_MENU=$(echo "$menu_content" | sed -n "$((day_index + 1)),$ p" | sed '/^[A-Z]*$/,$d' | grep -v ^# | sed  's/^\(.\)/\U\1/' ) 
if [ ! -n "$TODAYS_MENU" ]; then # No menu in weekends or if the menu is empty
 if [ ${LANGUAGE} == "DK" ]; then 
  echo "Kunne ikke finde \"$day\" i menuen."
 else
  echo "Could not find \"$day\" in the menu."
 fi
 exit 0
fi
#---------------------------------------
# FIND OUT WHAT THEY SERV TODAY
#---------------------------------------
if [ ${LANGUAGE} == "DK" ]; then 
 printf "Vent velingst mens jeg checker om der er burgere på menuen om ${day}en..\n\n"
 COUNT_BURGERS="$(echo ${TODAYS_MENU:-Ingen}|grep -i -v 'hamburgerryg'|grep -c -E 'Burger| burger|hamburger|Hamburger')"
 COUNT_FISK="$(echo ${TODAYS_MENU:-Ingen}|grep -v -i -E 'kål'|grep -c -i -E 'fisk|Aborre|stør|tangål|Belugastør|Berggylte|Bitterling|Blåkæft|Blåstak|Bonito|Brasen|Brisling|Brosme|Brun dværgmalle|Brøding|Båndgrundling|Bækørred|Elritse|malle|Fjeldørred|Fjæsing|Flire|Flynder|Gedde|Glyse|Grundling|knurhane|haj|Gråskalle|Gråtunge|karpe|Guldlaks|ørred|Havbars|Havkarusse|Havkat|Havtaske|Havål|Helleflynder|Helt|Hestemakrel|Hork|Hornfisk|Hvidrokke|Hvilling|Håising|Hårhvarre|Ising|Karusse|ørred|Knude|Kuller|Kulmule|Laks|Lange|ulk|Lerkutling|Lubbe|Løje|Makrel|Multe|Panserulk|haj|Pighvarre|tobiskonge|Pukkellaks|Regnløje|Rimte|Rudskalle|pelamide|knurhane|Rødnæb|Rødspætte|Rødtunge|Sandart|Sandkutling|Savgylte|Sej|Sild|Skalle|Skrubbe|Skægtorsk|Skælkarpe|Slethvar|Solaborre|Somrokke|Sortkutling|kutling|Sortvels|karpe|kutling|Stalling|Stavsild|Stenbider|Sterlet|Stjernestør|tangål|fløjfisk|Strømskalle|Suder|karpe|Sølvkarusse|Sølvlaks|Tangspræl|Torsk|Hudestejle|Tun|Tærbe|Ulk|tunge|Ål|Ålekvabbe|Ørred')"
 ${PROWL_LINE} -F event=" Menu i kantinen ${day}:" -F description="
${TODAYS_MENU}
--------------------
${URL}"      > /dev/null 2>&1
else # TODO: translate this to english
 printf "Please wait for me checking if they serv burgers this ${day}..\n\n"
 COUNT_BURGERS="$(echo ${TODAYS_MENU:-Ingen}|grep -i -v 'hamburgerryg'|grep -c -E 'Burger| burger|hamburger|Hamburger')"
 COUNT_FISK="$(echo ${TODAYS_MENU:-Ingen}|grep -v -i -E 'kål'|grep -c -i -E 'fisk|Aborre|stør|tangål|Belugastør|Berggylte|Bitterling|Blåkæft|Blåstak|Bonito|Brasen|Brisling|Brosme|Brun dværgmalle|Brøding|Båndgrundling|Bækørred|Elritse|malle|Fjeldørred|Fjæsing|Flire|Flynder|Gedde|Glyse|Grundling|knurhane|haj|Gråskalle|Gråtunge|karpe|Guldlaks|ørred|Havbars|Havkarusse|Havkat|Havtaske|Havål|Helleflynder|Helt|Hestemakrel|Hork|Hornfisk|Hvidrokke|Hvilling|Håising|Hårhvarre|Ising|Karusse|ørred|Knude|Kuller|Kulmule|Laks|Lange|ulk|Lerkutling|Lubbe|Løje|Makrel|Multe|Panserulk|haj|Pighvarre|tobiskonge|Pukkellaks|Regnløje|Rimte|Rudskalle|pelamide|knurhane|Rødnæb|Rødspætte|Rødtunge|Sandart|Sandkutling|Savgylte|Sej|Sild|Skalle|Skrubbe|Skægtorsk|Skælkarpe|Slethvar|Solaborre|Somrokke|Sortkutling|kutling|Sortvels|karpe|kutling|Stalling|Stavsild|Stenbider|Sterlet|Stjernestør|tangål|fløjfisk|Strømskalle|Suder|karpe|Sølvkarusse|Sølvlaks|Tangspræl|Torsk|Hudestejle|Tun|Tærbe|Ulk|tunge|Ål|Ålekvabbe|Ørred')"
 ${PROWL_LINE} -F event=" Cantinas Menu ${day}:" -F description="
${TODAYS_MENU}
--------------------
${URL}"      > /dev/null 2>&1
fi
#---------------------------------------
# TEST ALL ALERTS FUNKTION
#---------------------------------------
if [ $# -ne 0 ]; then COUNT_BURGERS=1; COUNT_FISK=1 ; fi
#---------------------------------------
# TEST FOR BURGERS
#---------------------------------------
if [ ${COUNT_BURGERS:-0} -ne 0 ]; then 
 if [ ${LANGUAGE} == "DK" ]; then 
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
${URL}"      > /dev/null 2>&1 
 else
  cat << "EOF"
    ____________
   /            \
   ! .  .._ ._. !
   !  \/ |_ |_  !
   !  /  |_ ._| !
   !            !
   \____________/
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
  ${PROWL_LINE} -F event="Eat lunch today." -F description="THEY SERV BURGERS!!! 
${URL}"      > /dev/null 2>&1 
 fi
else
 if [ ${LANGUAGE} == "DK" ]; then 
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
 else
  cat << "EOF"
     _________
    /         \
    ! .  .._. !
    ! |\ || | !
    ! | \||_| !
    !         !
    \_________/
        L_ !  ... Sorry no BURGERS      
       / _)!       served in the 
      / /__L          cantina     
_____/ (____)          today
       (____)
_____  (____)
     \_(____)
        \__/   

EOF
 fi
fi
if [ ${LANGUAGE} == "DK" ]; then 
 printf "\nDagens menu:\n\n${TODAYS_MENU}\n"|grep -v ^#
else
 printf "\nTodays menu:\n\n${TODAYS_MENU}\n"|grep -v ^#
fi
printf -- "--------------------\n\n"
#---------------------------------------
# SEND AN EXTRA ALERT IF THEY SERV FISH
#---------------------------------------
if [ ${COUNT_FISK:-0} -ne 0 ]; then 
 if [ ${LANGUAGE} == "DK" ]; then 
  ${PROWL_LINE} -F event="Advarsel vedrørende frokost" -F description="DER ER FISKE DAG!!!
${URL}"      > /dev/null 2>&1 
 else
  ${PROWL_LINE} -F event="WARNING about lunch" -F description="THEY SERV FISH TODAY :( !!!
${URL}"      > /dev/null 2>&1 
 fi
fi
#-----------------------------------------------------
# END OF SCRIPT
#-----------------------------------------------------
norman@stepstone:~$ vi /home/norman/bin/burger-detector 
norman@stepstone:~$ cat /home/norman/bin/burger-detector 
#!/bin/bash
if tty > /dev/null; then
 clear
fi
#-----------------------------------------------------
# VARIABLES
#-----------------------------------------------------
LANGUAGE="DK"                                         # Define the LANGUAGE ("UK" or "DK")
#LANGUAGE="UK"                                         # Define the LANGUAGE ("UK" or "DK")
URL="https://www.guckenheimer.dk/banner/weekmenu/44"  # URL where the menu is hosted
#-----------------------------------------------------
# Banner for the 1337'ishness
#-----------------------------------------------------
cat << "EOF"

 Dette er Burger detektoren for ISS kantinen i Søborg
     (C)opyleft Keld Norman, Dubex A/S May 2019

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
#-----------------------------------------------------
# PROWL
#-----------------------------------------------------
PROWL_URL="https://prowl.weks.net/publicapi/add"
PROWL_LINE="
 /usr/bin/timeout --kill-after=15 --signal 9 10     \
 /usr/bin/curl                                      \
 -k ${PROWL_URL}                                    \
 -F priority=2                                      \
 -F application=\"BurgerDetektor\"                  \
 -F apikey=b25b371da5eb28dd927f3502cbe7108c447d57b7" 
#-------------------------------------
# CHECK FOR NEEDED UTILS
#-------------------------------------
if [ ! -x /usr/bin/curl ]; then 
 printf "\n ### ERROR - Missing /usr/bin/curl (run apt-get update && apt-get install curl)\n\n"
 exit 1
fi
if [ ! -x /usr/bin/html2text ]; then 
 printf "\n ### ERROR - Missing /usr/bin/html2text (run apt-get update && apt-get install html2text)\n\n"
 exit 1
fi
if [ ! -x /usr/bin/sed ]; then 
 printf "\n ### ERROR - Missing /usr/bin/sed (run apt-get update && apt-get install sed)\n\n"
 exit 1
fi
#-------------------------------------
# GET CURRENT DAY IN SELECTED LANGUAGE
#-------------------------------------
# Get the English day name from the date command
english_day=$(LC_TIME=en_US.UTF-8 date +%A)
if [ "${LANGUAGE}" == "DK" ]; then
 # Define a mapping of English day names to Danish day names
 declare -A danish_days
 danish_days["Monday"]="Mandag"
 danish_days["Tuesday"]="Tirsdag"
 danish_days["Wednesday"]="Onsdag"
 danish_days["Thursday"]="Torsdag"
 danish_days["Friday"]="Fredag"
 danish_days["Saturday"]="Lørdag"
 danish_days["Sunday"]="Søndag"
 # Map the English day name to the Danish day name using the defined mapping
 day="${danish_days[$english_day]}"
else
 day="${english_day}"
fi
#-------------------------------------
# Read the URL HTML into a variable
#-------------------------------------
menu_content=$(/usr/bin/curl -Ss "${URL}" | \
 /usr/bin/sed 's/ - /<br>/g'              | \
 /usr/bin/sed 's/ – /<br>/g'              | \
 /usr/bin/sed -e 's/\ \///g'              | \
 /usr/bin/html2text -utf8                 | \
 /usr/bin/sed "s/\*//g"                   | \
 /usr/bin/sed "s/^[[:space:]]*//"         | \
 egrep -E -v "Velkommen til\!|\[logo]|Ugens menu 35|^DK$|^UK$|^Download ISS Take|^Made fresh in our kitchen|^to-go\!" | \
 /usr/bin/sed -e 's/• //'                                                                      | \
 /usr/bin/sed -e 's/Go Green:/--------------------\nGo Green:\n--------------------\n/'        | \
 /usr/bin/sed -e 's/Comfort Food:/--------------------\nComfort Food\n--------------------\n/' | \
 /usr/bin/sed -e 's/Deli:/--------------------\nDeli:\n--------------------\n/'                | \
 /usr/bin/sed -e 's/( Allergener: Ingen allergener i denne ret )//'                            | \
 /usr/bin/sed -e 's/( Allergens: No allergens in this dish )//'                                | \
 /usr/bin/sed -e 's/Oste bord/\n--------------------\nOste bord:\n--------------------/'       | \
 /usr/bin/sed -E 's/\( Allergener: (.*) \)/\n# Allergener:\1/g'                                | \
 /usr/bin/sed -E 's/\( Allergens: (.*) \)/\n# Allergens:\1/g'                                  | \
 /usr/bin/sed "s/^[[:space:]]*//"                                                     )
#-------------------------------------
# Find the current day's menu
#-------------------------------------
day_index=$(echo "$menu_content" | grep -E -n "^${day^^}$" | cut -d ':' -f 1)
if [ ! -n "$day_index" ]; then
 printf "\n ### ERROR - Day index empty!\n\n"
 exit 1
fi
#-------------------------------------
# Extract the current day's menu section
#-------------------------------------
TODAYS_MENU=$(echo "$menu_content" | sed -n "$((day_index + 1)),$ p" | sed '/^[A-Z]*$/,$d' | grep -v ^# | sed  's/^\(.\)/\U\1/' ) 
if [ ! -n "$TODAYS_MENU" ]; then # No menu in weekends or if the menu is empty
 if [ ${LANGUAGE} == "DK" ]; then 
  echo "Kunne ikke finde \"$day\" i menuen."
 else
  echo "Could not find \"$day\" in the menu."
 fi
 exit 0
fi
#---------------------------------------
# FIND OUT WHAT THEY SERV TODAY
#---------------------------------------
if [ ${LANGUAGE} == "DK" ]; then 
 printf "Vent velingst mens jeg checker om der er burgere på menuen om ${day}en..\n\n"
 COUNT_BURGERS="$(echo ${TODAYS_MENU:-Ingen}|grep -i -v 'hamburgerryg'|grep -c -E 'Burger| burger|hamburger|Hamburger')"
 COUNT_FISK="$(echo ${TODAYS_MENU:-Ingen}|grep -v -i -E 'kål'|grep -c -i -E 'fisk|Aborre|stør|tangål|Belugastør|Berggylte|Bitterling|Blåkæft|Blåstak|Bonito|Brasen|Brisling|Brosme|Brun dværgmalle|Brøding|Båndgrundling|Bækørred|Elritse|malle|Fjeldørred|Fjæsing|Flire|Flynder|Gedde|Glyse|Grundling|knurhane|haj|Gråskalle|Gråtunge|karpe|Guldlaks|ørred|Havbars|Havkarusse|Havkat|Havtaske|Havål|Helleflynder|Helt|Hestemakrel|Hork|Hornfisk|Hvidrokke|Hvilling|Håising|Hårhvarre|Ising|Karusse|ørred|Knude|Kuller|Kulmule|Laks|Lange|ulk|Lerkutling|Lubbe|Løje|Makrel|Multe|Panserulk|haj|Pighvarre|tobiskonge|Pukkellaks|Regnløje|Rimte|Rudskalle|pelamide|knurhane|Rødspætte|Rødspætte|Rødspætte|Sandart|Sandkutling|Savgylte|Sej|Sild|Skalle|Skrubbe|Skægtorsk|Skælkarpe|Slethvar|Solaborre|Somrokke|Sortkutling|kutling|Sortvels|karpe|kutling|Stalling|Stavsild|Stenbider|Sterlet|Stjernestør|tangål|fløjfisk|Strømskalle|Suder|karpe|Sølvkarusse|Sølvlaks|Tangspræl|Torsk|Hudestejle|Tun|Tærbe|Ulk|tunge|Ål|Ålekvabbe|Ørred|Brosme|Grundling|Fjæsing|Flynder|Glyse|Helleflynder|Hvilling|Håising|Ising|Karusse|Knude|Kulmule|Lerkutling|Lubbe|Løje|Panserulk|Pighvarre|Tobiskonge|Pukkellaks|Regnløje|Rimte|Rudskalle|Pelamide|Rødspætte|Sandart|Sandkutling|Savgylte|Stavsild|Stenbider|Sterlet|Stjernestør|Strømskalle|Sølvkarusse|Sølvlaks|Tangspræl|Torsk|Hudestejle|Tun|Tærbe|Ulk|Ålekvabbe|Ørred')"
 ${PROWL_LINE} -F event=" Menu i kantinen ${day}:" -F description="
${TODAYS_MENU}
--------------------
${URL}"      > /dev/null 2>&1
else # TODO: translate this to english
 printf "Please wait for me checking if they serv burgers this ${day}..\n\n"
 COUNT_BURGERS="$(echo ${TODAYS_MENU:-Ingen}|grep -i -v 'hamburgerryg'|grep -c -E 'Burger| burger|hamburger|Hamburger')"
 COUNT_FISK="$(echo ${TODAYS_MENU:-Ingen}|grep -v -i -E 'kål'|grep -c -i -E 'fish|Perch|sturgeon|lamprey|Beluga sturgeon|Goldsinny wrasse|Bitterling|Blue-mouth|Bluestreak cleaner wrasse|Bonito|Bream|Sprat|Tusk|Common pygmy catfish|Whitefish|Bandfish|Brown trout|European chub|Catfish|Arctic char|Fjord sole|Flounder|Pike|Birchfish|Two-spotted goby|Knobbed wrasse|Shark|Grey mullet|Gray sole|Carp|Golden trout|Sea bass|Rock goby|Dogfish|European conger|Halibut|Herring|Horse mackerel|Whiting pout|Garfish|Gray skate|Hake|Lesser sand eel|Dragonet|Flounder|Sea bream|Cherry salmon|Trout|European bass|Rock goby|Red hake|Twaite shad|Brown trout|Saithe|Herring|Shiner perch|Turbot|Bearded goby|Common blenny|Common roach|False herring|Red mullet|Red gurnard|Red-spotted blenny|Pelamide|Greater weever|Redmouth|European plaice|Turbot|Zander|Two-spotted goby|Gilthead bream|Pollack|Herring|Shiner perch|Flounder|Tench|Stickleback|Sturgeon|Sterlet|Stellate sturgeon|Lamprey|Triggerfish|Spined loach|Allis shad|Silver bream|Silver salmon|Sea stickleback|Cod|Fourspine stickleback|Tuna|Razorbill|Tusk|Common ling|Sole|Eel|Wolf-fish|Flounder|Trout')"
 ${PROWL_LINE} -F event=" Cantinas Menu ${day}:" -F description="
${TODAYS_MENU}
--------------------
${URL}"      > /dev/null 2>&1
fi
#---------------------------------------
# TEST ALL ALERTS FUNKTION
#---------------------------------------
if [ $# -ne 0 ]; then COUNT_BURGERS=1; COUNT_FISK=1 ; fi
#---------------------------------------
# TEST FOR BURGERS
#---------------------------------------
if [ ${COUNT_BURGERS:-0} -ne 0 ]; then 
 if [ ${LANGUAGE} == "DK" ]; then 
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
${URL}"      > /dev/null 2>&1 
 else
  cat << "EOF"
    ____________
   /            \
   ! .  .._ ._. !
   !  \/ |_ |_  !
   !  /  |_ ._| !
   !            !
   \____________/
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
  ${PROWL_LINE} -F event="Eat lunch today." -F description="THEY SERV BURGERS!!! 
${URL}"      > /dev/null 2>&1 
 fi
else
 if [ ${LANGUAGE} == "DK" ]; then 
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
 else
  cat << "EOF"
     _________
    /         \
    ! .  .._. !
    ! |\ || | !
    ! | \||_| !
    !         !
    \_________/
        L_ !  ... Sorry no BURGERS      
       / _)!       served in the 
      / /__L          cantina     
_____/ (____)          today
       (____)
_____  (____)
     \_(____)
        \__/   

EOF
 fi
fi
if [ ${LANGUAGE} == "DK" ]; then 
 printf "\nDagens menu:\n\n${TODAYS_MENU}\n"|grep -v ^#
else
 printf "\nTodays menu:\n\n${TODAYS_MENU}\n"|grep -v ^#
fi
printf -- "--------------------\n\n"
#---------------------------------------
# SEND AN EXTRA ALERT IF THEY SERV FISH
#---------------------------------------
if [ ${COUNT_FISK:-0} -ne 0 ]; then 
 if [ ${LANGUAGE} == "DK" ]; then 
  ${PROWL_LINE} -F event="Advarsel vedrørende frokost" -F description="DER ER FISKE DAG!!!
${URL}"      > /dev/null 2>&1 
 else
  ${PROWL_LINE} -F event="WARNING about lunch" -F description="THEY SERV FISH TODAY :( !!!
${URL}"      > /dev/null 2>&1 
 fi
fi
#-----------------------------------------------------
# END OF SCRIPT
#-----------------------------------------------------
