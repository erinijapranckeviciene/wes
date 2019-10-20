#!/bin/sh
################################################################################################
#  gemini query modif from https://github.com/naumenko-sa/cre/blob/master/cre.sh lines 154, 155
################################################################################################
# Full path to the  database file
dbfile=$1
reportdir=/projects/analysis/report
echo "Input dbfile ${dbfile}"
# Query type: exome, myoslice
# Filters for exome: 
#   impact_severity in (HIGH, MED) 
#   cheo_gnomad_af_popmax_without_other less than 0.01 
#   depth of variant coverage is equal or greater than 10
#
# Inprogres:
# Filters for myoslice:
#   impact_severity not in intergenic, intronic,downstream, upstream
#   by myogene ID
#
#################################################################################################
## SQL queries to  create source tables for the report 
## gemini query is needed because gts and gt_ fields are 
## BLOB that gemini decodes
################################################################################################

echo "Filter variants add annotations"
   sqlite3 $dbfile < exome.sql
#   myopathy"
#   sqlite3 $dbfile < filter-myopathy-variants.sql

echo "Query"
#  Query tables
for table in exome
do
echo $table
gemini query --header -q "select t.*,(gts).(*),(gt_alt_depths).(*),(gt_depths).(*) from ${table} t, variants v where t.variant_id=v.variant_id" $dbfile |  uniq | perl ${reportdir}/columns.pl | sed -e 's/"//g' -e 's/^\|$/"/g' -e 's/\t/","/g'  > $dbfile.${table}.csv
# test 
echo "Report two lines"
head -n2 $dbfile.${table}.csv
echo ""
done


# Clean DB - do it in exome.sql
# sqlite3 $dbfile < DROPTABLES.sql

