#!/usr/bin/perl
# This script selectively prints report columns from the query 
#
use strict; 
#use warnings;

my %colByName;
my %colByPosition;
my $linecount=1;

my @colToPrint_Part1=("Position","UCSC_link","GNOMAD_link","Ref","Alt","VType");
## then zygocity
my @colToPrint_Part2=("Gene","Symbol_source");
## then gts
my @colToPrint_Part3=("Variation","Impact_severity","total_number_of_variant_impacts_in_gemini","Info","Refseq_change","Depth","Quality");
## then alt_depth
## then trio_coverage
my @colToPrint_Part4=("Ensembl_gene_id","Gene_info_description","Entrezid","Omim","Orpha","Clinvar");
my @colToPrint_Part5=("Gnomad_af_popmax_cheo","Gnomad_af_popmax_noother_cheo","Gnomad_ac_cheo","Gnomad_an_cheo","Gnomad_hom");
my @colToPrint_Part6=("Ensembl_transcript_id","AA_position","Exon","Protein_domains","rsIDs");
my @colToPrint_Part7=("Gnomad_LOF","Conserved_in_20_mammals_dbnsfp","Sift_score","Polyphen_score","Cadd_score_dbnsfp","Vest3_score_dbnsfp","Revel_score_dbnsfp","Gerp_score_dbnsfp","Spliceregion","Maxentscan_alt","Maxentscan_diff","Maxentscan_ref","Callers","Old_multiallelic");


my $gts="gts";
my $gtaltdepths="gt_alt_depths";
my $gtdepths="gt_depths";

##  Possibly change the header fields/ TO DO Later /
#my @colNameToPrint=("Position","UCSC_Link","GNOMAD_Link","Ref","Alt","Gene");


while(<>)
{ chop;

my @fields = split( "\t", $_);

# line 1 is header
if ($linecount == 1)
{

@colByPosition{(0..$#fields)}=@fields;
@colByName{@fields}=(0..$#fields);

$colByName{"Position"}=$#fields+1;
$colByPosition{$#fields+1}="Position";

$colByName{"UCSC_link"}=$#fields+2;
$colByPosition{$#fields+2}="UCSC_link";

$colByName{"GNOMAD_link"}=$#fields+3;
$colByPosition{$#fields+3}="GNOMAD_link";

## Print to test uncomment 
## foreach my $h(sort keys %colByPosition){ print $h,"\t",$colByPosition{$h},"\n"; }
## foreach my $h(sort keys %colByName){ print $h,"\t",$colByName{$h},"\n"; }


## Start printing header
print join("\t",@colToPrint_Part1),"\t";

## Zygocity - change gts word into zygocity
for ( grep /\b\Q$gts\E\b/, keys %colByName) { 
  my $zygocity = $_;
  $zygocity=~s/gts/Zygocity/;
  print  $zygocity ,"\t"; }

print join("\t",@colToPrint_Part2),"\t";

## Genotypes gts
for ( grep /\b\Q$gts\E\b/, keys %colByName) { 
  print  $_ ,"\t"; }

print join("\t",@colToPrint_Part3),"\t";
## Alt_depths and Trio_coverage
print join("\t","Alt_depths","Trio_coverage"),"\t";

print join("\t",@colToPrint_Part4),"\t";
print join("\t",@colToPrint_Part5),"\t";
print join("\t",@colToPrint_Part6),"\t";
print join("\t",@colToPrint_Part7),"\n";

}

else{

# read line into hash
my %valueByPos;
@valueByPos{(0..$#fields)}=@fields;

# add new fields
my $position=join(":", $valueByPos{$colByName{"Chrom_geminiv"}}, $valueByPos{$colByName{"Pos_geminiv"}});
my $gnomadl=join("-", $valueByPos{$colByName{"Chrom_geminiv"}}, $valueByPos{$colByName{"Pos_geminiv"}},$valueByPos{$colByName{"Ref_geminiv"}},$valueByPos{$colByName{"Alt_geminiv"}} );

my $ucsclink='=HYPERLINK("http://genome.ucsc.edu/cgi-bin/hgTracks?db=hg19&hgt.out3=10x&position='.$position.'","UCSC_link")';
my $gnomadlink='=HYPERLINK("http://gnomad.broadinstitute.org/variant/'.$gnomadl.'","GNOMAD_link")';

$valueByPos{$#fields+1}=$position;
$valueByPos{$#fields+2}=$ucsclink;
$valueByPos{$#fields+3}=$gnomadlink;

print join("\t", @valueByPos{ @colByName{@colToPrint_Part1} } ), "\t";
# Zygosity

sub zygocity {
  my ($gt) =@_;
  my @parts=split("/",$gt);
  if ($parts[0] eq $parts[1]) { return 'Hom';} else {return 'Het';}
}


for ( grep /\b\Q$gts\E\b/, keys %colByName) { 
#  print "\n", $_ ,"\n"; 
#  print $valueByPos{ $colByName{$_} } ,"\n";
  print zygocity($valueByPos{ $colByName{$_} }) ,"\t";
  
}

print join("\t", @valueByPos{ @colByName{@colToPrint_Part2} } ), "\t";

## Genotypes
for ( grep /\b\Q$gts\E\b/, keys %colByName) { 
  print $valueByPos{ $colByName{$_} } ,"\t";
}

print join("\t", @valueByPos{ @colByName{@colToPrint_Part3} } ), "\t";

## Alt depths comma separated
print join(",", @valueByPos{ @colByName {( grep /\b\Q$gtaltdepths\E\b/, keys %colByName) } } ), "\t";
## Trio covrage, gt depts comma separated
print join(",", @valueByPos{ @colByName {( grep /\b\Q$gtdepths\E\b/, keys %colByName) } } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part4} } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part5} } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part6} } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part7} } ), "\n";


}
$linecount+=1;
}
