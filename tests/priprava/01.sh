#!/bin/sh -x

pomocny=/tmp/pomocny.$$
trap 'rm -f $pomocny; exit 1' 2 3 15

ls -la "$1" | {
  echo -n "expr 0" > $pomocny

  while read prava x x x velikost x x x jmeno; do
    [ "$jmeno" = "." -o "$jmeno" = ".." ] && continue

    case $prava in
    [-l]*) echo -n " + $velikost" >> $pomocny;;
    d* ) $0 "$1/$jmeno" $pomocny && continue
         rm -f $pomocny; exit 1;;
    esac
  done
  soucet=`sh $pomocny`
  rm $pomocny
  echo $1:$soucet
  [ -n "$2" ] && echo -n " + $soucet" >> $2
  exit 0
}


