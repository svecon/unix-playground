#!/bin/sh
# Spocitejte prumernou delku jmena studenta (na znaky, slova)
# pouzijte getent passwd

Radky=$( getent passwd | cut -d: -f5 | wc -l )
Znaky=$( getent passwd | cut -d: -f5 | wc -c )
expr $Znaky / $Radky

