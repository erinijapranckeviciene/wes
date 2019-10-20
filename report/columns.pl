#!/usr/bin/perl
# This script selectively prints report columns from the query 
#
use strict; 
use List::Util qw(max);
#use warnings;

my %colByName;
my %colByPosition;
my $linecount=1;

my @colToPrint_Part1=("Position","UCSC_link","GNOMAD_link","Ref","Alt");
## then zygocity
my @colToPrint_Part2=("Gene");
## then burden  
## then gts
my @colToPrint_Part3=("Variation","Info","Refseq_change","Depth","Quality");
## then alt_depth
## then trio_coverage
my @colToPrint_Part4=("GeneIDv","Gene_description","Omim_gene","Orpha","Clinvar");
my @colToPrint_Part5=("Gnomad_af_popmax_noother","Gnomad_af","Gnomad_ac","Gnomad_an","Gnomad_hom");
my @colToPrint_Part6=("Ensembl_transcript_id","AA_position","Exon","Protein_domains","rsIDs");
my @colToPrint_Part7=("oe_lof","oe_mis","pLI","pRec","pNull","Conserved_in_20_mammals","Sift_score","Polyphen_score","Cadd_score");
my @colToPrint_Part8=("Vest3_score");
my @colToPrint_Part9=("Revel_score","Gerp_score","Splicing","Callers");
my @colToPrint_Part10=("Num_of_callers");
my @colToPrint_Part11=("Old_multiallelic","VType","Impact_severity","Symbol_source","Hugo_entrez","Hugo_ensg","Hugo_symbol","hpo_entrez","hpo_symbol","variant_id");

my $gts="gts";
my $gtaltdepths="gt_alt_depths";
my $gtdepths="gt_depths";
my $burden="burden";

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
for ( grep /\b\Q$gts\E\b/, sort keys %colByName) { 
  my $zygocity = $_;
  $zygocity=~s/gts/Zygocity/;
  print  $zygocity ,"\t"; }

## After Zygocity goes Gene and Burden
print join("\t",@colToPrint_Part2),"\t"; # Part2 is VEP assigned Gene

## Burden burden
for ( grep /\b\Q$burden\E\b/, sort keys %colByName) { 
  print  $_ ,"\t"; }

## Genotypes gts
for ( grep /\b\Q$gts\E\b/, sort keys %colByName) { 
  print  $_ ,"\t"; }

print join("\t",@colToPrint_Part3),"\t";
## Alt_depths and Trio_coverage
print join("\t","Alt_depths","Trio_coverage"),"\t";

print join("\t",@colToPrint_Part4),"\t";
print join("\t",@colToPrint_Part5),"\t";
print join("\t",@colToPrint_Part6),"\t";
print join("\t",@colToPrint_Part7),"\t";


## Here is Vest3 score
print join("\t",@colToPrint_Part8),"\t";

print join("\t",@colToPrint_Part9),"\t";

## Here is number of callers from Callers column
print join("\t",@colToPrint_Part10),"\t";

print join("\t",@colToPrint_Part11),"\n";

}

else{

# read line into hash
my %valueByPos;
@valueByPos{(0..$#fields)}=@fields;

# add new fields
my $position=join(":", $valueByPos{$colByName{"Chrom"}}, $valueByPos{$colByName{"Pos"}});
my $gnomadl=join("-", $valueByPos{$colByName{"Chrom"}}, $valueByPos{$colByName{"Pos"}},$valueByPos{$colByName{"Ref"}},$valueByPos{$colByName{"Alt"}} );

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


for ( grep /\b\Q$gts\E\b/, sort keys %colByName) { 
#  print "\n", $_ ,"\n"; 
#  print $valueByPos{ $colByName{$_} } ,"\n";
  print zygocity($valueByPos{ $colByName{$_} }) ,"\t";
  
}

## Here gene assigned by VEP
print join("\t", @valueByPos{ @colByName{@colToPrint_Part2} } ), "\t";

## Burden
for ( grep /\b\Q$burden\E\b/, sort keys %colByName) { 
  print $valueByPos{ $colByName{$_} } ,"\t";
}

## Genotypes
for ( grep /\b\Q$gts\E\b/, sort keys %colByName) { 
  print $valueByPos{ $colByName{$_} } ,"\t";
}

print join("\t", @valueByPos{ @colByName{@colToPrint_Part3} } ), "\t";

## Alt depths by ; separated
print join(";", @valueByPos{ @colByName {( grep /\b\Q$gtaltdepths\E\b/, sort keys %colByName) } } ), "\t";
## Trio coverage, gt depts by ; separated because excel has its own rules how to interpret and transforms numbers
print join(";", @valueByPos{ @colByName {( grep /\b\Q$gtdepths\E\b/, sort keys %colByName) } } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part4} } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part5} } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part6} } ), "\t";
print join("\t", @valueByPos{ @colByName{@colToPrint_Part7} } ), "\t";

## Vest3 score - max of three values 
my $Vest3 = max split(",", @valueByPos{ @colByName{@colToPrint_Part8} });
print $Vest3, "\t";

print join("\t", @valueByPos{ @colByName{@colToPrint_Part9} } ), "\t";

## Num_of_callers - number of callers that made a call
## Uses Callers column to compute the length of the array
print join("\t", scalar split(",", @valueByPos{ @colByName{"Callers"} } )), "\t";

## Aditional fields that come from Hugo
print join("\t", @valueByPos{ @colByName{@colToPrint_Part11} } ), "\n";


}
$linecount+=1;
}
