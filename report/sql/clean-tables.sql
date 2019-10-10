####################################################
# sql statements to create gene level annotations
# to link them to variants,
# merged is an identifier table
####################################################
# part1 
#separate genehistory into replaced and discontinued
#####################################################
.headers on

#####################################################
# replaced
#####################################################

DROP TABLE IF EXISTS replaced;
CREATE TABLE replaced AS SELECT * FROM genehistory WHERE GeneID NOT IN (SELECT DISTINCT Discontinued_GeneID FROM genehistory) AND LENGTH(GeneID)>1;
select * from replaced limit 5;

#sqlite> .schema replaced
#CREATE TABLE replaced(
#  GeneID TEXT,
#  Discontinued_GeneID TEXT,
#  Discontinued_Symbol TEXT,
#  Discontinue_Date TEXT
#);

#sqlite> select * from replaced limit 5;
#7003|8|AA|20061122
#51596|42|ACHAP|20060616
#1261|44|ACHM2|20050509
#54714|45|ACHM3|20050510
#7291|57|ACS3|20050510


#####################################################
# discontinued
#####################################################
DROP TABLE IF EXISTS discontinued;
CREATE TABLE discontinued AS SELECT * FROM genehistory WHERE GeneID IN (SELECT DISTINCT Discontinued_GeneID FROM genehistory) OR LENGTH(GeneID)==1;
select * from discontinued limit 5;

#sqlite> .schema discontinued
#CREATE TABLE discontinued(
#  GeneID TEXT,
#  Discontinued_GeneID TEXT,
#  Discontinued_Symbol TEXT,
#  Discontinue_Date TEXT
#);
#sqlite> select * from discontinued limit 10;
#-|4|A12M1|20050508
#-|5|A12M2|20050510
#-|6|A12M3|20050510
#-|7|A12M4|20050510
#-|65|ACTBP5|20100427
#-|84|ACTL4|20130314
#-|85|ACTL5|20100520
#-|129|ADH5P1|20081010
#-|138|ADORA2L1|20050510
#-|139|ADORA2L2|20050510


# Left join replaced and discontinued with merged, so that we know which of the genes in the report are no longer supported
DROP TABLE IF EXISTS part1;
CREATE TABLE part1 AS SELECT * FROM (SELECT symbol AS merged_symbol, 
                      geneid AS merged_geneid, 
                      GeneID AS replaced_geneid, 
                      Discontinued_GeneID AS replaced_discontinued_geneid, 
                      Discontinued_Symbol AS replaced_discontinued_symbol, 
                      Discontinue_Date AS replaced_date FROM (SELECT * FROM merged LEFT JOIN replaced ON merged.geneid=replaced.GeneID) ) m 
                                                               LEFT JOIN discontinued ON m.merged_geneid=discontinued.Discontinued_GeneID;
.schema part1 
select * from part1 limit 5;

#sqlite> .schema part1
#CREATE TABLE part1(
#  merged_symbol TEXT,
#  merged_geneid TEXT,
#  replaced_geneid TEXT,
#  replaced_discontinued_geneid TEXT,
#  replaced_discontinued_symbol TEXT,
#  replaced_date TEXT,
#  GeneID TEXT,
#  Discontinued_GeneID TEXT,
#  Discontinued_Symbol TEXT,
#  Discontinue_Date TEXT
#);

###############
## Example 1
##############
#sqlite> select * from part1  limit 5;
#merged_symbol|merged_geneid|replaced_geneid|replaced_discontinued_geneid|replaced_discontinued_symbol|replaced_date|GeneID|Discontinued_GeneID|Discontinued_Symbol|Discontinue_Date
#3.8-1.3|353008|353008|||||||
#3.8-1.4|353009|353009|||||||
#3.8-1.5|353010|353010|||||||
#5-HT3C2|389180|389180|100422427|LOC100422427|20100813||||
#5S_rRNA|ENSG00000201285|ENSG00000201285|||||||

