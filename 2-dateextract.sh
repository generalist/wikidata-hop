# needed files:
# electionlist
# # election-1708	1708-04-30
# dissolutionlist
# # dissolution-1710	1710-09-21
# termlist
# # Q96776409	1708-04-30	1710-09-21
# seatslist
# # CARLISLE	Q3238953

v=`echo 1820-1832`

# set the volume we want to do

rm *report

# clean up

for i in `ls dates/$v` ; do 

counter=`cat dates/$v/$i | wc -l`

# now we open a loop to do one line per constituency-date pair

for j in `seq 1 $counter` ; do

seat=`sed -n "$j"p dates/$v/$i | sed 's/_-_/\t/g' | cut -f 1`

startorig=`sed -n "$j"p dates/$v/$i | sed 's/_-_/\t/g' | cut -f 2 | sed 's/_/ /g'`

start=`sed -n "$j"p dates/$v/$i | sed 's/_-_/\t/g' | cut -f 2 | sed 's/_/ /g' | sed 's/^\([0-9]\{4\}\)$/election-\1/g' | sed 's/\.//g' | sed 's/^\([A-Z]\)/1 \1/g'`

# labels election dates, makes all dates first of the month

endorig=`sed -n "$j"p dates/$v/$i | sed 's/_-_/\t/g' | cut -f 3 | sed 's/_/ /g'`

end=`sed -n "$j"p dates/$v/$i | sed 's/_-_/\t/g' | cut -f 3 | sed 's/_/ /g' | sed 's/^\([0-9]\{4\}\)$/dissolution-\1/g' | sed 's/\.//g' | sed 's/^\([A-Z]\)/1 \1/g'`

# labels dissolution dates, makes all dates first of the month

echo -e $i"\t"$seat"\t"$startorig"\t"$endorig >> $v-original-report
echo -e $i"\t"$seat"\t"$start"\t"$end >> $v-extract-report


done

done

# this gives us all the extracted stuff in a nice and relatively coherent table, and is easy to regen

for a in `cut -f 1 electionlist` ; do 
date=`grep $a electionlist | cut -f 2`
sed -i "s/$a/$date/g" $v-extract-report
done

for b in `cut -f 1 dissolutionlist` ; do 
date=`grep $b dissolutionlist | cut -f 2`
sed -i "s/$b/$date/g" $v-extract-report
done

sed -i "s/1 Dec 1847/2 Dec 1847/g" $v-extract-report

# change election and dissolution dates to the relevant time
# and does a quick check for any 1st Dec 1847 as this is the Problem Day(tm)

# now plug it all into {date}

counter=`cat $v-extract-report | wc -l`

for j in `seq 1 $counter` ; do

person=`sed -n "$j"p $v-extract-report | cut -f 1`
seat=`sed -n "$j"p $v-extract-report | cut -f 2`
start=`sed -n "$j"p $v-extract-report | cut -f 3`
end=`sed -n "$j"p $v-extract-report | cut -f 4`

mpstart=`date +%s --date="$start"`
mpend=`date +%s --date="$end"`

echo -e $person"\t"$seat"\t"$start"\t"$end"\t"$mpstart"\t"$mpend >> $v-dates-report

done

echo "total count -     "`cut -f 1 $v-dates-report | wc -l`
echo "original start -  "`cut -f 3 $v-dates-report | wc -l`
echo "original end -    "`cut -f 4 $v-dates-report | wc -l`
echo "processed start - "`cut -f 5 $v-dates-report | wc -l`
echo "processed end -   "`cut -f 6 $v-dates-report | wc -l`

# now do the processing into date chunks

for term in `cut -f 1 termlist` ; do

start=`grep $term termlist | cut -f 2 `
startdate=`date +%s --date="$start"`
end=`grep $term termlist | cut -f 3 `
enddate=`date +%s --date="$end"`

counter=`cat $v-dates-report | wc -l`

# now we open a loop to do one line per constituency-date pair

for j in `seq 1 $counter` ; do

person=`sed -n "$j"p $v-dates-report | cut -f 1`
seat=`sed -n "$j"p $v-dates-report | cut -f 2`
fullstart=`sed -n "$j"p $v-dates-report | cut -f 3`
fullend=`sed -n "$j"p $v-dates-report | cut -f 4`
mpstart=`sed -n "$j"p $v-dates-report | cut -f 5`
mpend=`sed -n "$j"p $v-dates-report | cut -f 6`


# did they start after our start date
# and if so, did they start before our end date

if [[ "$mpend" -ge "$startdate" ]]; then
  # the MP finished on or after the day the Parliament started
    if [[ "$mpstart" -le "$enddate" ]]; then
  # *and* they began on or before the day the Parliament ended
  # then they're in!
# then 
# if mpend > enddate ; report end
# if mpend < enddate ; report mpend
       if [[ "$mpend" -gt "$enddate" ]]; then
       termend=`echo $end`
       else
       termend=`echo $fullend`
       fi
# if mpstart < startdate ; report start
# if mpstart > startdate ; report mpstart
       if [[ "$mpstart" -lt "$startdate" ]]; then
       termstart=`echo $start`
       else
       termstart=`echo $fullstart`
       fi
### now reprot
echo -e $person"\t"$term"\t"$seat"\t"$termstart"\t"$termend >> $v-terms-report

# if they don't match the first two rules, not reported

fi
fi

done

done

# now transform it into a version suitable for uploading

cp $v-terms-report $v-seats-report

for b in `cut -f 1 seatslist` ; do 
seat=`grep -w $b seatslist | cut -f 2`
sed -i "s/\t$b\t/\t$seat\t/g" $v-seats-report
done


counter=`cat $v-seats-report | wc -l`

for j in `seq 1 $counter` ; do

person=`sed -n "$j"p $v-seats-report | cut -f 1`
term=`sed -n "$j"p $v-seats-report | cut -f 2`
seat=`sed -n "$j"p $v-seats-report | cut -f 3`
start=`sed -n "$j"p $v-seats-report | cut -f 4`
end=`sed -n "$j"p $v-seats-report | cut -f 5`

cleanstart=`date +%Y-%m-%d --date="$start"`
cleanend=`date +%Y-%m-%d --date="$end"`

qid=`grep -w $person memberlist | cut -f 1`

echo -e $qid"\tP39\t"$term"\tP768\t"$seat"\tP580\t+"$cleanstart"T00:00:00Z/11\tP582\t+"$cleanend"T00:00:00Z/11\tS248\tQ7739799\tS1614\t\""$v"/member/"$person"\"" >> $v-upload-report

done
