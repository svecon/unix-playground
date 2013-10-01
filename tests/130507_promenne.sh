#!/bin/sh

var=ahojlala
echo $var
echo ${var%lala}
# <=>
echo $(echo "$var" | sed 's/lala$//' )

echo ${var#o*a}
