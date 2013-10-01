#!/bin/sh

# nahradte abc^4   ---->  pow(abc, 4)
# wget http://kam.mff.cuni.cz/~pasky/polynom.txt

cat polynom.txt | sed -r 's/(\(([a-z0-9+*/ -]+)\)|([a-z0-9]+))\^([0-9])/pow(\1,\4)/g'

# vypiste vsechna URL ktera obsahuje zdrojak homepage cviceni
#wget 'http://pasky.or.cz/vyuka/2013-SWI095/'

cat index.html | grep -Eo 'http://([a-zA-Z0-9-]+\.?)+([/a-zA-Z0-9~.?_=&]+)?'

# Nahradte vsechny // komentare za /* */ komentare
# wget http://kam.mff.cuni.cz/~pasky/board_move.cu

cat board_move.cu | sed -r 's/\/\/(.+)/\/\* \1 \*\//g'

# Smazte s shelloveho scriptu vsechny komentare a nenechavejte prazdne radky

cat 130402_regexp.sh | grep -vE '^(\s+)?#' # neumi mazat tyto komentare


