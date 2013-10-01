#!/bin/sh

# 1] grep.sh REGEX soubor ---- bez pouziti grepu

#sed -n "/$1/p" $2

# 2] dirname

echo '/home/////svecon' | sed -r 's=(.*)/.*=\1=' | sed 's=/*$=='

# 3] basename

echo '/home/////svecon' | sed -r 's=(.*)/(.*)$=\2='
echo '/home/////svecon' | sed 's@.*/@@'

# 4] Napiste one-liner, ktery vam otevre editor vi se vsemi soubory v
# /usr/share/doc/bash*/examples
# ktere obsahuji volani prikazu trap
# (vic parametru => pohyb :n, :prev)

vi `grep -r 'trap' | sed -r 's/:.*//' | sort | uniq `
grep -l 'trap' | xargs vi

# 4*] Zahrajte si adventuru!

# 5] Vypiste hlavicku mailu

cat 'mail.txt' | sed '/^$/q'

# 6] Vypiste telo mailu

cat 'mail.txt' | sed '1,/^$/d'

