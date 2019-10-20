#!/bin/sh
################################################################################################
#  gemini query modif from https://github.com/naumenko-sa/cre/blob/master/cre.sh lines 154, 155
################################################################################################
# Full path to the  database file
dbfile=$1
#Query table
table="exome"

#reportdir=/projects/analysis/report
reportdir=/home/erinija/cheo/report

tmpdir=`pwd`/tmp
if [ ! -d ${tmpdir} ]; then
  mkdir  ${tmpdir}
fi

echo "Input dbfile ${dbfile}"
echo "Query table ${table}"
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
## gemini query is needed because gts and gt_ fields
## are written into BLOB that only gemini decodes
################################################################################################

echo "Filter variants add annotations"
   sqlite3 $dbfile < ${reportdir}/exome.sql
#   myopathy"
#   sqlite3 $dbfile < filter-myopathy-variants.sql

echo "Output the variant_id and gene to make joins with burden"
sqlite3 $dbfile ".mode tabs" ".headers on" "select distinct GeneIDv  from ${table};" >${tmpdir}/gv.tmp
grep GeneIDv ${tmpdir}/gv.tmp > ${tmpdir}/vheader.tmp
grep -v GeneIDv ${tmpdir}/gv.tmp | sort -k1,1 > ${tmpdir}/vbody.tmp
cat ${tmpdir}/vheader.tmp ${tmpdir}/vbody.tmp > ${tmpdir}/v.tmp
head -n3 ${tmpdir}/v.tmp


########################################################## This is burden computation start #######################
## Here make the query - genes and genotypes from exome
gemini query --header -q "select t.GeneIDv,(gts).(*) from ${table} t, variants v where t.variant_id=v.variant_id;" $dbfile > ${tmpdir}/b.tmp

head ${tmpdir}/b.tmp

## then create burden columns
# number of columns in b.csv file
n=`head -n1 ${tmpdir}/b.tmp | tr "\t" "\n" | wc -l`
echo $n

#read columns by two
for c in `seq 2 1 ${n}` 
do
 echo $c
 cut -f1,$c ${tmpdir}/b.tmp | grep gts > ${tmpdir}/bheader.tmp
 cut -f1,$c ${tmpdir}/b.tmp | grep -v gts | grep -v "[.]/[.]"| cut -f1 | sort -k1,1 | uniq -c | awk '{print $2 "\t" $1}'  >  ${tmpdir}/bbody.tmp
 cat ${tmpdir}/bheader.tmp ${tmpdir}/bbody.tmp > ${tmpdir}/bc.tmp
head -n2  ${tmpdir}/bc.tmp
wc ${tmpdir}/bc.tmp
# do left join with burden 
join --header -a 1  -1 1 -2 1 ${tmpdir}/v.tmp ${tmpdir}/bc.tmp | tr " " "\t" > ${tmpdir}/intermed.tmp
mv ${tmpdir}/intermed.tmp ${tmpdir}/v.tmp

head ${tmpdir}/v.tmp
done
########################################################## This is burden computation finish #######################

cat ${tmpdir}/v.tmp | uniq | sed 's/gts/burden/g' > burden.csv
head -n3 burden.csv
wc burden.csv
# import burden  to sqlite and join on variant_id field with exome table
sqlite3 $dbfile ".mode tabs" ".headers on" "drop table if exists burden;" ".import burden.csv burden"
# Left join of exome with burden in sqlite, 
# does not work on gemini query 
sqlite3 $dbfile "drop table if exists ${table}b;"
sqlite3 $dbfile "create table ${table}b as select * from ${table} t left join burden b on t.GeneIDv=b.GeneIDv;"

# Clean 
rm -rf ${tmpdir}  burden.csv


echo "Main query table exome" 
gemini query --header -q "select t.*,(gts).(*),(gt_alt_depths).(*),(gt_depths).(*) from ${table}b t, variants v where t.variant_id=v.variant_id" $dbfile | uniq| perl ${reportdir}/columns.pl | grep -v discontinued | sed -e 's/"/""/g' -e 's/^\|$/"/g' -e 's/\t/","/g'  > $dbfile.${table}.csv
# test 
echo "Report two lines"
head -n2 $dbfile.${table}.csv
echo ""

# Clean DB - drop exome and burden table
sqlite3 $dbfile "drop table if exists ${table}b;"
sqlite3 $dbfile "drop table if exists ${table};"
sqlite3 $dbfile "drop table if exists burden;"





