############################################################
# Th sql script to organize tables for the report 
# and link gene level external annotations
###########################################################
# Variant impacts are decribed here
# https://useast.ensembl.org/info/genome/variation/prediction/predicted_data.html
############################################################


DROP TABLE IF EXISTS filtered_impacts1;
CREATE TABLE filtered_impacts1 AS SELECT * FROM variant_impacts WHERE impact_severity IN ('HIGH', 'MED'); 
#impact_so NOT IN ('non_coding_transcript_exon_variant','downstream_gene_variant','upstream_gene_variant','intergenic_variant','intron_variant');
select "Filtered impacts ",count(*) from filtered_impacts1;
select "";

DROP TABLE IF EXISTS filtered_variants1;
CREATE TABLE filtered_variants1 AS SELECT * FROM variants WHERE impact_severity IN ('HIGH', 'MED'); 
#AND impact_so NOT IN ('non_coding_transcript_exon_variant','downstream_gene_variant','upstream_gene_variant','intergenic_variant','intron_variant');
select "Filtered variants ",count(*) from filtered_variants1;
select "";


## Second filter variants by frequency and depth and concatenate variant impacts into Info field
DROP TABLE IF EXISTS filtered_variants2;
CREATE TABLE filtered_variants2 AS SELECT 
        v.chrom AS Chrom,
        v.start+1 AS Pos,
        v.ref AS Ref,
        v.alt AS Alt,
        v.type AS VType,
        v.impact AS Variation,
        v.impact_severity AS Impact_severity,
        CAST(IFNULL(v.dp,v.tr) AS INT) AS Depth,
        CAST(v.qual AS REAL) AS Quality,
        v.gene AS Gene,
        v.ensembl_gene_id AS GeneIDv,
        v.symbol_source AS Symbol_source,
        v.clin_sig AS Clinvar,
        v.transcript AS Ensembl_transcript_id,
        REPLACE(v.aa_length,'/','_') AS AA_position,
        REPLACE(v.exon,'/','_') AS Exon,
        v.domains AS Protein_domains,
        v.rs_ids AS rsIDs,
        CAST(v.cheo_af_total AS REAL) AS Gnomad_af,
        CAST(v.cheo_ac_total AS INT) AS Gnomad_ac,
        CAST(v.cheo_an_total AS INT) AS Gnomad_an,
        CAST(v.cheo_af_popmax AS REAL) AS Gnomad_af_popmax,
        CAST(v.cheo_no_other_af_popmax AS REAL) AS Gnomad_af_popmax_noother,
        v.cheo_nhomalt_total AS Gnomad_hom,
        v.sift_score AS Sift_score,
        v.polyphen_score AS Polyphen_score,
        v.cheo_cadd_phred AS Cadd_score,
        v.cheo_vest3_score AS Vest3_score,
        v.cheo_revel_score AS Revel_score,
        v.cheo_gerp_score AS Gerp_score,
        v.cheo_phylop20way_mammalian AS Conserved_in_20_mammals,
        v.aa_change AS AA_change,
        v.old_multiallelic AS Old_multiallelic,
        CAST(COUNT(*) AS INT) AS total_number_of_variant_impacts_in_gemini,
        GROUP_CONCAT( DISTINCT ( '[' || i.impact_severity || ';' || i.impact_so || ';' || i.Gene || ';Exon:' || i.exon || ';' || i.hgvsc || ';' || i.hgvsp || ']' ) ) as Info,
        SUBSTR(GROUP_CONCAT(DISTINCT (CASE WHEN INSTR(i.hgvsc, 'NM') THEN i.hgvsc ELSE '' END ) ), 2) AS Refseq_change,
        v.callers AS Callers,
        TRIM(GROUP_CONCAT( DISTINCT  i.spliceregion),',') AS Spliceregion,
        CAST(TRIM(GROUP_CONCAT( DISTINCT i.maxentscan_diff),',') AS REAL) AS Splicing,
        CAST(TRIM(GROUP_CONCAT( DISTINCT i.maxentscan_alt),',') AS REAL) AS Maxentscan_alt,
        CAST(TRIM(GROUP_CONCAT( DISTINCT i.maxentscan_ref),',') AS REAL) AS Maxentscan_ref,
        v.variant_id AS variant_id FROM filtered_variants1 v, filtered_impacts1 i WHERE 
             v.variant_id=i.variant_id  AND 
             v.cheo_no_other_af_popmax < 0.01  AND 
             Depth >= 10  AND 
             v.chrom not in ('MT','Y')
        GROUP BY v.variant_id;

