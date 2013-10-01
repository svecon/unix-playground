#!/bin/sh
# Najdete uzivatele, ktery se nejcasteji prihlasuje na vasi workstation
# pouzijte last

last -n 10000 | cut -d' ' -f1 | sort | uniq -c | sort -n -r

