#!/usr/bin/bash

# Use gencode19 and refseq release 105 gene annotations 
# to create merged identifier file and to LEFT JOIN this
# merged file with gene level annotations from gene_history
# gnomad, orpha  and  omim
# 
# We know that VEP GRCh37.p13 v97 uses merged identifiers from RefSeq Release 105
# and Gencode GRCh37 v19. The gene and CDS contain names and identifiers that we need.  
# We also need to annotate by discontinued and changed


####################################################################################################
## LOCAL files locations
## OMIM and ENSBIOMART download 
## Modify paths as needed
## Some example data will be cloned with the archive
####################################################################################################

OMIMD=`pwd`/static/DB/OMIM
echo "OMIMD $OMIMD"
ENSBIOMARTD=`pwd`/static/DB/GRCh37-v97-ensembl-biomart
echo "ENSBIOMARTD $ENSBIOMARTD"


####################################################################################################
## Part1 
## get script for ORPHANET data prep if needed
## get bedops tools if not exist 
####################################################################################################

# clone comp-bio to use orphanet processing script

if [ ! -d `pwd`/scripts/compbio-toolkit ]; then 
  git clone https://github.com/buske/compbio-toolkit.git 
  mv compbio-toolkit `pwd`/scripts/
fi

# get bedops if not exist
if [ ! -d `pwd`/scripts/bedops ]; then 
   wget https://github.com/bedops/bedops/releases/download/v2.4.36/bedops_linux_x86_64-v2.4.36.tar.bz2
   tar jxvf bedops_linux_x86_64-v2.4.36.tar.bz2
   mv bin `pwd`/scripts/bedops
   rm bedops_linux_x86_64-v2.4.36.tar.bz2
      
fi
# export path to be able to use scripts once
export PATH=`pwd`/scripts/bedops:$PATH
echo $PATH

####################################################################################################
## Part2 - download or read sources into source-data
##         all spaces transform to _ , columns separator TAB
####################################################################################################
echo " Source data to source-data dir "

if [ ! -d `pwd`/source-data ]; then
  mkdir source-data; cd `pwd`/source-data
else
  cd `pwd`/source-data
  rm *
fi

## Working directory 
WD=`pwd`

#####################################################################################################
## GENCODE GRCh37.p13  gene annotations  https://www.gencodegenes.org/human/release_19.html
## RefSeq GRCh37.p13 RELEASE 105 annotations ftp://ftp.ncbi.nlm.nih.gov//genomes/H_sapiens/ARCHIVE
#####################################################################################################
## read in a GFF3 table
wget ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gff3.gz
wget ftp://ftp.ncbi.nlm.nih.gov//genomes/H_sapiens/ARCHIVE/ANNOTATION_RELEASE.105/GFF/ref_GRCh37.p13_top_level.gff3.gz
gunzip *.gz


## Process annotation files  with bedops
`pwd`/../scripts/bedops/gff2bed < ref_GRCh37.p13_top_level.gff3 > refseq37release105.bed
`pwd`/../scripts/bedops/gff2bed < gencode.v19.annotation.gff3 > gencode19.bed

## create merged identifier file of refseq and gencode 
## extract data from  Refseq gene
cat refseq37release105.bed | tr " " _ | grep [[:space:]]gene[[:space:]] | awk '{print $10}' | sed 's/Name=/\t/' | sed 's/GeneID:/\t/' | cut -f2,3 |  sed 's/;.*\t/\t/' | tr "," "\t" | tr ";" "\t" | cut -f1,2 | sort -k1,1 | uniq | sort -k2,2n > tr1
## extract data from RefSeq CDS
cat refseq37release105.bed | tr " " _ | grep [[:space:]]CDS[[:space:]] | awk '{print $10}' | sed 's/GeneID:/\t/' | cut -f2 |  sed 's/,Genbank.*gene=/\t/' | tr "," "\t" | tr ";" "\t" | awk '{print $2 "\t" $1}' | sort -k2,2n | uniq  > tr2
## merge
cat tr1 tr2 | sort -k1,1 | uniq > refseq37release105ids.tsv

