#!/usr/bin/bash
# Create  tables with annotations from  gene_info.gz and gene2ensemble.gz, omim, orphanet and gnomad_constraint
# Requirements : perl

####################################################################################################
## Part1 - prep to get  scripts
####################################################################################################

# clone comp-bio to use orphanet processing script

if [ ! -d `pwd`/scripts/compbio-toolkit ]; then 
  git clone https://github.com/buske/compbio-toolkit.git 
  mv compbio-toolkit `pwd`/scripts/
fi

####################################################################################################
## Part2 - collect the data, all ; will be converted to , 
####################################################################################################
echo " Source data prep"

if [ ! -d `pwd`/source-data ]; then
  mkdir source-data; cd `pwd`/source-data
else
  cd `pwd`/source-data
fi

WD=`pwd`

## Where your OMIM data files reside
## change 
OMIMD=/projects/Databases/OMIM

#####################################################################################################
## Obtain gene regions BED file from NCBI
#####################################################################################################
## Create bed file with gene coordinates, EntrezID , gene name and description
## This file defines gene regions that will be used to annotate variant by entrez Gene ID
## EntrezID is 4th column, Name is 5th column, description is 6th column
echo " prepare coordinates file, the GFF3 file location is from NCBI OMIM Frequently asked questions:"
echo " https://www.omim.org/help/faq#1_12 "

coordfile=ref_GRCh37.p13_top_level

if [ ! -f ${coordfile}.genecoord.bed.gz ]; then
  if [ ! -f ${coordfile}.gff3.gz ]; then
    wget ftp://ftp.ncbi.nlm.nih.gov//genomes/H_sapiens/ARCHIVE/ANNOTATION_RELEASE.105/GFF/${coordfile}.gff3.gz
  fi
# EXPLORE OFF THE SHELF PROGRAMS FOR GFF3 to BED i.e . gff2bed.pl
  zcat ${coordfile}.gff3.gz | perl ../scripts/gff3toGenesBed.pl | tr ";" "," > ${coordfile}.genecoord.bed
  echo ""
  echo " =======================================================================ref_GRCh37.p13_top_level.gff3 to BED"
  echo ""
  head ${coordfile}.genecoord.bed
  echo ""
  echo ""

  ## if regions directory does not exist
  if [ ! -d ${WD}/../regions ]; then
    mkdir ${WD}/../regions
  fi
  cat ${coordfile}.genecoord.bed | bgzip -c > ${WD}/../regions/${coordfile}.genecoord.bed.gz
  tabix ${WD}/../regions/${coordfile}.genecoord.bed.gz
fi

#####################################################################################################
## Obtain gene2ensemble mapping file
#####################################################################################################
echo "gene2ensembl.tsv"
# Process gene2ensembl 
if [ ! -f gene2ensembl.tsv ]; then
  if [ ! -f gene2ensembl.gz ]; then
    wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2ensembl.gz
  fi
  zcat gene2ensembl.gz | grep ^9606 | cut -f2-7 | sort -k1,1 | uniq > gene2ensembl.tsv
fi 

echo " =======================================================================gene2ensembl.tsv"
echo ""
head gene2ensembl.tsv
echo ""
echo ""

#####################################################################################################
## Obtain gene_info file
#####################################################################################################
echo "gene_info.tsv"
# Process gene_info
if [ ! -f gene_info.tsv ]; then
  if [ ! -f gene_info.gz ]; then
    wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
  fi
  zcat gene_info.gz | grep ^9606 | tr " " _ | cut -f2,3,5,6,9,10  | sort -k1,1 | uniq | tr ";" ","  > gene_info.tsv
fi
 
echo " =======================================================================gene_info.tsv"
echo ""
head gene_info.tsv
echo ""
echo ""

#####################################################################################################
## Obtain gnomad constraint file 
#####################################################################################################
echo "gnomad_constraint.tsv"
# https://github.com/buske/compbio-toolkit.gitProcess gnomad constraint file 
if [ ! -f gnomad_constraint.tsv ]; then

  if [ ! -f gnomad.v2.1.1.lof_metrics.by_gene.txt.gz ]; then
    wget https://storage.googleapis.com/gnomad-public/release/2.1.1/constraint/gnomad.v2.1.1.lof_metrics.by_gene.txt.bgz
    mv gnomad.v2.1.1.lof_metrics.by_gene.txt.bgz gnomad.v2.1.1.lof_metrics.by_gene.txt.gz
  fi
  
  zcat gnomad.v2.1.1.lof_metrics.by_gene.txt.gz | cut -f1,2,5,21,22,23,24,64 | tail -n +2 > gnomad_constraint.tsv

fi
echo " =======================================================================gnomad_constraint.tsv"
echo ""
head gnomad_constraint.tsv
echo ""
echo ""

#####################################################################################################
## Obtain orphanet gene 
#####################################################################################################

echo "orpha.tsv"
if [ ! -f orpha.tsv ]; then
  python3 ${WD}/../scripts/compbio-toolkit/orphanet/get-orphanet-gene-xls.cgi | tail -n +6 | tr " " "_" | tr ";" ","   > orpha.tsv
fi 

echo " =======================================================================orpha.tsv"
echo ""
head "orpha.tsv"
echo ""
echo ""


# if OMIM folder exists
# create sqlite database with identifiers and make queries to create the association table
if [ -d ${OMIMD} ]; then 

##############################################################################mim2gene#########
echo ""
echo ""
echo " =======================================================================mim2gene.txt"
echo ""
  head -n10 ${OMIMD}/mim2gene.txt 
