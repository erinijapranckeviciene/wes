#!/usr/bin/perl
# Synopsis: create bed file with minimum gene information from gff3
#
use strict; 
use warnings;

while(<>)
{ chop;
#print $_, "\n";
my @fields = split( "\t", $_);
  if ( scalar @fields >1 ){
  my ( $seq, $source, $type, $start, $end, $dot1, $strand, $dot2, $annot ) = @fields;
  if ( ( index($type, "gene")!=-1 ) and ( index($seq, "NC_")!=-1 )  ){
    my @pairs = split( ";", $annot );    
    my %annotations;
    my %dbxref;
    # parse annotations
    foreach my $pair(@pairs){
      my ( $key, $value) = split( "=" , $pair);
      $annotations{$key}=$value; }
    # parse Dbxref
    foreach my $pair( split( ",", $annotations{'Dbxref'} ) ){
      my ( $key, $value) = split( ":" , $pair);
      $dbxref{$key}=$value; }

    
#    while (my ($key, $value) = each %annotations) {print $key,"\t", $value ,"\n"; }
   $seq=~s/^NC\_0+//;    # clean NC_
   $seq=~s/\.[0-9].*$//; # clean .version
   $seq=~s/23/X/;
   $seq=~s/24/Y/;
   $seq=~s/12920/MT/;

   if (! exists $annotations{'description'}) { $annotations{'description'}="NA";}
   else {$annotations{'description'}=~s/ /_/g; } 
   if (exists $annotations{'Name'}) {  
     print $seq, "\t", $start, "\t", $end, "\t", $dbxref{'GeneID'}, "\t", join("\t", $annotations{'Name'}, $annotations{'description'}), "\n";}
   
    }
  }
}


