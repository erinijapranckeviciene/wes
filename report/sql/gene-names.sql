#######################################
# Aggregate data to get gene names
# from HUGO, GENEINFO and BIOMART sources
# some ids are in HUGO and 
# some in geneinfo and some in Ensembl
######################################
## The merged table has records in a form 
## symbol and ensg, symbol and entrez
## 
## first- hugo gene name, hugo symbol and 
## hugo entrezid and hugo ensembl_gene_id. 
## second - gene_info
## third Ensembl biomart

DROP INDEX IF EXISTS mergedIndex;
CREATE INDEX mergedIndex ON merged(geneid);

DROP INDEX  IF EXISTS hgncIndex;
CREATE INDEX hgncIndex ON hgnc(entrez_id, ensembl_gene_id, symbol);


# from merged 40186 genes with entrezid
DROP TABLE IF EXISTS merged_entrez;
CREATE TABLE merged_entrez AS SELECT * FROM merged WHERE INSTR(geneid,'ENSG')<1; 
select "merged_entrez ", count(*) from merged_entrez;

# from merged 57748 with ensg
DROP TABLE IF EXISTS merged_ensg;
CREATE TABLE merged_ensg AS SELECT * FROM merged WHERE INSTR(geneid,'ENSG')>0;
select "merged_ensg ", count(*) from merged_ensg;

### NO.SELECT into the external tables, that we can import later
## This is the most time consuming step
## Takes about 10 minutes to create these two tables
## Run once and freeze

.mode tabs
.headers on

#.output annotations/mergedEntrezInHugo.tsv
DROP TABLE IF EXISTS mergedentrezinhugo;
CREATE TABLE mergedentrezinhugo AS
SELECT m.*, 
       h.name AS hugo_description, 
       h.entrez_id AS hugo_entrez, 
       h.ensembl_gene_id AS hugo_ensg, 
       h.symbol AS hugo_symbol 
 FROM merged_entrez m, hgnc h 
  WHERE m.geneid=h.entrez_id OR m.symbol=h.symbol OR m.symbol=h.prev_symbol;
select "merged entrez in hugo ", count(*) from mergedentrezinhugo;

#.output annotations/mergedEnsgInHugo.tsv 
DROP TABLE IF EXISTS mergedensginhugo;
CREATE TABLE mergedensginhugo AS
SELECT m.*, 
       h.name AS hugo_description, 
       h.entrez_id AS hugo_entrez, 
       h.ensembl_gene_id AS hugo_ensg, 
       h.symbol AS hugo_symbol 
 FROM merged_ensg m, hgnc h 
  WHERE m.geneid=h.ensembl_gene_id OR m.symbol=h.symbol OR m.symbol=h.prev_symbol;
select "merged ensg in hugo ", count(*) from mergedensginhugo;

## Import these tables back
#.import annotations/mergedEntrezInHugo.tsv mergedentrezinhugo
#.import annotations/mergedEnsgInHugo.tsv mergedensginhugo


############################################################## DEAL WITH ENTREZ THAT NOT IN HUGO
## The entrez that are not in hugo are in geneinfo

DROP TABLE IF EXISTS  mergedentreznotinhugo;
CREATE TABLE mergedentreznotinhugo AS 
 SELECT * FROM merged_entrez 
  WHERE geneid NOT IN 
   (SELECT geneid FROM mergedentrezinhugo);
select "merged entrez not in hugo ", count(*) from mergedentreznotinhugo;

# Identify annotations from geneinfo

# Table t1 - from geneinfo and gene2 ensembl that have ENSG 809
DROP TABLE IF EXISTS t1;
CREATE TABLE t1 AS SELECT
    m.*, 
    g.description AS gi_description, 
    g.GeneID AS gi_entrez, 
    e.Ensembl_gene_identifier AS gi_ensg, 
    g.Symbol AS gi_symbol 
 FROM mergedentreznotinhugo m, geneinfo g, gene2ensembl e 
  WHERE m.geneid=g.GeneID AND m.geneid=e.GeneID;
select "t1 from gene info have ensg ", count(*) from t1;


# The table t2 does not have ENSG 3323
DROP TABLE IF EXISTS t2;
CREATE TABLE t2 AS SELECT
   m.*, 
   g.description as gi_description, 
   g.GeneID as gi_entrez, 
   '-' as gi_ensg, 
   g.Symbol as gi_symbol 
 FROM mergedentreznotinhugo m, geneinfo g 
  WHERE m.geneid=g.GeneID AND m.geneid NOT IN 
  (SELECT GeneID FROM gene2ensembl);