## extract data from GENCODE GRCh37 v19 gene
cat gencode19.bed | tr " " _ | grep [[:space:]]gene[[:space:]] | cut -f4,10 | sed 's/ID=.*gene_name=//'|  tr ";" "\t" | tr "," "\t" | cut -f1,2 | sed 's/[.][0-9].*\t/\t/' | sort -k2,2 | awk '{print $2 "\t" $1}' > tr1
## extract data from GENCODE GRCh37 v19 CDS
cat gencode19.bed | tr " " _ | grep [[:space:]]CDS[[:space:]] | cut -f10 | sed 's/^.*gene_id=//' | sed 's/[.].*gene_name=/\t/'|  tr ";" "\t" | tr "," "\t" |  awk '{print $2 "\t" $1}' | sort -k1,1 | uniq  > tr2
cat tr1 tr2 | sort -k1,1 | uniq > gencode19ids.tsv


cat refseq37release105ids.tsv gencode19ids.tsv | grep -v HGNC | grep -v exception | grep -v MIM | grep -v ENSGR | sort -k1,1 > refseq_gencode_merged.tsv
sed -i '1i\symbol\tgeneid' refseq_gencode_merged.tsv
## rm the intermediate files
rm tr1 tr2


echo " =======================================================================merged GRCh37.p13 RefSeq RELEASE 105 and GENCODE 19 identifiers"
echo ""
head -n20 refseq_gencode_merged.tsv
echo ""
tail -n20 refseq_gencode_merged.tsv
echo ""

#####################################################################################################
## Gene history changed and discontinued gene identifiers from ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/
#####################################################################################################
## 
wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_history.gz
zcat gene_history.gz | grep ^9606 | cut -f2-5 > hs_gene_history.tsv 
sed -i '1i\GeneID\tDiscontinued_GeneID\tDiscontinued_Symbol\tDiscontinue_Date' hs_gene_history.tsv

echo " =======================================================================Discontinued genes gene_history"
echo ""
head -n10 hs_gene_history.tsv
echo ""


#####################################################################################################
## Full HUGO data set for gene names 
#####################################################################################################
## 

echo "HUGO gene names complete set https://www.genenames.org/download/statistics-and-files/"
wget ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt

## make it into tsv
cat hgnc_complete_set.txt | tr " " _  >  hgnc.tsv

echo " =======================================================================GRCh37.p13.gff3.tsv"
echo ""
head -n4 hgnc.tsv
echo ""


#####################################################################################################
## Gene regions for GRCh37.p13 from NCBI
#####################################################################################################
## read in a GFF3 table

echo " GRCh37.p13 Coordinates GFF3 file from NCBI OMIM Frequently asked questions https://www.omim.org/help/faq#1_12"
echo  "ftp://ftp.ncbi.nlm.nih.gov//genomes/H_sapiens/ARCHIVE/ANNOTATION_RELEASE.105/GFF/ref_GRCh37.p13_top_level.gff3.gz"

#wget ftp://ftp.ncbi.nlm.nih.gov//genomes/H_sapiens/ARCHIVE/ANNOTATION_RELEASE.105/GFF/ref_GRCh37.p13_top_level.gff3.gz

## add gff3 header and make it into tsv
#zcat ref_GRCh37.p13_top_level.gff3.gz | grep -v ^# | awk '{if(NR==1){$0="seqid\tsource\ttype\tstart\tend\tscore\tstrand\tphase\tattributes\n"$0; print $0}; if(NR!=1){print $0}}' > GRCh37.p13.gff3.tsv
cat ref_GRCh37.p13_top_level.gff3 | grep -v ^# | awk '{if(NR==1){$0="seqid\tsource\ttype\tstart\tend\tscore\tstrand\tphase\tattributes\n"$0; print $0}; if(NR!=1){print $0}}' > GRCh37.p13.gff3.tsv

## gff3 header

echo " =======================================================================GRCh37.p13.gff3.tsv"
echo ""
head -n4 GRCh37.p13.gff3.tsv
echo ""

## make miminal subset 
cat GRCh37.p13.gff3.tsv | awk '{if ($3=="gene") print $9}' | sed 's/;Note.*;Dbxref/;Dbxref/' | cut -f5 | tr ";" "\t" | cut -f1-3 | tr "," "\t" | cut -f1-3 | sed 's/ID=//' | sed 's/Name=//' | sed 's/Dbxref=GeneID://' > grch37.trunc.tsv
sed -i '1 i\geneno\tsymbol\tentrez_id' grch37.trunc.tsv

echo " =======================================================================GRCh37.p13.gff3 truncated"
echo ""
head -n4 grch37.trunc.tsv
echo ""



#####################################################################################################
## Gnomad constraint file 
#####################################################################################################
# https://github.com/buske/compbio-toolkit.gitProcess gnomad constraint file 

