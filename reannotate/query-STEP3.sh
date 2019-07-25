#!/bin/sh
################################################################################################
#  gemini query basis from https://github.com/naumenko-sa/cre/blob/master/cre.sh lines 154, 155
################################################################################################
# Full path to the  database file
dbfile=$1
echo "Started with dbfile ${dbfile}"
# Query type: exome, myoslice, myosliceexome
# Filters for exome: 
#   impact_severity in (HIGH, MED) or impact_severity in LOW and Variation is synonymous_variant and either is_coding or is_splicing
#   cheo_gnomad_af_popmax_without_other less than 0.01 or greater than 99.9
#   depth of variant coverage is equal or greater than 10
#
# Filters for myoslice:
#   impact_severity in (HIGH, MED, LOW)
#   cheo_gnomad_af_popmax_without_other less than 0.01 or greater than 99.9
#   depth of variant coverage is equal or greater than 10
#
# Filters for myosliceexome:
#
#   cheo_gnomad_af_popmax_without_other less than 0.01 or greater than 99.9
#
#################################################################################################
## SQL queries to  create required tables
## gemini query is needed because gts and gt_ fields are BLOB that gemini decodes
################################################################################################

echo "Importing SQL tables"
   sqlite3 $dbfile < sql/IDDB.sql
   sqlite3 $dbfile < sql/CREATETABLES.sql
   sqlite3 $dbfile < sql/LOADMYOSLICE.sql

echo "Query"
#  Query tables
for table in exome myoslice
do
echo $table
gemini query --header -q "select t.*,(gts).(*),(gt_alt_depths).(*),(gt_depths).(*) from ${table} t, variants v where t.variant_id=v.variant_id" $dbfile |\
   uniq| perl scripts/columns.pl > $dbfile.${table}.csv
# test 
head -n4 $dbfile.${table}.csv | datamash transpose | cat -n
echo ""
done


# Clean DB
   sqlite3 $dbfile < sql/DROPTABLES.sql


