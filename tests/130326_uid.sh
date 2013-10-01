#!/bin/sh
# vypiste svoje UID
id | cut -d" " -f1 | tr -cd "[0-9]"
echo; 

# Vypiste svuj LoginShell
id | sed 's/).*/)/' | sed 's/[^\(]*([a-z][a-z]*)[^\)]*/\1/'
getent passwd | grep `whoami` | cut -d: -f1

# vypiste realname uzivatele 44211
getent passwd | cut -d: -f3,5 | grep '44211' | cut -d: -f2

# kolik uzivatelu ma ve jmene znak X
getent passwd | cut -d: -f1 | grep 'x' | wc -l

# kolik uzivatelu ma ve jmene znak X nebo W
getent passwd | cut -d: -f1 | grep '[xw]' | wc -l

# kolik logickych procesoru ma vas pocitac? /proc/cpuinfo
cat /proc/cpuinfo | grep '^processor' | wc -l

# prevedte matematicky vyraz na C-ckovsky
# xy^n    ----->   pow(xy, n)
# (a+b)^(1/2) ----> sqrt(a+b)

#wget 'http://kam.mff.cuni.cz/~pasky/polynom.txt'
cat polynom.txt

