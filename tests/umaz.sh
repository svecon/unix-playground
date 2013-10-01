#!/bin/sh
#cat radky.txt | wc -l
cat radky.txt | tail -n +2 > radky_temp.txt
cp radky_temp.txt radky.txt
#cat radky.txt | wc -l