select "Filtered variants 2 ",count(*) from filtered_variants2;
select "";


.mode tabs
.headers on

select * from filtered_variants2 limit 2;

# CREATE BURDEN column in tb
DROP TABLE IF EXISTS tb;
CREATE TABLE tb AS SELECT * FROM 
 (SELECT Gene as GB, 
         COUNT(Gene) AS Burden 
 FROM filtered_variants2 
 WHERE LENGTH(Gene) > 0 GROUP BY Gene);

select "Burden column";
select * from tb limit 2;
select "";

# CREATE ensembl gene column to make left joins with gene level annotations
DROP TABLE IF EXISTS t0;
CREATE TABLE t0 AS SELECT 
 DISTINCT GeneIDv AS GeneID 
 FROM filtered_variants2 WHERE LENGTH(GeneIDv) >0;

# TEST 
select "GeneID column";
select * from t0 limit 2;
select "";

# IMPORTANT! 
# imported tables get appended, 
#so it is necessary to drop the table before importing
DROP TABLE IF EXISTS omim;
.import annotations/omimannot.csv omim

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS omim1;

CREATE TABLE omim1 as SELECT 
 DISTINCT merged_geneid, 
          gname, 
          gphenotypes 
 FROM omim 
 WHERE INSTR(gphenotypes,'(3)')>0;

CREATE TABLE t1 AS SELECT * FROM t0 v LEFT JOIN omim1 o ON v.GeneID=o.merged_geneid;

select "Left join with omim";
select * from t1 where length(gphenotypes)>1 limit 2;
select "";

DROP TABLE IF EXISTS orpha;
.import annotations/orphaannot.csv orpha

DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS orpha1;

CREATE TABLE orpha1 as SELECT 
 DISTINCT geneid, disorders FROM orpha;

CREATE TABLE t2 AS SELECT 
 DISTINCT GeneID, 
          gname, 
          gphenotypes, 
          disorders 
 FROM (SELECT * FROM t1 v LEFT JOIN orpha1 o ON v.GeneID=o.geneid);

select "Left join with orpha";
select * from t2 where length(disorders)>1 limit 2;
select "";

DROP TABLE IF EXISTS gnomadconstr;
.import annotations/gnomadconstrannot.csv gnomadconstr

DROP TABLE IF EXISTS t3;
CREATE TABLE t3 AS SELECT 
 DISTINCT GeneID, 
           gname, 
           gphenotypes, 
           disorders, oe_lof, oe_mis, pLI, pNull, pRec 
 FROM (SELECT * FROM t2 v LEFT JOIN gnomadconstr o ON v.GeneID=o.geneid);

select "Left join with gnomad constraint";
select * from t3 limit 2;
select "";

DROP TABLE IF EXISTS genenames;
.import annotations/gene_names_hpo.csv genenames

DROP TABLE IF EXISTS t4;
CREATE TABLE t4 AS SELECT DISTINCT 
   GeneID, 
   gname, 
   gphenotypes AS Omim_gene,
   disorders AS Orpha, 
   oe_lof, 
   oe_mis, 
   pLI, 
   pNull, 
   pRec, 
   hugo_description AS Gene_name, 
   hugo_entrez AS Hugo_entrez, 
   hugo_ensg AS Hugo_ensg, 
   hugo_symbol AS Hugo_symbol,
   hpo_entrez,
   hpo_symbol 
FROM (SELECT * FROM t3 v LEFT  JOIN genenames o ON v.GeneID=o.geneid);

select "Left join with genenames";
select * from t4 limit 2;
select "";

## Left join with filtered variants
DROP TABLE IF EXISTS report0;
CREATE TABLE report0 AS SELECT 
 DISTINCT * FROM filtered_variants2 v LEFT JOIN t4 o ON v.GeneIDv=o.GeneID;

## ADD BURDEN column
DROP TABLE IF EXISTS exome;
CREATE TABLE exome AS SELECT  
 DISTINCT * FROM report0 v LEFT JOIN tb o ON v.Gene=o.GB;

select "Final exome table";
select * from exome limit 2;

