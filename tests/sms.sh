#!/bin/sh
smsFile=sms.txt
randLine=$(( $RANDOM % `cat $smsFile | wc -l` ))
cat $smsFile | head -$randLine | tail -1 | mail -s "Milostna SMS" ja@svecon.cz
cat $smsFile | head -$(($randLine - 1)) > /tmp/$smsFile$$
cat $smsFile | tail -n +$(($randLine + 1 )) >> /tmp/$smsFile$$
mv /tmp/$smsFile$$ $smsFile
