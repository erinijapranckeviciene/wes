#!/bin/sh
name=$1
# database full name including .db
database=$2
# query genotypes and import the genotypes table to the database  
gemini query --header -q "select variant_id, gts.${name},gt_types.${name}, gt_phases.${name}, gt_depths.${name}, gt_ref_depths.${name}, gt_alt_depths.${name}, gt_quals.${name}, gt_alt_freqs.${name} from variants" ${database}  > gts.csv
sqlite3 ${database} ".mode tabs" ".headers on" "drop table if exists genotypes;" ".import gts.csv genotypes" 
sqlite3 ${database} ".mode tabs" ".headers on" "drop table if exists genelevel;" ".import /projects/Annotations/GeneLevel/omim-orpha-ensg-annotations.csv genelevel"
 
# run sql script that outputs variant annotation table
sqlite3 ${database} < report1.sql > ${name}-report.csv

# Arrange columns properly