###############
## Example 1
##############
#sqlite> select * from part1 where length(Discontinue_Date)>1 limit 5;
#merged_symbol|merged_geneid|replaced_geneid|replaced_discontinued_geneid|replaced_discontinued_symbol|replaced_date|GeneID|Discontinued_GeneID|Discontinued_Symbol|Discontinue_Date
#ASAH2C|653365|653365||||-|653365|ASAH2C|20140409
#BRWD1-IT2|257357|257357||||-|257357|BRWD1-IT2|20140408
#C14orf99|317730|317730||||-|317730|C14orf99|20170818
#CRIPAK|285464|285464||||-|285464|CRIPAK|20190702
#CSPG4P8|440297|440297||||-|440297|CSPG4P8|20140403


####################################################
# part2 
####################################################

# OMIM genemap2 tables that can be  linked by 
# Entrez_Gene_ID and Ensembl_Gene_ID
# How we do it? 
#
####################################################

####################################################
# How many records from genemap2 have to be manually
# curated? The records that have Phenotype (3)
####################################################

# Create table to separate the OMIM genemap2 
# Phenotype (3) records that can't be linked
# to the merged identifiers
DROP TABLE IF EXISTS omim2curate7phen3items;
CREATE TABLE omim2curate7phen3items AS SELECT * FROM genemap2 WHERE
               Ensembl_Gene_ID NOT IN (SELECT DISTINCT GeneID FROM merged) AND 
               Entrez_Gene_ID  NOT IN (SELECT DISTINCT GeneID FROM merged) AND 
               INSTR(Phenotypes,'(3)')>0;

.schema omim2curate7phen3items
select * from omim2curate7phen3items;

#sqlite> .schema omim2curate7phen3items
#CREATE TABLE omim2curate7phen3items(
#  Chromosome TEXT,
#  Genomic_Position_Start TEXT,
#  Genomic_Position_End TEXT,
#  Cyto_Location TEXT,
#  Computed_Cyto_Location TEXT,
#  Mim_Number TEXT,
#  Gene_Symbols TEXT,
#  Gene_Name TEXT,
#  Approved_Symbol TEXT,
#  Entrez_Gene_ID TEXT,
#  Ensembl_Gene_ID TEXT,
#  Comments TEXT,
#  Phenotypes TEXT,
#  "Mouse_Gene_Symbol/ID" TEXT
#);

# There are 4139 Phenotypes (3) , total 4136 corresponding Entrez IDs and 4121 corresponding Ensembl Ids , 7 can't be linked. 

#sqlite> select * from genemap2 where Ensembl_Gene_ID not in (select distinct GeneID from merged) and Entrez_Gene_ID not in (select distinct GeneID from merged) and instr(Phenotypes,'(3)')>0;
#chr3|161000000|183000000|3q26||600049|MDS1|Myelodysplasia_syndrome-1||||cen--EVI1--MDS1--EAP--tel|Myelodysplasia_syndrome-1_(3)|
#chr6|98900000|100000000|6q16.2||616842|DHS6S1,_MCDR1|DNase1_hypersensitivity,_chromosome_6,_site_1||107305681||upstream_of_PRDM13_and_CCNC|Macular_dystrophy,_North_Carolina_type,_136550_(3),_Autosomal_dominant|
#chr11|1998744|2003508|11p15.5|11p15.5|616186|ICR1|H19-IGF2-imprinting_control_region||105259599|||Beckwith-Wiedemann_syndrome,_130650_(3),_Autosomal_dominant|
#chr11|5269924|5304185|11p15.5|11p15.4|152424|LCRB|Locus_control_region_beta||109580095|||Thalassemia,_Hispanic_gamma-delta-beta,_613985_(3)|
#chr13|54700000|72800000|13q21||613289|ATXN8|Ataxin_8|ATXN8|724066||CAG_repeat_results_in_polyglutamine_expansion_protein|Spinocerebellar_ataxia_8,_608768_(3),_Autosomal_dominant|
#chr20|28100000|64444167|20q11-q13||617352|MBCS|Mulchandani-Bhoj-Conlin_syndrome||||maternal_uniparental_disomy_of_imprinted_region|Mulchandani-Bhoj-Conlin_syndrome,_617352_(3)|
#chrX|0|6100000|Xpter-p22.32||314700|XG|Xg_blood_group||||nonlyonizing,_spans_pseudoautosomal_boundary,_XGPY_on_Yq11.21|[Blood_group,_XG_system]_(3)|

