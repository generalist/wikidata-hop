# wikidata-hop

This is a repository for the Wikidata-History of Parliament maintenance script(s).

The main script - `hopscript` - generates a spreadsheet for each individual covered in Wikidata, giving a number of relevant identifiers along with 1-3 History of Parliament URLs.

Daily outputs are available at http://www.generalist.org.uk/wikidata

The `hopcreate` script takes a preformatted TSV file of missing entries and generates a file to upload via QuickStatements 

The `hopsearch` script takes a basic list of missing URLs, guesses names, and tries to find out if they're already in Wikidata
