#!/usr/bin/sh
# Script to summarize validation results of vcfeval

if test "$#" -ne 2 ; then
echo " NAME"
echo "   list-fn-and-fp.sh"
echo ""
echo " CALL "
echo "    sh list-fn-and-fp.sh 'list-of-prefixes-to-folder-names' 'list-of-sample-names-prefixed-by-folder-prefix' " 
echo ""
echo " EXAMPLE"
echo "    sh validation_summary.sh 'coding-exons-GRCh37-p10 some-other-regions' 's11 s12 s21 s22' " 
echo ""
echo " DESCRIPTION"
echo "Script creates a list of false negatives and false positives aggregating results from all samples "
echo "prefixed by the same prefix. The snp and indels are separated and indels are stratified by length."

    exit 1

fi

PREFIXES=$1 
SAMPLES=$2

for prefix in ${PREFIXES}
do

for status in fn fp
do

SNPFILE=`pwd`/${status}-${prefix}-snp
INDEL1FILE=`pwd`/${status}-${prefix}-indel
#INDEL2FILE=`pwd`/${status}-${prefix}-indel2
#INDEL3FILE=`pwd`/${status}-${prefix}-indel3

> $SNPFILE

head $SNPFILE


for sample in ${SAMPLES}
do

DIR=`pwd`"/${prefix}-${sample}"
echo ${DIR}


# True Positives tp fn an fp are in status variable

      zcat ${DIR}/${status}.vcf.gz  | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1==2) print $0}'| cut -f2-11  >> ${SNPFILE}
      zcat ${DIR}/${status}.vcf.gz  | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1>2) print $0}'| cut -f2-11  >> ${INDEL1FILE}

#      indel1=`zcat ${DIR}/${status}.vcf.gz | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1<11) print $0}' |  wc -l`
#      indel2=`zcat ${DIR}/${status}.vcf.gz | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ( ($1>=11) && ($1<21) ) print $0}' |  wc -l`
#      indel3=`zcat ${DIR}/${status}.vcf.gz | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1>=21) print $0}' |  wc -l`

done # sample

cat ${SNPFILE} | sort -k1,1n -k2,2 | uniq -c | sort -k1,1nr | awk '{print "chr"$2":"$3-20"-"$3+20 "\t" $0}' | grep difficult > ${SNPFILE}.difficult
cat ${SNPFILE} | sort -k1,1n -k2,2 | uniq -c | sort -k1,1nr | awk '{print "chr"$2":"$3-20"-"$3+20 "\t" $0}' | grep -v difficult > ${SNPFILE}.notdifficult
cat $SNPFILE.notdifficult  | awk '{print $0 "\t" "notdifficult" }' > ${SNPFILE}.csv 
cat $SNPFILE.difficult  | awk '{print $0 "\t" "difficult" }' >> ${SNPFILE}.csv 

cat ${INDEL1FILE} | sort -k1,1n -k2,2 | uniq -c | sort -k1,1nr | awk '{print "chr"$2":"$3-20"-"$3+20 "\t" $0}' | grep difficult > ${INDEL1FILE}.difficult
cat ${INDEL1FILE} | sort -k1,1n -k2,2 | uniq -c | sort -k1,1nr | awk '{print "chr"$2":"$3-20"-"$3+20 "\t" $0}' | grep -v difficult > ${INDEL1FILE}.notdifficult
cat ${INDEL1FILE}.notdifficult  | awk '{print $0 "\t" "notdifficult" }' > ${INDEL1FILE}.csv 
cat ${INDEL1FILE}.difficult  | awk '{print $0 "\t" "difficult" }' >> ${INDEL1FILE}.csv 

rm ${SNPFILE} ${INDEL1FILE} *.difficult  *.notdifficult

done  # status

done  #prefix
