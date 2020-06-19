############################################################
# The sql script to organize tables for the report 
# and link gene level external /projects/analysis/report/annotations
###########################################################
# Variant impacts are decribed here
# https://useast.ensembl.org/info/genome/variation/prediction/predicted_data.html
############################################################

## Concatenate all variant effects separately for refseq and for ensembl
DROP TABLE IF EXISTS grouped_impacts_refseq;
CREATE TABLE grouped_impacts_refseq AS select variant_id, COUNT(variant_id) AS Variant_impacts_num_refseq, 
  GROUP_CONCAT( distinct ( '[' || gene || ';' || impact_so || ';' || impact_severity || ';' || hgvsc || ';' || hgvsp || ']')) AS Grouped_variant_impacts_refseq
    FROM variant_impacts WHERE NOT INSTR(transcript,"EN") GROUP BY variant_id ;

DROP TABLE IF EXISTS grouped_impacts_enst;
CREATE TABLE grouped_impacts_enst AS select variant_id, COUNT(variant_id) AS Variant_impacts_num_enst, 
  GROUP_CONCAT( distinct ( '[' || gene || ';' || impact_so || ';' || impact_severity || ';' || hgvsc || ';' || hgvsp || ']')) AS Grouped_variant_impacts_enst 
    FROM variant_impacts WHERE INSTR(transcript,"EN") GROUP BY variant_id;

# distinct variant identifiers
DROP TABLE IF EXISTS var_ids;
CREATE TABLE var_ids AS SELECT DISTINCT variant_id
    FROM variant_impacts;

# Join grouped impacts
DROP TABLE IF EXISTS grouped_impacts_r;
CREATE TABLE grouped_impacts_r AS SELECT v.variant_id as variant_id,
  r.Variant_impacts_num_refseq,
  r.Grouped_variant_impacts_refseq
FROM var_ids v LEFT JOIN grouped_impacts_refseq r ON v.variant_id=r.variant_id;

DROP TABLE IF EXISTS grouped_impacts;
CREATE TABLE grouped_impacts AS SELECT v.variant_id as variant_id,
  v.Variant_impacts_num_refseq,
  v.Grouped_variant_impacts_refseq,
  r.Variant_impacts_num_enst,
  r.Grouped_variant_impacts_enst
FROM grouped_impacts_r v LEFT JOIN grouped_impacts_enst r ON v.variant_id=r.variant_id;

# Join genotypes
DROP TABLE IF EXISTS grouped_impacts_gts;
CREATE TABLE grouped_impacts_gts AS SELECT g.*,
  v.Variant_impacts_num_refseq,
  v.Grouped_variant_impacts_refseq,
  v.Variant_impacts_num_enst,
  v.Grouped_variant_impacts_enst
FROM genotypes g, grouped_impacts v where g.variant_id=v.variant_id;


## Select fields into the report
## Select fields from grouped variant effects : refseq and ensembl

