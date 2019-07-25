#!/bin/sh
# Reannotate and load to gemini db
# DIR  - reannotation pending folder
# NAME - project to be reannotated, these are two files vcf and ped
# Example DIR is reannotate contains NA12878 vcf and ped
#####################################################################
## CALL: sh reannotate-STEP2.sh reannotate NIST
####################################################################

# Full path to the of the file and file name 
# NAME=/projects/RD/CHEO_ROI/reannotate/NIST-chr22
NAME=$1 

# The following paths change accordingly
VCFANNOD=/opt/analysis/bcbio/anaconda/bin/
VCF2DB=/opt/analysis/bcbio/bin/
BASEPATH=/opt/analysis/bcbio/genomes/Hsapiens/GRCh37/

# reannotated with vcfanno like in cheop.conf and cheop.lua
${VCFANNOD}/vcfanno -base-path ${BASEPATH} -p 60 -lua cheop.lua cheop.conf ${NAME}.vcf | \
   sed 's/Number=A/Number=1/g' > ${NAME}-reannotated.vcf
echo "Reannotated ${DIR}/${NAME}, loading to the gemini db"

# if ped file exits, create gemini db
# if there is  a database already with the same name move to .1
if [ -f ${NAME}.ped ]; then

  # if there is  a database already with the same name move to .1
  if [ -f ${NAME}.db ]; then
    mv ${NAME}.db ${NAME}.db.1
  fi

  # load  reannotated vcf into the gemini database
  ${VCF2DB}/vcf2db.py ${NAME}-reannotated.vcf ${NAME}.ped ${NAME}.db
  echo " The gemini db ${DIR}/${NAME} created"
else 
  echo "Skip gemini, no ped file"
fi

