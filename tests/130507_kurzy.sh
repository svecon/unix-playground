#!/bin/sh

data=kurzy.txt
mena=${1:-AUD}
min=999999
max=0

#wget "http://www.cnb.cz/cs/financni_trhy/devizovy_trh/kurzy_devizoveho_trhu/rok.txt?rok=2012"

IFS="\n"
sloupec=`cat $data | head -n1 | sed -r "s/$mena.*$//" | sed -r 's/[^|]*//g' | wc -m`

cat $data | tail -n +2 | ( while read line; do

  val=`echo $line | cut -d'|' -f $sloupec | sed 's/,//'`
 
  if [ $val -gt $max ]; then
    max=$val
  fi

  if [ $val -lt $min ]; then
    min=$val
  fi
done

echo $mena: $min \< $max
)