wget https://storage.googleapis.com/gnomad-public/release/2.1.1/constraint/gnomad.v2.1.1.lof_metrics.by_gene.txt.bgz
mv gnomad.v2.1.1.lof_metrics.by_gene.txt.bgz gnomad.v2.1.1.lof_metrics.by_gene.txt.gz

## make it into tsv - all columns
zcat gnomad.v2.1.1.lof_metrics.by_gene.txt.gz | tr " " _ > gnomad_constraint.tsv

echo " =======================================================================gnomad_constraint.tsv"
echo ""
head -n4 gnomad_constraint.tsv
echo ""
echo ""


#####################################################################################################
## Obtain orphanet gene table 
#####################################################################################################
python3 ${WD}/../scripts/compbio-toolkit/orphanet/get-orphanet-gene-xls.cgi | tail -n +5 | tr " " "_" | tr ";" ","  |   sed 's/P12081.*antigen/P12081,J_antigen/g'  > orpha.tsv

echo " =======================================================================orpha.tsv"
echo ""
head -n4 orpha.tsv
echo ""

#####################################################################################################
## OMIM data files
#####################################################################################################
#OMIMD=/projects/DB/OMIM
## OMIM files location
## OMIM 2019 has  mim2gene.txt, genemap2.txt,  morbidmap.txt , mimTitles.txt


# if OMIM folder exists clean files to import to sqlite3
if [ -d ${OMIMD} ]; then 

##############################################################################mim2gene#########
cat ${OMIMD}/mim2gene.txt | sed 's/^# MIM Number/MIM Number/' |  grep -v ^# | tr " " _  > mim2gene.tsv

echo " =======================================================================mim2gene.tsv"
echo ""
head -n4 mim2gene.tsv
echo ""

##############################################################################genemap2########
cat ${OMIMD}/genemap2.txt |  sed 's/^# Chromosome/Chromosome/' | grep -v ^# | tr " " _ | tr ";" "," | sed '$d' > genemap2.tsv

echo " =======================================================================genemap2.tsv"
echo ""
head -n4 genemap2.tsv
echo "tail"
tail -n4 genemap2.tsv
echo ""

##############################################################################morbidmap.txt###
cat ${OMIMD}/morbidmap.txt | sed 's/^# Phenotype/Phenotype/' | grep -v ^# | tr " " _ | tr ";" "," | sed '$d' | sed '$d' > morbidmap.tsv

echo " =======================================================================morbidmap.tsv"
echo ""
head -n4 morbidmap.tsv
echo "tail"
tail -n4 morbidmap.tsv
echo ""

##############################################################################mimTitles.txt###
cat ${OMIMD}/mimTitles.txt | sed 's/^# Prefix/Prefix/' | grep -v ^# | tr " " _ | tr ";" "," > mimTitles.tsv

echo " =======================================================================mimTitles.tsv"
echo ""
head -n4 mimTitles.tsv
echo ""

fi

#####################################################################################################
## Full HPO disease-gene-phenotype table from charite
#####################################################################################################
## read in HPO association table

echo "HPO all frequencies all sources HPO http://compbio.charite.de/jenkins/job/hpo.annotations.monthly/lastStableBuild/artifact/annotation/ALL_SOURCES_ALL_FREQUENCIES_diseases_to_genes_to_phenotypes.txt"
wget http://compbio.charite.de/jenkins/job/hpo.annotations.monthly/lastStableBuild/artifact/annotation/ALL_SOURCES_ALL_FREQUENCIES_diseases_to_genes_to_phenotypes.txt

## change the header 
cat ALL_SOURCES_ALL_FREQUENCIES_diseases_to_genes_to_phenotypes.txt |tr -d "#" | sed 's/<tab>/\t/g' | tr " " _  >  hpo.tsv

echo " =======================================================================hpo.tsv"
echo ""
head -n4 hpo.tsv
echo ""

#####################################################################################################
## Obtain gene2ensemble mapping file
#####################################################################################################
echo "gene2ensembl.tsv"
# Process gene2ensembl 
    wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2ensembl.gz
    zcat gene2ensembl.gz | grep ^9606 | cut -f2-7 | sort -k1,1 | uniq > gene2ensembl.tsv
# Add header 
    sed -i '1 i\GeneID\tEnsembl_gene_identifier\tRNA_nucleotide_accession\tEnsembl_rna_identifier\tprotein_accession\tEnsembl_protein_identifier' gene2ensembl.tsv     

echo " =======================================================================gene2ensembl.tsv"
echo ""
head gene2ensembl.tsv
echo ""