echo ""
echo ""

  cat ${OMIMD}/mim2gene.txt | grep -v ^# | tr " " _  > ${WD}/mim2gene.tsv

echo " =======================================================================mim2gene.tsv"
echo ""
head "mim2gene.tsv"
echo ""
echo ""

##############################################################################genemap2########
echo " =======================================================================genemap2.txt"
echo ""
  head -n10 ${OMIMD}/genemap2.txt 
echo ""
echo ""

  cat ${OMIMD}/genemap2.txt | grep -v ^# | tr " " _ | tr ";" "," > ${WD}/genemap2.tsv

echo " =======================================================================genemap2.tsv"
echo ""
head "genemap2.tsv"
echo ""
echo ""

##############################################################################morbidmap.txt###
echo " =======================================================================morbidmap.txt"
echo ""
  head -n10 ${OMIMD}/morbidmap.txt 

echo ""
echo ""

  cat ${OMIMD}/morbidmap.txt | grep -v ^# | tr " " _ | tr ";" "," > ${WD}/morbidmap.tsv

echo " =======================================================================morbidmap.tsv"
echo ""
head "morbidmap.tsv"
echo ""
echo ""


fi

## if OMIM directory does not exist, then  OMI data will not be in DB
## sql query will create DB to create annotation tables

  sqlite3 IDDB.db < ${WD}/../sql/IDDB.sql

  echo "IDDB.db from source data and OMIM  if exists"

  echo ""
  echo "Source data to create annotation tables:"
  echo ""
  ls -lh

####################################################################################################
## Part3 - create annotation tables in the format that cheop.lua understands
##         The format may change if https://www.genenames.org/help/rest/ will  be incorporated to
##         harmonize identifiers
####################################################################################################

echo ""
echo "Create annotation tables by executing queries from the IDDB:"
echo ""

  
if [ ! -d ${WD}/../annotation-tables ]; then 
  mkdir ${WD}/../annotation-tables
fi

sqlite3 ${WD}/IDDB.db ".headers off" ".mode tabs" "select mg.entrezid, mg.mimnumber, mg.symbol, mg.ensg, mm.genesymbols,g.genename,g.phenotype  from morbidmap mm,\
                             mim2gene mg, genemap2 g where(mm.mimnumber=mg.mimnumber) and (mg.mimnumber=g.mimnumber) and mg.entrezid in\
                              (select distinct entrezid from gene_bed);" "" | sort -k1,1 | \
                             awk '{print $1 "\t" "=\"MIM:"$2"|SYM:"$3"|ENSG:"$4"|MMGSYM:"$5"|GNAME:"$6"|GPHEN:"$7"\""}' | uniq | \
                             tr "," "@" | datamash -g 1 unique 2 | sed 's/,=/\/\//g' | tr "@" "," | tr -d "\t" > ${WD}/../annotation-tables/OmimTable
echo ""
echo " =======================================================================OmimTable"
echo ""
head  ${WD}/../annotation-tables/OmimTable
echo ""
echo ""


sqlite3 ${WD}/IDDB.db ".headers off" ".mode tabs" "select b.entrezid, o.orpha_id, o.symbol, o.disorder, o.assocstatus, o.altids  from orpha o,\
                             gene_bed b where o.symbol in (select distinct s.symbol from gene_bed s) and o.symbol=b.symbol; " "" | sort -k1,1 | \
                             awk '{print $1 "\t" "=\"ORPHA:"$2"|SYM:"$3"|DISORD:"$4"|ASSOC:"$5"|ALTIDS:"$6"\""}' | uniq | \
                             tr "," "@" | datamash -g 1 unique 2 | sed 's/,=/\/\//g' | tr "@" "," | tr -d "\t"  >${WD}/../annotation-tables/OrphaTable

echo ""
echo " =======================================================================OrphaTable"
echo ""
head  ${WD}/../annotation-tables/OrphaTable
echo ""
echo ""


sqlite3 ${WD}/IDDB.db ".headers off" ".mode tabs" "select b.entrezid, o.symbol, o.oe_lof, o.oe_mis, o.pLI, o.pNull, o.pRec, o.enst, o.ensg  from gnomad_constraint o,\
                             gene_bed b where o.symbol in (select distinct s.symbol from gene_bed s) and o.symbol=b.symbol; " "" | sort -k1,1 | \
                             awk '{print $1 "\t" "=\"SYM:"$2"|OE_LOF:"$3"|OE_MIS:"$4"|PLI:"$5"|PNUL:"$6"|PREC:"$7"|ENST:"$8"|ENSG:"$9"\""}' | uniq | \
                             tr "," "@" | datamash -g 1 unique 2 | sed 's/,=/\/\//g' | tr "@" "," | tr -d "\t"  > ${WD}/../annotation-tables/GnomadLofTable

echo ""
echo " =======================================================================GnomadLofTable"
echo ""
head ${WD}/../annotation-tables/GnomadLofTable
echo ""
echo ""

echo ""
echo " =======================================================================MODIFY cheop.lua and cheop.conf - change pwd to the real path"
echo ""

## return back from the source data
cd ..
## Change the absolute paths in cheop. to the current

changepwd=`pwd | sed "s/\//-SLASH-/g"`
cat cheop.lua | sed -e "s/pwd/${changepwd}/" | sed "s/-SLASH-/\//g" > cheop.lua.tmp
mv cheop.lua cheop.lua.1
mv cheop.lua.tmp cheop.lua

cat cheop.conf | sed -e "s/pwd/${changepwd}/" | sed "s/-SLASH-/\//g" > cheop.conf.tmp
mv cheop.conf cheop.conf.1
mv cheop.conf.tmp cheop.conf


