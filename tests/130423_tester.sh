#!/bin/sh

# Overte na 1000 vzorcich vystupu 130423_random, ze vrati parametry s 50% na 50%

for i in `seq 1000`; do
  ./130423_random.sh # >> /tmp/randomtest$$
done > /tmp/randomtest$$

cat /tmp/randomtest$$ | sort | uniq -c