DROP TABLE IF EXISTS variant_fields;
CREATE TABLE variant_fields AS SELECT 
        v.variant_id AS variant_id,
        v.chrom AS Chrom,
        v.start+1 AS Start,
        v.end+1 AS End,
        v.vcf_id AS RS, 
        v.ref AS Ref,
        v.alt AS Alt,
        CAST(v.qual AS REAL) AS Quality,
        v.filter AS Filter,
        v.type AS VType,
        v.sub_type AS VSubType,
        v.call_rate AS Call_rate,
        v.num_hom_ref AS Num_hom_ref,
        v.num_het AS Num_het,
        v.num_hom_alt AS Num_hom_alt,
        v.num_unknown AS Num_unknown,
        v.gene AS Gene,
        v.ensembl_gene_id AS VGeneID,
        v.transcript AS Ensembl_transcript_id,
        v.is_exonic AS IS_exonic,
        v.is_coding AS IS_coding,
        v.is_lof AS IS_lof,
        v.is_splicing AS IS_splicing,
        v.is_canonical AS IS_canonical,
        REPLACE(v.exon,'/','_') AS Exon,
        REPLACE(v.codon_change,'/','_') AS Codon_change,
        REPLACE(v.aa_change,'/','_') AS AA_change,
        REPLACE(v.aa_length,'/','_') AS AA_length,
        v.biotype AS Biotype,
        v.impact AS Impact,
        v.impact_so AS Impact_so,
        v.impact_severity AS Impact_severity,
        v.polyphen_pred AS Polyphen_pred,
        v.polyphen_score AS Polyphen_score,
        v.sift_pred AS Sift_pred,
        v.sift_score AS Sift_score,
        v.ancestral_allele AS Ancestral_allele,
        v.cadd_phred AS Cadd_phred,
        v.cadd_raw AS Cadd_raw,
        v.cadd_raw_rankscore AS Cadd_raw_rankscore,
        v.dann_rankscore AS Dann_rankscore,
        v.dann_score AS Dann_score,
        v.eigen_pc_phred AS Eigen_pc_phred,
        v.eigen_pc_raw AS Eigen_pc_raw,
        v.eigen_pc_raw_rankscore AS Eigen_pc_raw_rankscore,
        v.eigen_phred AS Eigen_phred,
        v.eigen_raw AS Eigen_raw,
        v.eigen_coding_or_noncoding AS Eigen_coding_or_noncoding,
        v.ensembl_geneid AS Ensembl_geneid,
        v.ensembl_proteinid AS Ensembl_proteinid,
        v.ensembl_transcriptid AS Ensembl_transcriptid,
        v.mutationassessor_uniprotid AS Mutationassessor_uniprotid,
        v.mutationassessor_pred AS Mutationassessor_pred,
        v.mutationassessor_score AS Mutationassessor_score,
        v.mutationassessor_score_rankscore AS Mutationassessor_score_rankscore,
        v.mutationassessor_variant AS Mutationassessor_variant,
        v.mutationtaster_aae AS Mutationtaster_aae,
        v.mutationtaster_converted_rankscore AS Mutationtaster_converted_rankscore,
        v.mutationtaster_model AS Mutationtaster_model,
        v.mutationtaster_pred AS Mutationtaster_pred,
        v.mutationtaster_score AS Mutationtaster_score,
        v.revel_rankscore AS Revel_rankscore,
        v.revel_score AS Revel_score,
        v.vest3_rankscore AS Vest3_rankscore,
        v.vest3_score AS Vest3_score,
        v.cds_strand AS Cds_strand,
        v.clinvar_disease_name AS Clinvar_disease_name,
        v.clinvar_sig AS Clinvar_sig,
        v.codon_degeneracy AS Codon_degeneracy,
        v.codonpos AS Codonpos,
        v.common_pathogenic AS Common_pathogenic,
        v.fathmm_mkl_coding_group AS Fathmm_mkl_coding_group,
        v.fathmm_mkl_coding_pred AS Fathmm_mkl_coding_pred,
        v.fathmm_mkl_coding_rankscore AS Fathmm_mkl_coding_rankscore,
        v.fathmm_mkl_coding_score AS Fathmm_mkl_coding_score,
        v.hotc_gnomad_exome_ac AS Gnomad_exome_ac,
        v.hotc_gnomad_exome_an AS Gnomad_exome_an,
        v.hotc_gnomad_exome_af AS Gnomad_exome_af,
        v.hotc_gnomad_exome_nhomalt AS Gnomad_exome_nhomalt,
        v.hotc_gnomad_exome_af_popmax AS Gnomad_exome_af_popmax,
        v.hotc_gnomad_exome_af_afr AS Gnomad_exome_af_afr,
        v.hotc_gnomad_exome_af_amr AS Gnomad_exome_af_amr,
        v.hotc_gnomad_exome_af_asj AS Gnomad_exome_af_asj,
        v.hotc_gnomad_exome_af_eas AS Gnomad_exome_af_eas,
        v.hotc_gnomad_exome_af_sas AS Gnomad_exome_af_sas,
        v.hotc_gnomad_exome_af_fin AS Gnomad_exome_af_fin,
        v.hotc_gnomad_exome_af_nfe AS Gnomad_exome_af_nfe,
        v.hotc_gnomad_exome_af_oth AS Gnomad_exome_af_oth,
        v.hotc_gnomad_genome_ac AS Gnomad_genome_ac,
        v.hotc_gnomad_genome_an AS Gnomad_genome_an,
        v.hotc_gnomad_genome_af AS Gnomad_genome_af,
        v.hotc_gnomad_genome_nhomalt AS Gnomad_genome_nhomalt,
        v.hotc_gnomad_genome_af_popmax AS Gnomad_genome_af_popmax,
        v.hotc_gnomad_genome_af_afr AS Gnomad_genome_af_afr,
        v.hotc_gnomad_genome_af_amr AS Gnomad_genome_af_amr,
        v.hotc_gnomad_genome_af_asj AS Gnomad_genome_af_asj,
        v.hotc_gnomad_genome_af_eas AS Gnomad_genome_af_eas,
        v.hotc_gnomad_genome_af_sas AS Gnomad_genome_af_sas,
        v.hotc_gnomad_genome_af_fin AS Gnomad_genome_af_fin,
        v.hotc_gnomad_genome_af_nfe AS Gnomad_genome_af_nfe,
        v.hotc_gnomad_genome_af_oth AS Gnomad_genome_af_oth,
        v.hg19_chr AS hg19_chr,
        v.hg19_pos AS hg19_pos,
        v.integrated_confidence_value AS Integrated_confidence_value,
        v.integrated_fitcons_score AS Integrated_fitcons_score,
        v.refcodon AS Refcodon,
        v.rs_ids AS RS_ids,
        v.allele AS Allele,
        v.feature_type AS Feature_type,
        REPLACE(v.intron,'/','_') AS Intron,
        v.hgvsc AS Hgvsc,
        v.hgvsp AS Hgvsp,
        REPLACE(v.cdna_position,'/','_') AS Cdna_position,
        REPLACE(v.cds_position,'/','_') AS Cds_position,
        v.existing_variation AS Existing_variation,
        v.allele_num AS Allele_num,
        v.distance AS Distance,
        v.strand AS Strand,
        v.flags AS Flags,
        v.pick AS Pick,
        v.variant_class AS Variant_class,
        v.symbol_source AS Symbol_source,
        v.hgnc_id AS Hgnc_id,
        v.tsl AS Tsl,
        v.appris AS Appris,
        v.ccds AS Ccds,
        v.ensp AS Ensp,
        v.swissprot AS Swissprot,
        v.source AS Source,
        v.given_ref AS Given_ref,
        v.used_ref AS Used_ref,
        v.domains AS Domains,
        v.hgvsg AS Hgvsg,
        v.dp AS Depth,
        CAST(r.Variant_impacts_num_refseq AS INT) AS Num_refseq_impacts, 
         r.Grouped_variant_impacts_refseq AS Refseq_impacts, 
        CAST(r.Variant_impacts_num_enst AS INT) AS Num_ensembl_impacts,
         r.Grouped_variant_impacts_enst AS Ensembl_impacts,
         r.gts,
         r.gt_depths,
         r.gt_ref_depths,
         r.gt_alt_depths,
         r.gt_quals,
         r.gt_alt_freqs
    FROM variants v, grouped_impacts_gts r WHERE 
             v.variant_id=r.variant_id;


