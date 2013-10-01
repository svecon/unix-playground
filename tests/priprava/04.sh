#!/bin/sh

awk -F: '
BEGIN {
  printf "Zadej jmeno uzivatele: " > "/dev/tty"
}

FILENAME == "/etc/passwd" {
  existuje[$1] = 1
  if ( $3 < 65000 && $3 > max )
    max = $3
  next
}

existuje[$1] {
  printf "Jmeno uz existuje, zvol jine: " > "/dev/tty"
  next
}

{
  printf "jmeno=%s\nuid=%d\n", $1, max+1
  exit
} ' /etc/passwd - 
