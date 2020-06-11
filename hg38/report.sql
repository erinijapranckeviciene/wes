############################################################
# The sql script to organize tables for the report 
# and link gene level external /projects/analysis/report/annotations
###########################################################
# Variant impacts are decribed here
# https://useast.ensembl.org/info/genome/variation/prediction/predicted_data.html
############################################################

## Concatenate all variant effects
DROP TABLE IF EXISTS grouped_impacts;
CREATE TABLE grouped_impacts AS select variant_id, COUNT(variant_id) AS Variant_impacts_num, GROUP_CONCAT( distinct ( '[' || gene || ';' || impact_so || ';' || impact_severity || ';' || hgvsc || ';' || hgvsp || ']')) AS Grouped_variant_impacts FROM variant_impacts GROUP BY variant_id;
SELECT "grouped_impacts ", COUNT(*) FROM grouped_impacts; 
SELECT "";


## Select fields into the report
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
        v.gnomad_ac AS Gnomad_ac,
        v.gnomad_ac_acr AS Gnomad_ac_afr,
        v.gnomad_ac_amr AS Gnomad_ac_amr,
        v.gnomad_ac_asj AS Gnomad_ac_asj,
        v.gnomad_ac_eas AS Gnomad_ac_eas,
        v.gnomad_ac_fin AS Gnomad_ac_fin,
        v.gnomad_ac_nfe AS Gnomad_ac_nfe,
        v.gnomad_ac_oth AS Gnomad_ac_oth,
        v.gnomad_ac_popmax AS Gnomad_ac_popmax,
        v.gnomad_ac_sas AS Gnomad_ac_sas,
        v.gnomad_af AS Gnomad_af,
        v.gnomad_af_afr AS Gnomad_af_afr,
        v.gnomad_af_amr AS Gnomad_af_amr,
        v.gnomad_af_asj AS Gnomad_af_asj,
        v.gnomad_af_eas AS Gnomad_af_eas,
        v.gnomad_af_fin AS Gnomad_af_fin,
        v.gnomad_af_nfe AS Gnomad_af_nfe,
        v.gnomad_af_oth AS Gnomad_af_oth,
        v.gnomad_af_popmax AS Gnomad_af_popmax,
        v.gnomad_af_sas AS Gnomad_af_sas,
        v.gnomad_an AS Gnomad_an,
        v.gnomad_an_anr AS Gnomad_an_afr,
        v.gnomad_an_amr AS Gnomad_an_amr,
        v.gnomad_an_asj AS Gnomad_an_asj,
        v.gnomad_an_eas AS Gnomad_an_eas,
        v.gnomad_an_fin AS Gnomad_an_fin,
        v.gnomad_an_nfe AS Gnomad_an_nfe,
        v.gnomad_an_oth AS Gnomad_an_oth,
        v.gnomad_an_popmax AS Gnomad_an_popmax,
        v.gnomad_an_sas AS Gnomad_an_sas,
        v.gnomad_gc AS Gnomad_gc,
        v.gnomad_gc_female AS Gnomad_gc_female,
        v.gnomad_gc_male AS Gnomad_gc_male,
        v.gnomad_hom AS Gnomad_hom,
        v.gnomad_hom_female AS Gnomad_hom_female,
        v.gnomad_hom_male AS Gnomad_hom_male,
        v.gnomad_popmax AS Gnomad_popmax,
        v.gnomad_exomes_ac AS Gnomad_exomes_ac,
        v.gnomad_exomes_af AS Gnomad_exomes_af,
        v.gnomad_exomes_an AS Gnomad_exomes_an,
        v.gnomad_genomes_ac AS Gnomad_genomes_ac,
        v.gnomad_genomes_af AS Gnomad_genomes_af,
        v.gnomad_genomes_an AS Gnomad_genomes_an,
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
        CAST(g.Variant_impacts_num AS INT) AS Num_of_variant_impacts,
        g.Grouped_variant_impacts FROM variants v, grouped_impacts g WHERE 
             v.variant_id=g.variant_id;

select "Variant fields ",count(*) from variant_fields;
select "";


# Join fields with variants
DROP TABLE IF EXISTS variant_fields_gts;
CREATE TABLE variant_fields_gts AS SELECT g.*, v.* FROM genotypes g, variant_fields v where g.variant_id=v.variant_id;

# To avoid duplications we will need to group/aggregate OMIMand Orpha diseases into one line 
DROP TABLE IF EXISTS variant_fields_gts_genelevel;
CREATE TABLE variant_fields_gts_genelevel AS SELECT v.*, gl.* 
  FROM  variant_fields_gts v LEFT JOIN genelevel gl ON v.VGeneID=gl.GeneID;

.mode tabs
.headers on

SELECT * from variant_fields_gts_genelevel;

#drop table if exists grouped_impacts;
#drop table if exists variant_fields;
#drop table if exists variant_fields_gts;
#drop table if exists variant_fields_gts_genelevel;
#drop table if exists genotypes;
#drop table if exists genelevel;