# In total 16943 items in genemap2 out of these in general 1416 can't be linked to merged idetifiers

DROP TABLE IF EXISTS omim2curate1416items;
CREATE TABLE omim2curate1416items AS SELECT * FROM genemap2 WHERE
            Ensembl_Gene_ID NOT IN (SELECT DISTINCT GeneID FROM merged) AND
            Entrez_Gene_ID  NOT IN (SELECT DISTINCT GeneID FROM merged);

#sqlite> select count(*) from omim2curate1416items;
#1416
## In this part2 maybe select only phenotype(3)
DROP TABLE IF EXISTS part2;
CREATE TABLE part2 AS SELECT * FROM (SELECT symbol AS merged_symbol, 
                                            geneid AS merged_geneid, 
                                            Mim_Number AS mimn, 
                                            Gene_Symbols AS genesymbols, 
                                            Gene_Name AS genename, 
                                            Approved_Symbol AS approvedsymbol, 
                                            Entrez_Gene_ID AS entrezid, 
                                            Ensembl_Gene_ID AS ensg, 
                                            Phenotypes AS phen FROM
                                     (SELECT * FROM merged LEFT JOIN genemap2 ON merged.geneid=genemap2.Entrez_Gene_ID)) p1 
                                      LEFT JOIN genemap2 ON p1.merged_geneid=genemap2.Ensembl_Gene_ID;
select * from part2 limit 5;

# part2  is a join on entrez and ensembl gene ids to the merged identifiers
#sqlite> .schema part2
#CREATE TABLE part2(
#  merged_symbol TEXT,
#  merged_geneid TEXT,
#  mimn TEXT,
#  genesymbols TEXT,
#  genename TEXT,
#  approvedsymbol TEXT,
#  entrezid TEXT,
#  ensg TEXT,
#  phen TEXT,
#  Chromosome TEXT,
#  Genomic_Position_Start TEXT,
#  Genomic_Position_End TEXT,
#  Cyto_Location TEXT,
#  Computed_Cyto_Location TEXT,
#  Mim_Number TEXT,
#  Gene_Symbols TEXT,
#  Gene_Name TEXT,
#  Approved_Symbol TEXT,
#  Entrez_Gene_ID TEXT,
#  Ensembl_Gene_ID TEXT,
#  Comments TEXT,
#  Phenotypes TEXT,
#  "Mouse_Gene_Symbol/ID" TEXT
#);
################################################
#sqlite> select * from part2 limit .. edited;
#merged_symbol|merged_geneid|mimn|genesymbols|genename|approvedsymbol|entrezid|ensg|phen|Chromosome|Genomic_Position_Start|Genomic_Position_End|Cyto_Location|Computed_Cyto_Location|Mim_Number|Gene_Symbols|Gene_Name|Approved_Symbol|Entrez_Gene_ID|Ensembl_Gene_ID|Comments|Phenotypes|Mouse_Gene_Symbol/ID
#7SK|ENSG00000254144|||||||||||||||||||||
#7SK|ENSG00000260682|||||||||||||||||||||
#7SK|ENSG00000271765|||||||||||||||||||||
#7SK|ENSG00000271814|||||||||||||||||||||
#7SK|ENSG00000271818|||||||||||||||||||||
#A1BG|1|138670|A1BG|Glycoprotein,_alpha-1B|A1BG|1|ENSG00000121410|||||||||||||||
#A1BG|ENSG00000121410||||||||chr19|58345182|58353491|19cen-q13.2|19q13.43|138670|A1BG|Glycoprotein,_alpha-1B|A1BG|1|ENSG00000121410|order:__C3-SE-LU-A1BG||A1bg_(MGI:2152878)
#A1BG-AS1|503538|||||||||||||||||||||
#A1BG-AS1|ENSG00000268895|||||||||||||||||||||
#A1CF|29974|618199|A1CF,_ASP|APOBEC1_complementation_factor|A1CF|29974|ENSG00000148584|||||||||||||||
#A1CF|ENSG00000148584||||||||chr10|50799408|50885674|10q11.21|10q11.23|618199|A1CF,_ASP|APOBEC1_complementation_factor|A1CF|29974|ENSG00000148584|||A1cf_(MGI:1917115)

