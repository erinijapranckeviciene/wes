# CREATE MASTER TABLE OF VARIANTS
DROP TABLE IF EXISTS mastertable;

CREATE TABLE mastertable AS SELECT 
        v.chrom AS Chrom_geminiv,
        v.start+1 AS Pos_geminiv,
        v.ref AS Ref,
        v.alt AS Alt,
        v.type AS VType,
        v.impact AS Variation,
       v.impact_severity AS Impact_severity,
        CAST(IFNULL(v.dp,v.tr) AS INT) AS Depth,
        CAST(v.qual AS REAL) AS Quality,
        v.gene AS Gene,
        v.symbol_source as Symbol_source,
        v.cheo_gsym AS Gsymbol_cheoannot,
        CAST(v.cheo_entrezid as INT) AS Entrezid,
        v.cheo_gname AS Genename_cheo,
       v.clinvar_pathogenic AS Clinvar,
        v.transcript AS Ensembl_transcript_id,
        REPLACE(v.aa_length,'/','_') AS AA_position,
        REPLACE(v.exon,'/','_') AS Exon,
        v.domains AS Protein_domains,
        v.rs_ids AS rsIDs,
        CAST(v.cheo_af_total AS REAL) AS Gnomad_af_cheo,
        CAST(v.cheo_ac_total AS INT) AS Gnomad_ac_cheo,
        CAST(v.cheo_an_total AS INT) AS Gnomad_an_cheo,
        CAST(v.cheo_af_popmax AS REAL) AS Gnomad_af_popmax_cheo,
        CAST(v.cheo_no_other_af_popmax AS REAL) AS Gnomad_af_popmax_noother_cheo,
        v.gnomad_hom AS Gnomad_hom,
        v.sift_score AS Sift_score,
        v.polyphen_score AS Polyphen_score,
        v.cheo_cadd_phred AS Cadd_score_dbnsfp,
        v.cheo_vest3_score AS Vest3_score_dbnsfp,
        v.cheo_revel_score AS Revel_score_dbnsfp,
        v.cheo_gerp_score AS Gerp_score_dbnsfp,
        v.cheo_phylop20way_mammalian AS Conserved_in_20_mammals_dbnsfp,
        v.aa_change AS AA_change,
        v.old_multiallelic AS Old_multiallelic,
        CAST(COUNT(*) AS INT) AS total_number_of_variant_impacts_in_gemini,
        GROUP_CONCAT( DISTINCT ( '[' || i.impact_severity || ';' || i.impact_so || ';' || i.Gene || ';Exon:' || i.exon || ';' || i.hgvsc || ';' || i.hgvsp || ']' ) ) as Info,
        SUBSTR(GROUP_CONCAT(DISTINCT (CASE WHEN INSTR(i.hgvsc, 'NM') THEN i.hgvsc ELSE '' END ) ), 2) AS Refseq_change,
        v.cheo_omim AS Omim,
        v.cheo_orpha AS Orpha,
        v.callers AS Callers,
        TRIM(GROUP_CONCAT( DISTINCT  i.spliceregion),',') AS Spliceregion,
        CAST(TRIM(GROUP_CONCAT( DISTINCT i.maxentscan_diff),',') AS REAL) AS Maxentscan_diff,
        CAST(TRIM(GROUP_CONCAT( DISTINCT i.maxentscan_alt),',') AS REAL) AS Maxentscan_alt,
        CAST(TRIM(GROUP_CONCAT( DISTINCT i.maxentscan_ref),',') AS REAL) AS Maxentscan_ref,
        v.cheo_gnomadlof AS Gnomad_LOF,
        v.is_coding AS is_coding,
        v.is_splicing AS is_splicing,
        v.variant_id AS variant_id FROM variants v, variant_impacts i WHERE ( v.variant_id=i.variant_id ) AND
    ( ( v.cheo_no_other_af_popmax < 0.01 ) OR ( v.cheo_no_other_af_popmax > 99.9 ) ) AND
    ( NOT INSTR(Depth,'None') )  GROUP BY v.variant_id;


## MAKE LEFT JOIN WITH gene2ensembl
DROP TABLE IF EXISTS mg;

CREATE TABLE mg AS SELECT DISTINCT mastertable.*, gene2ensembl.ensg as Ensembl_gene_id
       FROM mastertable LEFT JOIN gene2ensembl ON mastertable.Entrezid=gene2ensembl.entrezid;

## MAKE LEFT JOIN WITH gene_info
DROP TABLE IF EXISTS myosliceexome;

CREATE TABLE myosliceexome AS SELECT DISTINCT mg.*, gene_info.description as Gene_info_description
       FROM mg LEFT JOIN gene_info ON mg.Entrezid=gene_info.entrezid;

## The myoslice query filters by Depth_dptr_geminiv => 10 and selects only 118 genes from mpgenes
## Everything that is associated with the 118 genes. Through symbol as well. 

## Load myoslice table

DROP TABLE IF EXISTS mpgenes;
.mode tabs
.import /projects/Databases/myoslice/MyopathyGenes.csv mpgenes


DROP TABLE IF EXISTS myoslice;
CREATE TABLE myoslice AS SELECT * FROM myosliceexome
       WHERE Depth >= 10 AND Entrezid IN (SELECT DISTINCT CAST(EntrezGeneID AS INT) FROM mpgenes) ;


## MAKE QUERIES to create exome, myoslice and myosliceexome
## THE myoslice exome has all variants filtered by gnomad frequency

## The exome query filters by Impact_severity in HIGH and MED and 
##  Depth_dptr_geminiv => 10
## and if 'LOW' and WES.synonymous then is_splicing, is_coding variants 
## are selected

DROP TABLE IF EXISTS exome;
CREATE TABLE exome AS SELECT * FROM myosliceexome
       WHERE ( (Impact_severity IN ('HIGH', 'MED')) OR ( Impact_severity IN ('LOW') AND Variation IN ('synonymous_variant') AND (is_coding=1 OR is_splicing=1) ) ) AND Depth >= 10;
