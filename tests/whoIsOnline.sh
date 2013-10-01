#!/bin/sh
for lab in "u2-" "u-pl"; do
for ((i=0;$i-18;i=$i+1)); do
  whoIsOnline=$(ssh $lab$i who | grep "[a-z]" | tr '\n' '\$' | sed '{s/\$/\n        /g}')
  if [ "$whoIsOnline" ]; then
    printf "%s%02d: %s \n" "$lab" "$i" "$whoIsOnline"
  fi
done
done
