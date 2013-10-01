#!/bin/sh

month=${1:-`date +%m`}
year=${2:-`date +%Y`}

days=28
month=$(printf %02d $month)
case $month in
  0[13578]|10|12) days=31;;
  0[469]|11)	    days=30;;
  *)
  if [ `expr $year % 4` -eq 0 ]; then
    days=29
    if [ `expr $year % 400` -eq 0 ]; then
      days=29
    elif [ `expr $year % 100` -eq 0 ]; then
      days=28
    fi
  fi
esac

header=`date -d $year-$month-01 +%B`" "$year
tput cuf $( expr \( 22 - $( echo $header | wc -c ) \) / 2 )
echo $header
echo "Mo Tu We Th Fr Sa Su"

offset=`date -d $year-$month-01 +%u`

i=1
while [ $i -lt $offset ]; do
  echo -n "   "
  i=`expr $i + 1`
done

i=1
while [ $i -le $days ]; do
  position=`expr $i + $offset - 1`
#  test `expr $position % 7` -eq 6 && tput bold
#  test `expr $position % 7` -eq 0 && tput bold
#  test "$year-$month-$i" == "`date +%Y-%m-%-d`" && tput setab 1
  
  if [ $i -lt 10 ]; then
    echo -n " "
  fi
  echo -n $i
#  tput sgr0
  echo -n " "

  if [ `expr $position % 7` -eq 0 ]; then
    echo
  fi
  i=`expr $i + 1`
done

echo; echo
