DROP TABLE IF EXISTS gene_bed;

CREATE TABLE gene_bed(
  chrom    INTEGER NOT NULL,
  start    INTEGER NOT NULL,
  end      INTEGER NOT NULL,
  entrezid INTEGER NOT NULL,
  symbol  TEXT NOT NULL,
  description TEXT NOT NULL);


DROP TABLE IF EXISTS gene_info;

CREATE TABLE gene_info(
  entrezid INTEGER NOT NULL,
  symbol  TEXT NOT NULL,
  synonyms TEXT NOT NULL,
  dbxref  TEXT NOT NULL,
  description TEXT NOT NULL,
  biotype  TEXT NOT NULL);

DROP TABLE IF EXISTS gene2ensembl;

CREATE TABLE gene2ensembl(
  entrezid INTEGER NOT NULL,
  ensg     TEXT NOT NULL,
  rnaacc   TEXT NOT NULL,
  enst     TEXT NOT NULL,
  protacc  TEXT NOT NULL,
  ensp     TEXT NOT NULL);

DROP TABLE IF EXISTS mim2gene;

CREATE TABLE mim2gene(
  mimnumber    INTEGER NOT NULL,
  mimentrytype TEXT NOT NULL,
  entrezid     INTEGER NOT NULL,
  symbol       TEXT NOT NULL,
  ensg         TEXT NOT NULL);

DROP TABLE IF EXISTS genemap2;

CREATE TABLE genemap2(
  chrom        INTEGER NOT NULL,
  start        INTEGER NOT NULL,
  end          INTEGER NOT NULL,
  cytolocation TEXT NOT NULL,
  cmpcytolocation TEXT NOT NULL,
  mimnumber    INTEGER NOT NULL,
  genesymbols  TEXT NOT NULL,
  genename     TEXT NOT NULL,
  approvedsymbol TEXT NOT NULL,
  entrezid     INTEGER NOT NULL,
  ensg         TEXT NOT NULL,
  comments     TEXT NOT NULL,
  phenotype    TEXT NOT NULL,
  mousegenesymbol TEXT NOT NULL);

DROP TABLE IF EXISTS morbidmap;

CREATE TABLE morbidmap(
  phenotype    TEXT NOT NULL,
  genesymbols  TEXT NOT NULL,
  mimnumber    INTEGER NOT NULL,
  cytolocation TEXT NOT NULL);


DROP TABLE IF EXISTS orpha;

CREATE TABLE orpha(
  disorder    TEXT NOT NULL,
  orpha_id    INTEGER NOT NULL,
  association TEXT NOT NULL,
  symbol      TEXT NOT NULL,
  assocstatus TEXT NOT NULL, 
  altids      TEXT NOT NULL);

DROP TABLE IF EXISTS gnomad_constraint;

CREATE TABLE gnomad_constraint(
  symbol TEXT NOT NULL,
  enst   TEXT NOT NULL,
  oe_mis REAL  NOT NULL,
  pLI    REAL  NOT NULL,
  pNull  REAL  NOT NULL,
  pRec   REAL  NOT NULL,
  oe_lof REAL  NOT NULL,
  ensg   TEXT NOT NULL);


.mode tabs
.import /projects/RD/CHEO_ROI/source-data/ref_GRCh37.p13_top_level.genecoord.bed gene_bed

.import /projects/RD/CHEO_ROI/source-data/gene_info.tsv gene_info
.import /projects/RD/CHEO_ROI/source-data/gene2ensembl.tsv gene2ensembl

.import /projects/RD/CHEO_ROI/source-data/orpha.tsv orpha
.import /projects/RD/CHEO_ROI/source-data/gnomad_constraint.tsv gnomad_constraint

.import /projects/RD/CHEO_ROI/source-data/mim2gene.tsv mim2gene
.import /projects/RD/CHEO_ROI/source-data/genemap2.tsv genemap2
.import /projects/RD/CHEO_ROI/source-data/morbidmap.tsv morbidmap
