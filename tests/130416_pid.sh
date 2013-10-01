#!/bin/sh

#1] Vypiste PID vsech bezicich shellu krome vasich a zkuste je zabit

#ps axu | grep -f '/etc/shells' | grep -v '^sveco' | awk '{ print $2 }' | xargs kill

#2] Vyrobte si v /tmp nekolik souboru .txt a vypiste za sebou jejich vystup

echo 'ASDGGasssss' > /tmp/sveco1.txt
echo 'DfhWcNjhWss' > /tmp/sveco2.txt
find /tmp -name '*.txt' -exec cat {} \;

#2b] V kazdem z nich nahradte vsechna velka pismena malymi

