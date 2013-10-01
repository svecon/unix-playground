#!/bin/sh

# exitcode posledniho prikazu
cp a b || echo Oops:$?

# KULATE ZAVORKY nejsou v sub-shellu
# lokalni promenne, nastaveni adresare
( cd "/tmp" )

# SLOZENE ZAVORKY nejsou v sub-shellu
# chova se to jako prikaz
{ echo "x" ;}

# HRANATE ZAVORKY
# chova se to jako prikaz
# JE TO ALIAS NA PRIKAZ TEST
[  ]

# DVOJITE ZAVORKY
# podobne jako jedna zavorka je to test, ale ma TROCHU jine parametry
[[ ]]

# TESTY: NULA JE TRUE!!!
# JEDNA JE FALSE
# -eq =
# -ne !=
# -lt <
# -gt >
# -le <=
# -ge >=
test 1 -eq 2
echo 1=2:$?

# Stringove porovnavani
test x = y
echo x=y:$?
test x != y
echo x!=y:$?

# FOR CYKLUS
echo for:
for i in a b c; do
  echo $i
done
for i in $(seq 3); do echo $i; done

# WHILE CYKLUS
echo while:
i=1
while [ $i -le 5 ]; do
  echo $i
  i=$(($i + 1))
done

# READ
#IFS=x
#read x y
#echo $x,$y
echo read:
echo ahoj | while read radek; do
  echo $radek
done
