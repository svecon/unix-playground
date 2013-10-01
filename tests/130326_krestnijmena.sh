#!/bin/sh
# Ktera krestni jmena studentu jsou nejcastejsi?

getent passwd | cut -d: -f5 | cut -d" " -f1 | sort | uniq -c | sort -nr | head
 