####################################################
# part3  
####################################################
# orpha tables that can be  linked.
# ORPHA link is symbol
# How we do the linking  with merged symbols? 
#   First - the symbols that are in merged , the orpha is linked to those
#   from 4023 genes in ORPHA we will link 3894 and 129 not
#   Second the symbols that are not in merged- what we do?
#   select entrez and ensg from hugo by symbol,
#   95 records are selected 
###################################################

#sqlite> select count(distinct Gene_symbol) from orpha where Gene_symbol in (select distinct upper(symbol) from merged);
#count(distinct Gene_symbol)
#3894
#sqlite> select count(distinct Gene_symbol) from orpha where Gene_symbol not in (select distinct upper(symbol) from merged);
#count(distinct Gene_symbol)
#129

DROP TABLE IF EXISTS orphalinkbysym3894;
CREATE TABLE orphalinkbysym3894 AS SELECT 
   symbol, 
   geneid, 
   Disorder_name, 
   Disorder_OrphaNumber,
   Gene_symbol  FROM
(SELECT * FROM merged LEFT JOIN orpha ON merged.symbol=orpha.Gene_symbol);

#sqlite> .schema  orphalinkbysym3894
#CREATE TABLE orphalinkbysym3894(
#  symbol TEXT,
#  geneid TEXT,
#  Disorder_name TEXT,
#  Disorder_OrphaNumber TEXT,
#  Gene_symbol TEXT,
#);
#####################################################################################
select * from orphalinkbysym3894 limit 30;

#sqlite> select * from part3 limit .. edited;
#symbol|geneid|Disorder_name|Disorder_OrphaNumber|Association_type|Gene_symbol|Association_status|Gene_alternate_IDs
#A1CF|29974||||||
#A1CF|ENSG00000148584||||||
#A2M|2||||||
#A2M|ENSG00000175899||||||
#A2M-AS1|144571||||||
#A2M-AS1|ENSG00000245105||||||
#A2ML1|144568|Noonan_syndrome|648|Disease-causing_germline_mutation(s)_in|A2ML1|Assessed|A2ML1,p170,FLJ25179,A8K2U0,23336,610627,ENSG00000166535
#A2ML1|ENSG00000166535|Noonan_syndrome|648|Disease-causing_germline_mutation(s)_in|A2ML1|Assessed|A2ML1,p170,FLJ25179,A8K2U0,23336,610627,ENSG00000166535
#A2ML1-AS1|ENSG00000256661||||||
#A2ML1-AS2|ENSG00000256904||||||
#A2MP1|3||||||
#A2MP1|ENSG00000256069||||||

#AAAS|8086|Triple_A_syndrome|869|Disease-causing_germline_mutation(s)_in|AAAS|Assessed|ENSG00000094914,605378,Allgrove,_triple-A,Q9NRG9,adracalin,aladin,13666,AAAS
#AAAS|ENSG00000094914|Triple_A_syndrome|869|Disease-causing_germline_mutation(s)_in|AAAS|Assessed|ENSG00000094914,605378,Allgrove,_triple-A,Q9NRG9,adracalin,aladin,13666,AAAS
#AACP|11||||||
########################################################################################

# this table had 95 ORPHA identifiers that can be linked to the merged through entrez id , then 34 still remains
DROP TABLE  IF EXISTS orphaentrezlink95;
DROP TABLE  IF EXISTS tmp1;

