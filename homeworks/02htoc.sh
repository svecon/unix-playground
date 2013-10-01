#!/bin/sh

temp=/tmp/svecon_headers_nums$$
list=/tmp/svecon_headers_list$$
echo 0 >> $temp

prevH=0

# najde a vytiskne <H1-H6>
# umaze vsechny parametry
# smaze vsechny tagy uvnitr <H>
cat $1 | sed -n '/<h[1-6][^>]*>/p' | sed "s='[^']*'==" | sed 's="[^"]*"==' | sed -r 's=<([^h/]|/[^h])[^>]*>==g' | while read line; do
  
  # vyselectuje cisty <H>
  pars=`echo "$line" | head -1 | sed -r 's=.*(<h[1-6][^>]*>[^<]*</h[1-6]>).*=\1='`
  # vyselectuje cislo a text
  text=`echo "$pars" | sed -r 's=<h[1-6][^>]*>([^<]*)</h[1-6]>=\1='`
  curr=`echo "$pars" | sed -r 's=<h([1-6]).*=\1='`

  if [ $curr -gt $prevH ]; then
    echo '<ul>' >> $list
    echo $curr >> $temp
  elif [ $curr -eq $prevH ]; then
    echo '</li>' >> $list
  else
    echo '</li>' >> $list

    # uzavira otevrene <ul> tagy
    tac $temp | while read num; do
      if [ $num -gt $curr ]; then
        sed -i '$ d' $temp
	echo '</ul></li>' >> $list
      else
        break
      fi
    done
    
  fi

  echo -n '<li>'$text >> $list
  prevH=$curr
done

# uzavira zbyvajici otevrene <ul> tagy
echo '</li>' >> $list
tac $temp | while read num; do
  if [ $num -gt 0 ]; then
    sed -i '$ d' $temp
    echo '</ul>' >> $list
    if [ `wc -l < $temp` -gt 1 ]; then
      echo '</li>' >> $list
    fi
  else
    break
  fi
done

# nahradi token @TOC@ za soubor s vygenerovanou strukturou
sed "$1" -e "
/^@TOC@/{
  r $list
  d
}
"

rm $temp $list
