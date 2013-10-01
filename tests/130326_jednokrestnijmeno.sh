#!/bin/sh
# kolik krestnich jmen ma prave jeden student?

getent passwd | cut -d: -f5 | cut -d" " -f1 | sort | uniq -c | sort -n | grep " 1 " | wc -l