CREATE TABLE tmp1 AS SELECT 
           h.symbol AS hsymbol, 
           h.entrez_id AS hentrez, 
           h.ensembl_gene_id AS hensg, 
           o.Gene_symbol,
           o.Disorder_name,
           o.Disorder_OrphaNumber FROM hgnc h, orpha o WHERE
 o.Gene_symbol NOT IN (SELECT DISTINCT UPPER(symbol) FROM merged) 
 AND (o.Gene_symbol=h.symbol OR 
      o.Gene_symbol=h.alias_symbol OR
      o.Gene_symbol=h.prev_symbol);
 
CREATE TABLE orphaentrezlink95 AS SELECT * FROM tmp1 WHERE 
      hentrez IN (SELECT DISTINCT geneid FROM merged) ;

select * from orphaentrezlink95 limit 5;

# here part3 is formed by orpha

DROP TABLE  IF EXISTS part3;
CREATE TABLE part3 AS SELECT * FROM
   (SELECT * FROM orphalinkbysym3894 LEFT JOIN orphaentrezlink95 ON
   orphalinkbysym3894.geneid=orphaentrezlink95.hentrez) h 
   LEFT JOIN orphaentrezlink95 ON h.geneid=orphaentrezlink95.hensg;

.schema part3
select * from part3 limit 5; 

#sqlite> .schema part3
#CREATE TABLE part3(
#  symbol TEXT,
#  geneid TEXT,
#  Disorder_name TEXT,
#  Disorder_OrphaNumber TEXT,
#  Gene_symbol TEXT,
#  hsymbol TEXT,
#  hentrez TEXT,
#  hensg TEXT,
#  "Disorder_name:1" TEXT,
#  "Disorder_OrphaNumber:1" TEXT,
#  "Gene_symbol:1" TEXT,
#  "hsymbol:1" TEXT,
#  "hentrez:1" TEXT,
#  "hensg:1" TEXT,
#  "Disorder_name:2" TEXT,
#  "Disorder_OrphaNumber:2" TEXT,
#  "Gene_symbol:2" TEXT
#);


# This table has 34 items from ORPHA that needs curation
DROP TABLE  IF EXISTS orpha2curateitems34;
CREATE TABLE orpha2curateitems34 AS SELECT DISTINCT Gene_symbol, * FROM orpha 
   WHERE Gene_symbol NOT IN (SELECT DISTINCT UPPER(symbol) FROM merged) AND
   Gene_symbol NOT IN (SELECT DISTINCT hsymbol FROM orphaentrezlink95);

select * from orpha2curateitems34 limit 10;

