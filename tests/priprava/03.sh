#!/bin/sh

id | tr ' =' '\n\n' | awk -F, '
  /^[a-z]/ { blok = $0; next }
  blok == "groups" {
    for ( i=1; i<=NF; i++ ) {
      pos = index ($i, "(")
      if ( pos > 0)
        print substr($i, 1, pos-1)
      else
        print $i
    }
  }


'
