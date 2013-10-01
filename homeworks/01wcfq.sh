#!/bin/sh
# Napiste skript, ktery na standardnim vstupu dostane nejaky cesky nebo anglicky text se slovy oddelenymi mezerami a obsahujici interpunkcni znamenka "." a "," (idealni text je napriklad (pravda latinske) Lorem ipsum). Vypiste deset nejcasteji se vyskytujicich slov (hint: tr(1) s \n) a spoctete (celkovy ci jednotlivy) percentualni podil techto slov na celkovem poctu slov v souboru (zkuste si z poctu slov vygenerovat automaticky aritmeticky vyraz a bc(1); procvicime jeste asi na pristim cviceni).

#wget 'http://pasky.or.cz/vyuka/2013-SWI095/lorem.txt'

Lorem=~/domaciulohy/lorem.txt
File=/tmp/svecon_wcfq$$
Pocty=/tmp/svecon_wcfq_pocty$$
Slova=/tmp/svecon_wcfq_slova$$
Procenta=/tmp/svecon_wcfq_procenta$$

cat $Lorem | tr 'A-Z' 'a-z' | tr -d '.,' | tr ' ' '\n' | tr -s '\n' | sort | uniq -c | sort -rn | tr -s ' ' > $File

cat $File | cut -d' ' -f2 > $Pocty
cat $File | cut -d' ' -f3 > $Slova
cat $Pocty | sed 's/^/scale=3;/' | sed -e "s/$/\*100\/`cat $File | wc -l`/" | bc | sed 's/$/%/' > $Procenta

paste $Slova $Procenta | head -10
#cat $File | wc -l

rm $File; rm $Pocty; rm $Slova; rm $Procenta
