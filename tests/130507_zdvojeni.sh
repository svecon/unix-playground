#!/bin/sh

# Zdvojte vsechny radky na vstupu

echo $* | sed p

exit
IFS="\n"
cat $1 | while read line; do
  echo $line
  echo $line
done

