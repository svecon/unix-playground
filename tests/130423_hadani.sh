#!/bin/sh

# HRA: hadani cisel

trap "echo; echo Nevzdavej to!!!" SIGINT

cislo=$RANDOM

read vstup
while [ ! "$vstup" -eq $cislo ]; do
  if [[ "$vstup" -lt $cislo ]]; then
    echo "Trochu vic"
  else
    echo "Trochu min"
  fi
  read vstup
done

echo "TREFIL SES!!!"



