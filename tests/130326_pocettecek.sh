#!/bin/sh
# Spoctete pocet tecek v http://kam.mff.cuni.cz/~pasky/lorem.txt

#wget "http://kam.mff.cuni.cz/~pasky/lorem.txt"
file="lorem.txt"
echo $((`cat $file | cut -d: -f5 | wc -c` - `cat $file | cut -d: -f5 | tr -d "." | wc -c`))

cat lorem.txt | tr -cd . | wc -c

