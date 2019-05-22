# burger_detector
Detects if they serv fish or burgers in the local cantina

Place the script somewhere safe on your linux server.

Register for an account on https://prowlapp.com, create an API key and pay the X$ for the prowl app on iTunes and install it on your iPhone.

NB: If you use an android then rewrite the script and use Pushover instead (https://pushover.net)

Then add the API key to the script where it says "HERE_GOES_YOUR_prowlapp.com_API_KEY"

Then "chmod 700 whatever_you_called_your_script"

Add a line to your crontab (crontab -e) so it executes every day (before lunch)

#------------------------------------------------------------------------------
# Cron Syntax: crontab
#------------------------------------------------------------------------------
#
#                * * * * *
#                | | | | |_ Weekly 0-6 (0 Sunday) 
#                | | | |___ Monthly 1-12
#                | | |_____ Day of month 1-31
#                | |_______ Hour 0-23
#                |_________ Minute 0-59
#
#------------------------------------------------------------------------------
0 8 * * * /home/norman/bin/burger-detector >/dev/null 2>&1

And enjoy the notifications that will keep you away from the cantina when they serv fish or ensure you get a "first-row" seat when they serv burgers.

PRE_REQ (I run it on a debian 9.x):
------------------------------------

apt-get install sed curl html2text

POC:
------------------------------------
norman@stepstone:~/bin$ ./burger-detector  

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

 Vent velingst mens jeg checker om der er burgere på menuen..

 Wed 22 May 2019 07:09:22 PM CEST
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

POC WHERE THEY SERV BURGERS:
------------------------------------
norman@stepstone:~/bin$ ./burger-detector test
...
....
 Wed 22 May 2019 07:10:02 PM CEST
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

