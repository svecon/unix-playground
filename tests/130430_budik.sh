#!/bin/sh

# budik HH MM
# za HH hodin a MM minut me vzbud
# echo -e '\n', mplayer

while [ -n "$1" ]; do
  case "$1" in
    -a) alert=true;;
    -m) shift;msg=$1;;
    *) break;;
  esac
  shift
done

hh=${1:-0}
mm=${2:-0}
#if [ "$2" = '' ]; then
#  mm=0
#else
#  mm=$2
#fi

echo za $(expr $hh \* 3600 + $mm \* 60) sekund te vzbudim
sleep $(expr $hh \* 3600 + $mm \* 60)

while ${alert:-false}; do
  echo -n ${msg:-"Vzbud se!!!"}
done
