#!/bin/sh

# 1] Napiste skript ktery s pravdepodobnosti 50% vypise prvni parameter
# jinak vypise druhy
# treti pravdepodobnost muze byt pravdepodobnost

rnd=$1
if [[ -z $rnd ]]; then
  rnd=50
fi

if [ $(($RANDOM % 100)) -lt $rnd ]; then
  echo prvni
else
  echo druhy
fi