select "t2 from gene info does not have ensg ", count(*) from t2;

## In total 1785 are not in hugo and not in tables t1 and t2 
## This a table of discontinued and replaced symbols
DROP TABLE IF EXISTS t3;
CREATE TABLE t3 AS SELECT
   m.*, 
   'discontinued_replaced' as di_description, 
    d.GeneID as di_entrez, 
    d.Discontinue_Date as di_ensg, 
    d.Discontinued_Symbol as di_symbol 
 FROM mergedentreznotinhugo m, genehistory d 
  WHERE m.geneid NOT IN (SELECT geneid FROM t1) AND 
        m.geneid NOT IN (SELECT geneid FROM t2) AND 
        m.geneid=d.Discontinued_GeneID;
select "t3 has discontinued and replaced genes ", count(*) from t3;

############################################################## DEAL WITH ENSG THAT NOT IN HUGO
## The ensg that are not in hugo are in geneinfo 
## This has 19778 IDS 
## All these ENSG ids are in ensbiomart
## Meaning that some has gene descriptions
# Only 2580 with gene descriptions
# And 1601 have entrezids. 

DROP TABLE IF EXISTS  mergedensgnotinhugo;
CREATE TABLE mergedensgnotinhugo AS 
 SELECT * FROM merged_ensg 
  WHERE geneid NOT IN 
   (SELECT geneid FROM mergedensginhugo);
select "merged ensg not in hugo ", count(*) from mergedensgnotinhugo;

DROP TABLE IF EXISTS ensginbiomart;
CREATE TABLE ensginbiomart AS SELECT 
   DISTINCT m.*, 
   b.Gene_description AS bm_description, 
   b.EntrezGene_ID AS bm_entrez, 
   b.Gene_stable_ID AS bm_ensg, 
   b.Gene_name AS bm_symbol 
 FROM mergedensgnotinhugo m, ensbiomart b 
  WHERE m.geneid=b.Gene_stable_ID;
select "merged ensg in biomart ", count(*) from ensginbiomart;

##############################################################  Making sure that each gene if possible is represented
## by entrez and ensg
## First - deal with the IDs that are in HUGO

drop table if exists mergeduniohugo;
create table mergedunionhugo as select * from mergedentrezinhugo union select * from mergedensginhugo order by symbol;
select "identifiers in hugo entrez ensg union ", count(*) from mergedunionhugo;

drop table if exists hugotable; 
create table hugotable as select distinct * 
 from (select symbol, geneid, hugo_description, hugo_entrez, hugo_ensg, hugo_symbol from mergedunionhugo 
        union 
       select symbol,hugo_entrez, hugo_description,hugo_entrez, hugo_ensg, hugo_symbol from mergedunionhugo 
        union 
       select symbol,hugo_ensg, hugo_description, hugo_entrez, hugo_ensg, hugo_symbol from mergedunionhugo);

select "appended hugo and entrez where possible ", count(*) from hugotable;

### The same strategy with table t1,t2,t3 and ensgbiomart
### first merge, then duplication of rows, 

drop table if exists mergedunionother;
create table mergedunionother as select * from t1 union select * from t2 union select * from t3 union select * from ensginbiomart order by symbol;
select "identifiers in t1,t2,t3,ensginbiomart union ", count(*) from mergedunionother;


drop table if exists gmarttable; 
create table gmarttable as select distinct * 
  from (select symbol, geneid, gi_description, gi_entrez, gi_ensg, gi_symbol from mergedunionother
         union 
        select symbol,gi_entrez, gi_description,gi_entrez, gi_ensg, gi_symbol from mergedunionother
         union 
        select symbol,gi_ensg, gi_description, gi_entrez, gi_ensg, gi_symbol from mergedunionother) 
  where length(geneid)>1 order by symbol;
select "gmarttable ", count(*) from gmarttable;

## create genenames table
drop table if exists genenames;
create table genenames as 
 select distinct * from hugotable 
   union
select distinct * from gmarttable;
select "total genenames union hugo geneinfo ensbiomart ", count(*) from genenames;

## create hpo identifiers
drop table if exists hpoids; 
create table hpoids as select distinct 
  "gene-id(entrez)" as hpo_entrez, 
  "gene-symbol" as hpo_symbol from hpo;
select " HPO identifiers ", count(*) from hpoids;

drop table if exists genenames_hpo;
create table genenames_hpo as 
  select * from genenames left join hpoids on 
    genenames.hugo_entrez=hpoids.hpo_entrez;
select " genenames left join hpo ids ", count(*) from genenames_hpo;
