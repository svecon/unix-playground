#!/bin/sh
# Vypiste skutecna jmena uzivatelu v labu bez mezer (vsechny casti jsou slepeny)

getent passwd | cut -d: -f5 | tr -d " " | tr "\n" " "