#sqlite> select count(*) from orpha2curateitems34 ;
#count(*)
#34
#sqlite> select * from orpha2curateitems34 ;
#Gene_symbol|Disorder_name|Disorder_OrphaNumber|Association_type|Gene_symbol:1|Association_status|Gene_alternate_IDs
#SPG34|X-linked_spastic_paraplegia_type_34|171607|Disease-causing_germline_mutation(s)_in|SPG34|Assessed|32944
#SPG37|Autosomal_dominant_spastic_paraplegia_type_37|171612|Disease-causing_germline_mutation(s)_in|SPG37|Assessed|33472
#SPG38|Autosomal_dominant_spastic_paraplegia_type_38|171617|Disease-causing_germline_mutation(s)_in|SPG38|Assessed|33485
#SPG32|Autosomal_recessive_spastic_paraplegia_type_32|171622|Disease-causing_germline_mutation(s)_in|SPG32|Assessed|32314,SPG29
#GINGF2|Hereditary_gingival_fibromatosis|2024|Candidate_gene_tested_in|GINGF2|Not_yet_assessed|14252,GGF2,HGF2
#HELLPAR|HELLP_syndrome|244242|Major_susceptibility_factor_in|HELLPAR|Assessed|ENSG00000281344,LINC-HELLP,614985,43984,Long_intergenic_non-protein_coding_RNA_associated_with_HELLP_syndrome
#SCA32|Spinocerebellar_ataxia_type_32|276183|Disease-causing_germline_mutation(s)_in|SCA32|Assessed|37475
#SCA30|Spinocerebellar_ataxia_type_30|211017|Disease-causing_germline_mutation(s)_in|SCA30|Assessed|33445
#USH1K|Usher_syndrome_type_1|231169|Disease-causing_germline_mutation(s)_in|USH1K|Assessed|43724
#USH1E|Usher_syndrome_type_1|231169|Disease-causing_germline_mutation(s)_in|USH1E|Assessed|12599
#USH1H|Usher_syndrome_type_1|231169|Disease-causing_germline_mutation(s)_in|USH1H|Assessed|22433
#SPG41|Autosomal_dominant_spastic_paraplegia_type_41|320355|Disease-causing_germline_mutation(s)_in|SPG41|Assessed|34382,613364
#SPG36|Autosomal_dominant_spastic_paraplegia_type_36|320365|Disease-causing_germline_mutation(s)_in|SPG36|Assessed|33240
#DYT17|Primary_dystonia,_DYT17_type|370103|Disease-causing_germline_mutation(s)_in|DYT17|Assessed|35416
#SCA37|Spinocerebellar_ataxia_type_37|363710|Disease-causing_germline_mutation(s)_in|SCA37|Assessed|43726
#DYT21|Primary_dystonia,_DYT21_type|306734|Disease-causing_germline_mutation(s)_in|DYT21|Assessed|39436
#KIF1BP|Goldberg-Shprintzen_megacolon_syndrome|66629|Disease-causing_germline_mutation(s)_(loss_of_function)_in|KIF1BP|Assessed|23419,DKFZP586B0923,609367,kinesin_binding_protein,KBP,KIF1BP,TTC20,ENSG00000198954,Q96EK5
#DHS6S1|North_Carolina_macular_dystrophy|75327|Disease-causing_germline_mutation(s)_in|DHS6S1|Assessed|616842
#DYT15|Myoclonus-dystonia_syndrome|36899|Role_in_the_phenotype_of|DYT15|Assessed|31376
#DYT13|Primary_dystonia,_DYT13_type|98807|Disease-causing_germline_mutation(s)_in|DYT13|Assessed|3101
#OPA2|Early-onset_X-linked_optic_atrophy|98890|Disease-causing_germline_mutation(s)_in|OPA2|Assessed|8141
#ATXN8|Spinocerebellar_ataxia_type_8|98760|Disease-causing_germline_mutation(s)_in|ATXN8|Assessed|ATXN8,613289,Q156A1,32925
#SCA25|Spinocerebellar_ataxia_type_25|101111|Disease-causing_germline_mutation(s)_in|SCA25|Assessed|20684
#SCA20|Spinocerebellar_ataxia_type_20|101110|Disease-causing_germline_mutation(s)_in|SCA20|Assessed|17204
#SPG29|Autosomal_dominant_spastic_paraplegia_type_29|101009|Disease-causing_germline_mutation(s)_in|SPG29|Assessed|30161
#SPG19|Autosomal_dominant_spastic_paraplegia_type_19|100999|Disease-causing_germline_mutation(s)_in|SPG19|Assessed|16706
#SPG16|X-linked_spastic_paraplegia_type_16|100997|Disease-causing_germline_mutation(s)_in|SPG16|Assessed|14260
#SPG14|Autosomal_recessive_spastic_paraplegia_type_14|100995|Disease-causing_germline_mutation(s)_in|SPG14|Assessed|13730
#SPG27|Autosomal_recessive_spastic_paraplegia_type_27|101007|Disease-causing_germline_mutation(s)_in|SPG27|Assessed|26071
#SPG25|Autosomal_recessive_spastic_paraplegia_type_25|101005|Disease-causing_germline_mutation(s)_in|SPG25|Assessed|25855
#SPG23|Autosomal_recessive_spastic_paraplegia_type_23|101003|Disease-causing_germline_mutation(s)_in|SPG23|Assessed|21340
#SPG24|Autosomal_recessive_spastic_paraplegia_type_24|101004|Disease-causing_germline_mutation(s)_in|SPG24|Assessed|22993
#FMR3|FRAXE_intellectual_disability|100973|Disease-causing_germline_mutation(s)_in|FMR3|Assessed|3777,FMR3
#SLC7A2-IT1|Ravine_syndrome|99852|Disease-causing_germline_mutation(s)_in|SLC7A2-IT1|Assessed|