#####################################################################################################
## Obtain gene_info file
#####################################################################################################
echo "gene_info.tsv"
# Process gene_info
  wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
  zcat gene_info.gz | grep ^9606 | tr " " _ | cut -f2,3,5,6,9,10,11,13,14,15  | sort -k1,1 | uniq | tr ";" ","  > gene_info.tsv
  sed -i '1 i\GeneID\tSymbol\tSynonyms\tdbXrefs\tdescription\ttype_of_gene\tSymbol_from_nomenclature_authority\tNomenclature_status\tOther_designations\tModification_date' gene_info.tsv
 
echo " =======================================================================gene_info.tsv"
echo ""
head gene_info.tsv
echo ""
echo ""

#####################################################################################################
## OMIM data files
#####################################################################################################
#ENSBIOMARTD=/projects/DB/GRCh37-v97-ensembl-biomart

## Ensembl biomart files location
## September 2019  download
## Stable link : http://grch37.ensembl.org/biomart/martview/7cc764372a19cf10b4ccf750a01a8c02
## TO DO: Implement download through API 

# if Ensembl BIOMART folder exists, prep files to import to sqlite3
if [ -d ${ENSBIOMARTD} ]; then 

##############################################################################mim2gene#########
zcat ${ENSBIOMARTD}/mart_export.txt.gz | tr " " _  > mart.tsv

echo " =======================================================================mart.tsv"
echo ""
head -n4 mart.tsv
echo ""
fi



####################################################################################################
## Part3 - make SQLITE3 database of all identifiers
##         Import tsv using command line
##         Time stamp source data and IDDB.db
##         This database will ten be used to create links to gene level annotations
####################################################################################################

if [ -f IDDB.db ]; then
  rm IDDB.db
fi

sqlite3 IDDB.db ".mode tabs" ".import hgnc.tsv hgnc" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import GRCh37.p13.gff3.tsv grch37" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import gnomad_constraint.tsv gnomadconstr" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import orpha.tsv orpha" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import mim2gene.tsv mim2gene" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import genemap2.tsv genemap2" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import morbidmap.tsv morbidmap" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import mimTitles.tsv mimTitles" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import hpo.tsv hpo" ".exit"

sqlite3 IDDB.db ".mode tabs" ".import gene2ensembl.tsv gene2ensembl" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import gene_info.tsv geneinfo" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import mart.tsv ensbiomart" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import grch37.trunc.tsv grch37min" ".exit"

sqlite3 IDDB.db ".mode tabs" ".import hs_gene_history.tsv genehistory" ".exit"
sqlite3 IDDB.db ".mode tabs" ".import refseq_gencode_merged.tsv merged" ".exit"


  echo ""
  echo "Tables in IDDB.db: "
  echo ""

sqlite3 IDDB.db ".tables" ".exit"

  echo ""
  echo "Proceeding with clean-tables.sql "
  echo "Computing within the  IDDB.db: "
  echo ""

sqlite3 IDDB.db < ../sql/clean-tables.sql

  echo ""
  echo "Proceeding with gene names.sql "
  echo "Computing within the  IDDB.db "
  echo "This may take up to 20-25 minutes "
  echo ""

sqlite3 IDDB.db < ../sql/gene-names.sql


mv IDDB.db ../
cd ../

  echo ""
  echo " Creating gene level annotation tables "
  echo " by querying tables from IDDB.db and "
  echo " saving them in annotations directory"
  echo ""


if [ ! -d `pwd`/annotations ]; then
  mkdir annotations
fi

sqlite3 IDDB.db ".mode tabs" ".headers on" ".output annotations/history.csv" "select * from history;" ".exit"
sqlite3 IDDB.db ".mode tabs" ".headers on" ".output annotations/omimannot.csv" "select * from omimannot;" ".exit"
sqlite3 IDDB.db ".mode tabs" ".headers on" ".output annotations/orphaannot.csv" "select * from orphaannot;" ".exit"
sqlite3 IDDB.db ".mode tabs" ".headers on" ".output annotations/gnomadconstrannot.csv" "select * from gnomadconstrannot;" ".exit"
sqlite3 IDDB.db ".mode tabs" ".headers on" ".output annotations/hpo.csv" "select * from hpo;" ".exit"
sqlite3 IDDB.db ".mode tabs" ".headers on" ".output annotations/gene_names_hpo.csv" "SELECT * FROM genenames_hpo; " ".exit"

exit

