####################################################
# CALL : 
#    sqlite3 IDDB.db < make_gene_level_annotations_table.sql
# OUTPUT : 
#    new file in the curent directory 
#        omim_orpha_ensg_gene_level_annotations.csv
####################################################


####################################################
# CODE
####################################################

# Join OMIM with geneinfo on Entrez_Gene_ID
DROP TABLE IF EXISTS ginfoomim;
CREATE TABLE ginfoomim AS SELECT
  g.GeneID, 
  g.Symbol, 
  g.description, 
  g.dbXD, 
  o.Ensembl_Gene_ID, 
  o.Gene_Symbols, 
  o.Approved_Symbol, 
  o.Phenotypes  
FROM geneinfo g LEFT JOIN genemap2 o ON g.GeneIDID=o.Entrez_Gene_ID;

# All OMIM IDs are in geneinfo, except of deprecated 

# Join ORPHA with the OMIM on gene symbol
DROP TABLE IF EXISTS ginfoomimorpha;
CREATE TABLE ginfoomimorpha AS SELECT 
  g.*, o.*  FROM ginfoomim g LEFT JOIN orpha o ON g.Symbol=o.Gene_symbol;

# Export ORPHA records that will need manual curation
.mode tabs
.headers on
.out orpha_to_curate.csv
SELECT * FROM orpha WHERE Gene_symbol NOT IN (SELECT Symbol FROM geneinfo);
sqlite> .out

# Join an OMIM and ORPHA join with gene2ensembl to get ensembl identifiers
DROP TABLE IF EXISTS ginfoomimorphaens;
CREATE TABLE ginfoomimorphaens AS SELECT 
  g.*, e.* FROM ginfoomimorpha g LEFT JOIN gene2ensembl e ON g.GeneID=e.GeneID;

# Create table as source of gene level annotations
DROP TABLE IF EXISTS annosource;
CREATE TABLE annosource AS SELECT 
  rowid AS ID, 
  GeneID, 
  Symbol, 
  description, 
  MIM_number, 
  Phenotypes, 
  Disorder_name as Orpha_disorder, 
  Disorder_OrphaNumber as Orpha_number, 
  Association_type as Orpha_association, 
  Association_status as Orpha_assocstatus, 
  Ensembl_gene_identifier as ENSG, 
  RNA_nucleotide_accession as NM, 
  Ensembl_rna_identifier as ENST 
FROM ginfoomimorphaens;

# schema of annosource
#CREATE TABLE annosource(
#  ID INT,
#  GeneID TEXT,
#  Symbol TEXT,
#  description TEXT,
#  MIM_Number TEXT,
#  Phenotypes TEXT,
#  Orpha_disorder TEXT,
#  Orpha_number TEXT,
#  Orpha_association TEXT,
#  Orpha_assocstatus TEXT,
#  ENSG TEXT,
#  NM TEXT,
#  ENST TEXT
#);

# Create two tables in which one gas Entrez gene ID as GeneID and another has Ensembl_Gene_ID as GeneID
DROP TABLE IF EXISTS annosourceentrez;
CREATE TABLE annosourceentrez AS SELECT 
 ID, 
 GeneID, 
 Symbol, 
 description, 
 MIM_number, 
 Phenotypes, 
 Orpha_disorder, 
 Orpha_number, 
 Orpha_association, 
 Orpha_assocstatus, 
 NM, 
 ENST 
FROM annosource;

DROP TABLE IF EXISTS annosourceensg;
CREATE TABLE annosourceensg AS SELECT 
 ID, 
 ENSG as GeneID, 
 Symbol, 
 description, 
 MIM_number, 
 Phenotypes, 
 Orpha_disorder, 
 Orpha_number, 
 Orpha_association, 
 Orpha_assocstatus, 
 NM, 
 ENST 
FROM annosource;

# Export both tables to the same file to merge 
# and then import them again
DROP TABLE IF EXISTS annottmp;
.mode tabs
.headers on
.out annottmp
SELECT * FROM annosourceentrez;
SELECT * FROM annosourceensg;

.out
.import annottmp annottmp
 
# This is the final gene level annotation table 
# to join with variant annotations
# output it into current dir as a table
# move to the appropriate location later
.mode tabs
.headers on
.out omim_orpha_ensg_gene_level_annotations.csv
SELECT rowid as NUM, 
       GeneID, 
       Symbol, 
       description as Description, 
       MIM_Number as MIM, 
       Phenotypes as OMIM_Phenotypes, 
       Orpha_disorder, 
       Orpha_number, 
       Orpha_association, 
       Orpha_assocstatus, 
       NM, 
       ENST 
FROM annottmp WHERE NOT INSTR(Symbol,"Sym") ORDER BY ID;

.exit
