#!/usr/bin/sh
# Script to summarize validation results of vcfeval

if test "$#" -ne 2 ; then
echo " NAME"
echo "   validation_summary.sh"
echo ""
echo " Provide a list of prefixes separated by space and  for each prefix a separate file will be created "
echo " CALL "
echo "    sh validation_summary.sh 'list-of-prefixes-to-folder-names' 'list-od-sample-names-prefixed-by-folder-prefix' " 
echo ""
echo " EXAMPLE"
echo "    sh validation_summary.sh 'coding-exons-GRCh37-p10 some-other-regions' 's11 s12 s21 s22' " 
echo ""
echo " DESCRIPTION"
echo "Script summarizes validation results generated vy rtg-tools vcfeval"
echo "List of prefixes identifies regions, which are connected to the sample names by  the symbol -" 
echo "The snp and indels are separated and indels are stratified by length"
echo "Plotting python script and png graph of the results are  generated on the fly"

    exit 1

fi

PREFIXES=$1 
SAMPLES=$2

for prefix in ${PREFIXES}
do
## the prefix  denotes regions for which statistics is generated
echo "sample,caller,vtype,metric,value" > ${prefix}-snp.csv
echo "sample,caller,vtype,metric,value" > ${prefix}-indels1.csv
echo "sample,caller,vtype,metric,value" > ${prefix}-indels2.csv
echo "sample,caller,vtype,metric,value" > ${prefix}-indels3.csv

for sample in ${SAMPLES}
do
DIR=`pwd`"/${prefix}-${sample}"
echo ${DIR}

for status in tp fn fp
do

# True Positives tp fn an fp are in status variable

      snp=`zcat ${DIR}/${status}.vcf.gz  | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1==2) print $0}' |  wc -l`
      indel1=`zcat ${DIR}/${status}.vcf.gz | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1<11) print $0}' |  wc -l`
      indel2=`zcat ${DIR}/${status}.vcf.gz | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ( ($1>=11) && ($1<21) ) print $0}' |  wc -l`
      indel3=`zcat ${DIR}/${status}.vcf.gz | grep -v ^"#" | awk '{print length($4)+length($5) "\t" $0}'| awk '{ if ($1>=21) print $0}' |  wc -l`


## Separate  snps and indels , separate indels by size 

      echo ${sample},"ensemble",SNPs,${status},${snp}>> ${prefix}-snp.csv
      echo ${sample}-lt10,"ensemble",indels,${status},${indel1} >> ${prefix}-indels1.csv
      echo ${sample}-1020,"ensemble",indels,${status},${indel2}>> ${prefix}-indels2.csv
      echo ${sample}-gt20,"ensemble",indels,${status},${indel3} >> ${prefix}-indels3.csv

done # status

done  #sample

## visualize with python script
## create a script on the fly 
## this is for particular region prefix

echo "import sys" > bcbio_validation_plot_${prefix}.py
echo "from bcbio.variation import validateplot" >> bcbio_validation_plot_${prefix}.py
echo "title='Comparison in region set ${prefix}'" >> bcbio_validation_plot_${prefix}.py
echo "validateplot.classifyplot_from_valfile(sys.argv[1], outtype='png', title=title)" >> bcbio_validation_plot_${prefix}.py
# plot snp
/media/erinija/data/bcbio/local/share/bcbio/anaconda/bin/python bcbio_validation_plot_${prefix}.py ${prefix}-snp.csv
#plot indels1
/media/erinija/data/bcbio/local/share/bcbio/anaconda/bin/python bcbio_validation_plot_${prefix}.py ${prefix}-indels1.csv
#plot indels2
/media/erinija/data/bcbio/local/share/bcbio/anaconda/bin/python bcbio_validation_plot_${prefix}.py ${prefix}-indels2.csv
#plot indels3
/media/erinija/data/bcbio/local/share/bcbio/anaconda/bin/python bcbio_validation_plot_${prefix}.py ${prefix}-indels3.csv

done  #prefix
