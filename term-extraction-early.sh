#!/bin/bash

# get all the dates & constituencies for a period
# will ONLY work at the moment for early vols (ie one line per parliament)
# will need to write a newer one for later vols
# nb needs PUP - https://github.com/ericchiang/pup

rm working/*-names

# curl "https://tools.wmflabs.org/wikidata-todo/beacon.php?prop=1614&source=0" | sed 's/||/\t/g' > beacon

for a in `cat volumelist` ; do
rm $a-uploadlist
rm $a-uploadlist-debug

rm dates/$a/*

for i in `ls $a/member | sed 's/.html//g'` ; 
do 
clean=`echo $i | sed 's/%28/(/g' | sed 's/%29/)/g'`
# set tidied name as variable
cat $a/member/$i.html | pup '#member-constituency text{}' | tr '\n' '\t' | sed -E 's/(\t[A-Z][A-Z])/\n\1/g' | sed -E 's/(\t\?[A-Z])/\n\1/g' | sed 's/^\t//g' | sed 's/\t /\t/g' | sed 's/ /_/g' | sed 's/\t_/_/g' |  sed 's/__/_/g' | sed 's/\[_/\[/g' | sed 's/\?_/\?/g' | sed 's/\t[0-9]\t/\t/g' | sed 's/\t$//g' | sed 's/&#39;//g' | grep -v "Constituency" > dates/$a/$clean ; done

# this also deals with spaces (eg Mar. 1414) by underscoring
# and drops those annoying trailing htmls
#?a-z is to catch one or two cases where a const is prefixed with ?
#a few weird cases have [ date] not [date] so this catches them too, or double underscores, or sthg

# crossmatch to Qids


##### now what we want to do is
##### produce a single file
##### with member - term - constituency - reference in QS fmt
##### so! let's go about this

for i in `cat termindex | cut -f 1` ; do grep -wl "$i" dates/$a/* | sed 's/||/\t/g' | sed 's/%28/(/g' | sed 's/%29/)/g' | sed 's/%E2%80%99/’/g' | sed 's/dates\/$a\//$a\/member\//g' | sed 's/.html//g' > working/$a-$i-names ; done


for i in `cat termindex | cut -f 1` ; do
   termqid=`grep -w $i termindex | cut -f 2` 
   counter=`cat working/$a-$i-names | wc -l`
# set some variables
# now open a loop using the counter
# if the file is empty, counter=0, and it skips out
for j in `seq 1 $counter` ; do

   slug=`sed -n "$j"p working/$a-$i-names | cut -d \/ -f 3`
   hopID=`echo -e $a"/member/"$slug`
# this is the slug for the first article in that term
   itemqid="`grep -e "$hopID$" beacon | cut -f 1`"
# this is the item QID
# the $ stops there being multiple entries in the value
# by only matching any lines that have no text after the ID

# this counter fixes things if we have two or more seats in the same term (it happens)
# eg weston-john-1433 - two seats in 1410
   innercounter=`grep -w $i dates/$a/$slug | wc -l`
   for k in `seq 1 $innercounter` ; do
   seat=`grep -w $i dates/$a/$slug | cut -f 1 | sed -n "$k"p | sed 's/?//g'`
# this stops any lead ? from the constituency being used in matching
   seatqid=`grep -w $seat seatlist | cut -f 2`

# now assemble into a line!

echo -e $itemqid"\tP39\t"$termqid"\tP768\t"$seatqid"\tS248\tQ7739799\tS1614\t\""$hopID"\"" >> $a-uploadlist

echo -e $slug"\tP39\t"$i"\tP768\t"$seat"\tS248\tQ7739799\tS1614\t\""$hopID"\"" >> $a-uploadlist-debug

echo volume $a - term $i - item $j - seat $k
     done # close the inner loop (seats)
   done # close the middle loop (people)
done # close the outer loop (periods)
 

done # close the volume loop

exit

###

# cat `ls dates/$a/*` > temp
# cut -f 2 temp |sort | uniq > temp2
# find all the terms used in the date files

# ls working/*-names | sed 's/-names//g' | sed 's/working\///g' > temp3
# find all the terms in indexed name files

# grep -vxf temp3 temp2 | grep -v \? | grep -v "\["
# this traces any which haven't been prepped for upload

# for i in `cat 1500s-dups | cut -f 1` ; do cp `grep -w $i 1500s-dups | cut -f 2` working/dups/$i-v1 ; cp `grep -w $i 1500s-dups | cut -f 3` working/dups/$i-v2 ; diff working/dups/$i-v1 working/dups/$i-v2 -qs >> difflog ; done

# this takes an export of all items found in two vols eg http://tinyurl.com/y963xl3n and does a diff report to see what's up

# looking for gaps at the end?
# cut -f 1,3,5,9 1386-1421-uploadlist | sed 's/\"//g'
# https://query.wikidata.org/#SELECT%20DISTINCT%20%3Fitem%20%20%3Fterm%20%3Fconstituency%20%3Fhop%20%7B%0A%20%3Fitem%20p%3AP39%20%3FpositionStatement%20.%0A%20%3FpositionStatement%20ps%3AP39%20%3Fterm%20.%20%3Fterm%20wdt%3AP279%20wd%3AQ18018860%20.%20%3Fterm%20wdt%3AP571%20%3Fstart%20.%20%0A%20OPTIONAL%20%7B%20%3FpositionStatement%20pq%3AP768%20%3Fconstituency%20.%20%7D%0A%20optional%20%7B%20%3FpositionStatement%20prov%3AwasDerivedFrom%20%3Fref%20.%20%3Fref%20pr%3AP1614%20%3Fhop%20.%20%3Fref%20pr%3AP248%20wd%3AQ7739799%20.%20%7D%0A%20%3Fitem%20wdt%3AP1614%20%3Fhop%20.%20FILTER%28STRSTARTS%28%3Fhop%2C%20%221386%22%29%29.%0A%20SERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%27en%27%20%7D%0A%7D%0AORDER%20BY%20%3Fstart%20%3Fhop
# what we should have, what we got
# sort both files and compare
