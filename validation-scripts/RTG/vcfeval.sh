#!/bin/bash
# Compare experimental calls with reference
#
#Call : sh vcfeval.sh vcflist_containing_full_paths_to_vcf.gz_files output_dir_prefix vcf_field_for_ROC_threshold
#
#Example:
#       sh vcfeval.sh vcflist output_dir_prefix  QUAL
#
# To use the script the RTG tools should be installed
# RTG install :  https://github.com/RealTimeGenomics/rtg-tools

# Set the correct paths to the parameters that will not be changing
# RTGPATH=/path/to/rtg/program/folder

RTGPATH=/home/erinija/Software/rtg-tools/rtg-tools-3.8.4-bdba5ea

# REFSDF=/path/bcbio/genomes/sdf
REFSDF=/media/erinija/data/bcbio/upgrade/genomes/Hsapiens/GRCh37/rtg/GRCh37.sdf

#EVALREGIONS=/regions/within/which/comparison/should/be/performed
# Genome in the bottle  high confidence regions and high confidence calls 
# can be used to restrict comparison to only high confidence regions.
# These should be provided with the parameter --evaluation-regions=/path/to/the/bed/file
#
# This command dowloads the high confidence Sanger validated NA12878 genomic regions from NCBI GET-RM
# wget ftp://ftp.ncbi.nlm.nih.gov/variation/get-rm/current/NA12878_sanger_validated.bed.gz
#
# This command downloads high confidence NA12878 variant calls from NCGI GET-RM
# wget ftp://ftp.ncbi.nlm.nih.gov/variation/get-rm/current/variant_calls/NA12878/NIST/converted_NIST_NA12878_GIAB_V_2_18_High_Confidence_SNPs_Indels.vcf.gz
# 
# Other regions within which a comparison should be restricted
# such as capture should be provided  with the parameter
# --bed-regions=/path/to/capture/regions
# Note, that seq names in regions in the bed file should be consistent with the 
# seq names in the vcf  and genome build (GRCh37 instead of chrNum has only Num, so the bed line looks like : Num start	stop)
# 
# BEDREGIONS will be passed as a parameter to this script 
# BEDREGIONS=/path/to/bed/regions


# REFCALLS=/ path/to/reference/calls  it can be also another vcf file taken as a  reference base
REFCALLS=/media/erinija/data/Databases/GIAB/NA12878-latest/HG001_GRCh37_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz
# 
# Reference calls NA12878_high_quality_variant.vcf.gz  from NCBI GET-RM website are in multisample call format and vcfeval does not work with this format 

# Provide a list of  *.vcf.gz files as a parameter
# vcf files are already bgzipped an indexed with tabix (such as they are created in bcbio final)

VCFLIST=$1
OUTDIRPREFIX=$2
VCFFIELD=$3
BEDREGIONS=$4

for vcf in `cat ${VCFLIST}`
do

# strip the name
bname=`basename ${vcf} .vcf.gz`
OUTPUTDIR=${OUTDIRPREFIX}-${bname}

# check if the directory exists, if it does remove, because rtg generates an error if it exists
if [ -d $OUTPUTDIR ] 
then
	rm -f -r ${OUTPUTDIR}
fi

echo ${vcf}
echo ${OUTPUTDIR}

${RTGPATH}/rtg vcfeval --bed-regions=${BEDREGIONS} --all-records --vcf-score-field=${VCFFIELD} -b ${REFCALLS} -c ${vcf} --output=${OUTPUTDIR} -t ${REFSDF}                                     

# If needed, call vcfeval with evaluation regions
#${RTGPATH}/rtg vcfeval --evaluation-regions=${EVALREGIONS} --all-records --vcf-score-field=${VCFFIELD} -b ${REFCALLS} -c ${vcf} --output=${OUTPUTDIR} -t ${REFSDF}


done

# Create  ROC plots  (if no -png is provided,  it opens interactive plot)
# ${RTGPATH}/rtg rocplot ${OUTDIRPREFIX}*/weighted_roc.tsv.gz --png="roc.png" --line=width=2 --title=${VCFLIST}

# Erinija Pranckeviciene, CHEO, 2018.03.07