####################################################
# part4 link with gnomadlof 
# gnomad lof is determined by ensg
####################################################

#sqlite> select count(distinct gene_id) from gnomadconstr where gene_id in (select distinct geneid from merged);
#19704
# create table to join by symbol so that ensg and entrez qould be covered
DROP TABLE  IF EXISTS part4;
CREATE TABLE part4 AS SELECT * FROM merged LEFT JOIN
   (SELECT m.symbol AS symid , m.geneid AS mgeneid, g.* FROM
     merged m, gnomadconstr g WHERE mgeneid=g.gene_id) gm ON
     merged.symbol=gm.symid;

select * from part4 limit 10;

#sqlite> .schema part4
#CREATE TABLE part4(
#  symbol TEXT,
#  geneid TEXT,
#  symid TEXT,
#  mgeneid TEXT,
#  gene TEXT,
#  transcript TEXT,
#  obs_mis TEXT,
#  exp_mis TEXT,
#  oe_mis TEXT,
#  mu_mis TEXT,
#  possible_mis TEXT,
#  obs_mis_pphen TEXT,
#  exp_mis_pphen TEXT,
#  oe_mis_pphen TEXT,
#  possible_mis_pphen TEXT,
#  obs_syn TEXT,
#  exp_syn TEXT,
#  oe_syn TEXT,
#  mu_syn TEXT,
#  possible_syn TEXT,
#  obs_lof TEXT,
#  mu_lof TEXT,
#  possible_lof TEXT,
#  exp_lof TEXT,
#  pLI TEXT,
#  pNull TEXT,
#  pRec TEXT,
#  oe_lof TEXT,
#  oe_syn_lower TEXT,
#  oe_syn_upper TEXT,
#  oe_mis_lower TEXT,
#  oe_mis_upper TEXT,
#  oe_lof_lower TEXT,
#  oe_lof_upper TEXT,
#  constraint_flag TEXT,
#  syn_z TEXT,
#  mis_z TEXT,
#  lof_z TEXT,
#  oe_lof_upper_rank TEXT,
#  oe_lof_upper_bin TEXT,
#  oe_lof_upper_bin_6 TEXT,
#  n_sites TEXT,
#  classic_caf TEXT,
#  max_af TEXT,
#  no_lofs TEXT,
#  obs_het_lof TEXT,
#  obs_hom_lof TEXT,
#  defined TEXT,
#  p TEXT,
#  exp_hom_lof TEXT,
#  classic_caf_afr TEXT,
#  classic_caf_amr TEXT,
#  classic_caf_asj TEXT,
#  classic_caf_eas TEXT,
#  classic_caf_fin TEXT,
#  classic_caf_nfe TEXT,
#  classic_caf_oth TEXT,
#  classic_caf_sas TEXT,
#  p_afr TEXT,
#  p_amr TEXT,
#  p_asj TEXT,
#  p_eas TEXT,
#  p_fin TEXT,
#  p_nfe TEXT,
#  p_oth TEXT,
#  p_sas TEXT,
#  transcript_type TEXT,
#  gene_id TEXT,
#  transcript_level TEXT,
#  cds_length TEXT,
#  num_coding_exons TEXT,
#  gene_type TEXT,
#  gene_length TEXT,
#  exac_pLI TEXT,
#  exac_obs_lof TEXT,
#  exac_exp_lof TEXT,
#  exac_oe_lof TEXT,
#  brain_expression TEXT,
#  chromosome TEXT,
#  start_position TEXT,
#  end_position TEXT
#);

########################################
# create annotation tables
########################################

