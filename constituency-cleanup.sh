# this script is designed to find P39 statements following a HoP upload
# and clean up mistaken constituencies
# "there are two constituencies, which are identified as the same"
# same = P1889 link, and same label (this leaves a few to do by
# "find the one that looks wrong and remove it"


v=`echo 1820-1832`

rm scratch*


curl --header "Accept: text/tab-separated-values" https://query.wikidata.org/sparql?query=SELECT%20DISTINCT%20%3FpositionStatement%20%3Fwrong_seat%0AWHERE%20%7B%0A%20%3Fitem%20p%3AP39%20%3FpositionStatement%20.%20%0A%20%3FpositionStatement%20ps%3AP39%20%3Fterm%20.%20%0A%20%7B%20%3Fterm%20wdt%3AP279%20wd%3AQ16707842%20%7D%20union%20%7B%20%3Fterm%20wdt%3AP279%20wd%3AQ18015642%20%7D%20%0A%20%3FpositionStatement%20pq%3AP768%20%3Fright_seat%20.%20%3FpositionStatement%20pq%3AP768%20%3Fwrong_seat%20.%20%0A%20filter%20%28%20%3Fright_seat%20%21%3D%20%3Fwrong_seat%20%29%20.%0A%20%20%23%20wrong%20seat%20starts%20after%20the%20term%20ends%0A%20%20%7B%20%3Fterm%20wdt%3AP576%20%3Fte%20.%20%3Fwrong_seat%20wdt%3AP571%20%3Fws_start%20.%20filter%20%28%3Fws_start%20%3E%20%3Fte%29%20%7D%0A%20%3Fright_seat%20wdt%3AP1889%20%3Fwrong_seat%20.%0A%20%3Fright_seat%20rdfs%3Alabel%20%3Fname%20.%20%3Fwrong_seat%20rdfs%3Alabel%20%3Fname%20.%20filter%20%28lang%28%3Fname%29%20%3D%20%22en%22%29%20%0A%20%3FpositionStatement%20prov%3AwasDerivedFrom%20%3Fref%20.%20%3Fref%20pr%3AP1614%20%3Frefhop%20.%0A%20%3Fref%20pr%3AP248%20wd%3AQ7739799%20.%20filter%20%28%3Frefhop%20%3D%20%3Fhop%20%29%20.%0A%20%3Fitem%20wdt%3AP1614%20%3Fhop%20.%20FILTER%28STRSTARTS%28%3Fhop%2C%20%22$v%22%29%29.%0A%7D%20order%20by%20desc%28%3Fte%29 > query.tsv

# curl --header "Accept: text/tab-separated-values" https://query.wikidata.org/sparql?query=SELECT%20DISTINCT%20%3FpositionStatement%20%3Fwrong_seat%0AWHERE%20%7B%0A%20%3Fitem%20p%3AP39%20%3FpositionStatement%20.%20%0A%20%3FpositionStatement%20ps%3AP39%20%3Fterm%20.%20%0A%20%7B%20%3Fterm%20wdt%3AP279%20wd%3AQ16707842%20%7D%20union%20%7B%20%3Fterm%20wdt%3AP279%20wd%3AQ18015642%20%7D%20%0A%20%3FpositionStatement%20pq%3AP768%20%3Fright_seat%20.%20%3FpositionStatement%20pq%3AP768%20%3Fwrong_seat%20.%20%0A%20filter%20%28%20%3Fright_seat%20%21%3D%20%3Fwrong_seat%20%29%20.%0A%20%20%23%20wrong%20seat%20starts%20after%20the%20term%20ends%0A%20%20%7B%20%3Fterm%20wdt%3AP576%20%3Fte%20.%20%3Fwrong_seat%20wdt%3AP571%20%3Fws_start%20.%20filter%20%28%3Fws_start%20%3E%20%3Fte%29%20%7D%0A%20%3Fright_seat%20wdt%3AP1889%20%3Fwrong_seat%20.%0A%20%3FpositionStatement%20prov%3AwasDerivedFrom%20%3Fref%20.%20%3Fref%20pr%3AP1614%20%3Frefhop%20.%0A%20%3Fref%20pr%3AP248%20wd%3AQ7739799%20.%20filter%20%28%3Frefhop%20%3D%20%3Fhop%20%29%20.%0A%20%3Fitem%20wdt%3AP1614%20%3Fhop%20.%20FILTER%28STRSTARTS%28%3Fhop%2C%20%22$v%22%29%29.%0A%20SERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%27en%27%20%7D%0A%7D%20order%20by%20desc%28%3Fte%29 > query.tsv

# this is a variant of https://w.wiki/ZFD and may be worth running that beforehand to check all the results look OK. https://w.wiki/ZEr is useful for where the names are not the same - this is the commented-out form

#

cut -f 1 query.tsv | cut -d \/ -f 6 | sed 's/>//g' | sed 's/\(Q[0-9]*\)-/\1\$/g' > scratch1
cut -f 2 query.tsv | cut -d \/ -f 5 | sed 's/>//g' > scratch2

#paste scratch1 scratch2 | grep Q | head -n 10 > scratchlist
paste scratch1 scratch2 | grep Q | head -n 50 > scratchlist

# cut it down to 10 for testing
# otherwise batches of 50

echo "number of lines - " `cut -f 1 scratchlist | wc -l`
echo "number of *unique* lines - " `cut -f 1 scratchlist | sort | uniq | wc -l`

# now we have cleaned up, time to hit the API via wd-cli

counter=`cat scratchlist | wc -l`

for j in `seq 1 $counter` ; do

statement=`sed -n "$j"p scratchlist | cut -f 1`
wrongseat=`sed -n "$j"p scratchlist | cut -f 2`
hash=`wd data --simplify --keep qualifiers,hashes $statement | jq '.qualifiers.P768' | grep -B 1 -A 2 $wrongseat | jq .hash | sed 's/\"//g'`

echo -e $statement"\t"$wrongseat"\t"$hash >> scratchreport
done

# now convert into a suitable format

echo -e "echo '" >> scratchupload

counter=`cat scratchreport | wc -l`
for j in `seq 1 $counter` ; do
statement=`sed -n "$j"p scratchreport | cut -f 1`
hash=`sed -n "$j"p scratchreport | cut -f 3`
echo -e "[ \""$statement"\", \""$hash"\" ]" >> scratchupload
done

echo -e "' | wd rq --batch -s \"constituency cleanup\"" >> scratchupload

# and now upload everything

bash scratchupload