#select "Variant fields ",count(*) from variant_fields;
#select "";

# Select gene IDs that are from variant table.
DROP TABLE IF EXISTS gene_ids;
CREATE TABLE gene_ids as SELECT distinct VGeneID from variant_fields;

# Join VGeneID with gene level annotations
DROP TABLE IF EXISTS gl_annotations;
CREATE TABLE gl_annotations AS SELECT v.VGeneID,gl.* 
  FROM gene_ids v LEFT JOIN genelevel gl ON v.VGeneID=gl.GeneID; 

#select * from gl_annotations limit 5;

DROP TABLE IF EXISTS gl_annotations_grouped;
CREATE TABLE gl_annotations_grouped AS SELECT GeneID,
  GROUP_CONCAT( DISTINCT (Description)) AS Gene_description,
  GROUP_CONCAT( DISTINCT (ENTREZ)) AS ENTREZ,
  GROUP_CONCAT( DISTINCT ('[' || MIM || ';' || OMIM_Phenotypes || ']' )) AS OMIM,
  GROUP_CONCAT( DISTINCT ('[' || Orpha_number || ';' || Orpha_disorder || ';' || Orpha_association || ']' )) AS ORPHA
FROM gl_annotations GROUP BY GeneID;

#select "gl_annotation_grouped ", count(*) from gl_annotations_grouped;

# The grouped gene level annotations join with variant_fields

DROP TABLE IF EXISTS variant_fields_gts_genelevel;
CREATE TABLE variant_fields_gts_genelevel AS SELECT v.*, gl.* 
  FROM  variant_fields v 
    LEFT JOIN gl_annotations_grouped gl ON v.VGeneID=gl.GeneID;

#select "variant_fields_gts_genelevel ",count(*) from variant_fields_gts_genelevel;

# Add refseq transcript information
DROP TABLE IF EXISTS enst_ids;
CREATE TABLE enst_ids as SELECT DISTINCT Ensembl_transcript_id as vENST FROM  variant_fields_gts_genelevel;
# keep only one identifier if tey are separated by comma

#select "enst_ids ",count(*) from enst_ids;


DROP TABLE IF EXISTS enst_nm;
CREATE TABLE enst_nm as SELECT DISTINCT e.vENST, gl.NM 
 FROM enst_ids e LEFT JOIN genelevel gl ON e.vENST=gl.ENST;

#select "enst_nm ",count(*) from enst_nm;


DROP TABLE IF EXISTS variant_fields_gts_genelevel_nm;
CREATE TABLE variant_fields_gts_genelevel_nm AS SELECT v.*, e.NM 
  FROM  variant_fields_gts_genelevel v LEFT JOIN enst_nm e ON v.Ensembl_transcript_id=e.vENST;

.mode tabs
.headers on



## Select fields in a proper order: separate script 
## ( TO DO for sample names - how to pass  sample name as a variable to the SQL script)

#SELECT "Variant fields_gts_genelevel_nm ",count(*) from variant_fields_gts_genelevel_nm;

DROP TABLE IF EXISTS grouped_impacts_refseq;
DROP TABLE IF EXISTS grouped_impacts_enst;
DROP TABLE IF EXISTS var_ids;
DROP TABLE IF EXISTS grouped_impacts_r;
DROP TABLE IF EXISTS grouped_impacts;
DROP TABLE IF EXISTS grouped_impacts_gts;
DROP TABLE IF EXISTS variant_fields;
DROP TABLE IF EXISTS gene_ids;
DROP TABLE IF EXISTS gl_annotations;
DROP TABLE IF EXISTS gl_annotations_grouped;
DROP TABLE IF EXISTS variant_fields_gts_genelevel;
DROP TABLE IF EXISTS enst_ids;
DROP TABLE IF EXISTS enst_nm;
#DROP TABLE IF EXISTS variant_fields_gts_genelevel_nm;

#DROP TABLE IF EXISTS genotypes;
#DROP table if exists genelevel;