# OMIM
DROP TABLE  IF EXISTS omimannot;
CREATE TABLE omimannot AS SELECT
    merged_symbol, 
    merged_geneid,
    IFNULL(mimn, Mim_Number) AS mimnumber, 
    IFNULL(genesymbols, Gene_Symbols) AS gsymbols, 
    IFNULL(genename, Gene_Name) AS gname, 
    IFNULL(phen,Phenotypes) AS gphenotypes FROM part2 WHERE mimnumber >0;

#sqlite> .schema omimannot
#CREATE TABLE omimannot(
#  merged_symbol TEXT,
#  merged_geneid TEXT,
#  mimnumber,
#  gsymbols,
#  gname,
#  gphenotypes
#);
.schema omimannot
select * from omimannot limit 5;

# ORPHA
DROP TABLE  IF EXISTS orphaunngrouped;
CREATE TABLE orphaunngrouped AS SELECT 
   symbol, 
   geneid, 
   IFNULL(IFNULL("Disorder_OrphaNumber","Disorder_OrphaNumber:1"),"Disorder_OrphaNumber:2") AS orphanum, 
   IFNULL(IFNULL("Disorder_name","Disorder_name:1"),"Disorder_name:2") AS disorder 
FROM part3 WHERE orphanum >0;

#sqlite> .schema orphaunngrouped
#CREATE TABLE orphaunngrouped(
#  symbol TEXT,
#  geneid TEXT,
#  orphanum,
#  disorder
#);

# Group the diseases
DROP TABLE  IF EXISTS orphaannot;
CREATE TABLE orphaannot AS SELECT 
   GROUP_CONCAT(DISTINCT symbol) AS symbol, 
   geneid, 
   GROUP_CONCAT( '[' || orphanum || ':' || disorder || ']') AS disorders 
FROM orphaunngrouped GROUP BY geneid ORDER BY symbol;

.schema orphaannot
select * from orphaannot limit 5;

#sqlite> .schema orphaannot
#CREATE TABLE orphaannot(
#  symbol,
#  geneid TEXT,
#  disorders
#);

DROP TABLE  IF EXISTS gnomadconstrannot;
CREATE TABLE gnomadconstrannot AS SELECT 
   symbol, 
   geneid, 
   oe_lof, 
   oe_mis, 
   pLI,
   pNull, 
   pRec FROM part4 WHERE oe_lof>0;

.schema gnomadconstrannot
select * from gnomadconstrannot limit 5;

#sqlite> .schema gnomadconstrannot
#CREATE TABLE gnomadconstrannot(
#  symbol TEXT,
#  geneid TEXT,
#  oe_lof TEXT,
#  oe_mis TEXT,
#  pLI TEXT,
#  pNull TEXT,
#  pRec TEXT
#);

DROP TABLE IF EXISTS history;
CREATE TABLE history AS SELECT * FROM part1 WHERE
    LENGTH(replaced_date)>0 OR LENGTH(Discontinue_Date)>0;

.schema history
select * from history limit 5;

# How many HPO terms will not have hits in merged ?
# 142 by symbol and only 7 by entrezid

#sqlite> select count(distinct "gene-symbol") from hpo 
# where "gene-symbol" not in (select distinct symbol from merged);
#142
#sqlite> select count(distinct "gene-id(entrez)") from hpo where "gene-id(entrez)" not
#in (select distinct geneid from merged);
#7
#sqlite> select distinct "gene-symbol","gene-id(entrez)" from hpo where "gene-id(entrez
#)" not in (select distinct geneid from merged);
#WHCR|7467
#H19-ICR|105259599
#ATXN8|724066
#HBB-LCR|109580095
#HELLPAR|101101692
#MKRN3-AS1|10108
#FRA16E|



##########################################
# export annotation tables
##########################################
#.mode tabs
#.headers on

#.output history.csv
#select * from history;

#.output omimannot.csv
#select * from omimannot;

#.output orphaannot.csv
#select * from orphaannot;

#.output gnomadconstrannot.csv
#select * from gnomadconstrannot;

