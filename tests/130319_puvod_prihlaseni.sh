#!/bin/sh
# Ke kazdemu uzivateli prihlasenemu za posledni mesic najdete
# nejcastejsi puvod prihlaseni (tj. 3. sloupecek v last)

# last | sort | uniq -c -s20 -w25

last | tr -s ' ' ';' | cut -d';' -f1,3 | sort | uniq -c | sort -nr

