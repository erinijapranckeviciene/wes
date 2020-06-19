#!/bin/sh
name=$1
vcfgzfile=$2
# database will be name.db
database=${name}.db

# reanotate vcf with vcfanoo
# this is a temporary solution to make an explicit query to extract just genotype information in a uniform way 
vcfanno -p 32 -base-path /projects/bcbio/v1.2.0/genomes/Hsapiens/hg38 /projects/Annotations/vcfanno/gnomad_ge.conf ${vcfgzfile} | sed 's/Number=A/Number=1/g' > ${name}.vcf
#create  db with vcf2db.py 
# since it is only one sample at the moment, create ped file on the fly
echo "" >  ${name}.ped
sed -i '1i#Family_ID\tIndividual_ID\tPaternal_ID\tMaternal_ID\tSex\tPhenotype' ${name}.ped
sed -i '2iFAMILY\tSAMPLE\t-9\t-9\t0\t0' ${name}.ped
cat ${name}.ped | sed "s/FAMILY/${name}_fam/" | sed "s/SAMPLE/${name}/"  > SAMPLE.ped
mv  SAMPLE.ped ${name}.ped
cat ${name}.ped

echo vcf2db.py
vcf2db.py ${name}.vcf ${name}.ped ${name}.db

echo gemini query
# query genotypes and import the genotypes table to the database  
gemini query --header -q "select variant_id, gts.${name},  gt_depths.${name}, gt_ref_depths.${name}, gt_alt_depths.${name}, gt_quals.${name}, gt_alt_freqs.${name} from variants" ${database} | sed "s/\.${name}//g"  > gts.csv

echo import annotations
sqlite3 ${database} ".mode tabs" ".headers on" "drop table if exists genotypes;" ".import gts.csv genotypes" 
sqlite3 ${database} ".mode tabs" ".headers on" "drop table if exists genelevel;" ".import /projects/Annotations/GeneLevel/omim-orpha-ensg-annotations.csv genelevel"

echo consolidate annotations 
# run sql script o consolidate annotations
sqlite3 ${database} < report.sql 
echo generate the report
# Arrange columns properly
sqlite3 ${database} < fields.sql > ${name}-report.csv

echo clean
#Remove tables 
sqlite3 ${database} "drop table if exists genotypes;"  
sqlite3 ${database} "drop table if exists genelevel;" 
