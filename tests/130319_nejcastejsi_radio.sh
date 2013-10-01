#!/bin/sh
# Stahnete si databazi pisnicek hranych na radiu relax
# http://kam.mff.cuni.cz/~pasky/relaxplay.tar.gz 

#URL='http://kam.mff.cuni.cz/~pasky/relaxplay.tar.gz'
#wget $URL

cat radiorelax.txt | sort | cut -d';' -f1 | uniq -c | sort -nr | head

