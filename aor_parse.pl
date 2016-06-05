#!/usr/bin/perl

#################################################################################################
#
# parse_aor.pl perl script  v8.0  25 Jul 2013 written by N. Silbermann, Spitzer Science Center
# [a quick and dirty script that gets the job done]
#
# This perl script reads in a Spitzer AOR file and, for those AORs in the file where 
# RESOURCE ESTIMATES exist (INTEGRATION_TIME line), outputs basic information for the AOR
# [useful to then cut & paste into a Spitzer proposal as a start on the observation summary table].
# Output is to the screen (standard output) or to an output file.
#
# The script will ask the user to enter three things:
# 1. Input AOR file name: 
# 2. Choose output delimiter (enter a space, |, or &; default is |):
# 3. Output to screen (enter a 1) or file (enter a 2; filename.aor => filename_parsed.txt):
#
# Example:
# > perl parse_aorfile.pl
# Input AOR file name: test.aor
# Choose output delimiter (i.e. a space, |, or &; default is |): |
# Output to screen (enter a 1) or file (enter a 2; filename.aor => filename_parsed.txt): 1
#
# The output appears on the screen as below:
#  AOR# | Target_Name | RA | Dec | AOT | Est. Flux | On-source Times |
#  1|NGC 1365|3h33m36.37s|-36d08m25.4s|IRAC Mapping| FD_3.6_MIN=10.0, FD_3.6_MAX=10.0, FD_4.5_MIN=20.0, FD_4.5_MAX=20.0, FD_5.8_MIN=15.0, FD_5.8_MAX=15.0, FD_8.0_MIN=12.0, FD_8.0_MAX=12.0 |IRAC_3_6=12.0 IRAC_4_5=12.0 IRAC_5_8=12.0 IRAC_8_0=12.0   | 
#  2|NGC 1365|3h33m36.37s|-36d08m25.4s|MIPS Photometry| 0 |MIPS_24=48.2 MIPS_70=125.8 MIPS_160=179.0    | 
#  3|NGC 1365|3h33m36.37s|-36d08m25.4s|MIPS Scan Map| 0 |MIPS_24=41.9 MIPS_70=41.9 MIPS_160=4.2    | 
#  4|NGC 1365|3h33m36.37s|-36d08m25.4s|IRS Staring| FD_14.75=1.0, FD_28.0=21.0, FD_17.5=31.0, FD_30.5=41.0 |IRS_HI_10=12.6 IRS_HI_19=121.9 IRS_LO_5=121.9 IRS_LO_7=121.9 IRS_LO_14=29.3 IRS_LO_20=29.3 |
#  5|Jupiter|Jupiter|599|IRAC Mapping| 0 |IRAC_3_6=12.0 IRAC_4_5=12.0 IRAC_5_8=12.0 IRAC_8_0=12.0   |
#
#
# Caveats: 
#  1. Output will be generated only for those AORs that have INTEGRATION_TIME information saved in the AOR file.
#     [create AORs, run the resource estimates for all of them, save AORs to disk, then run parse_aorfile.pl]
#  2. Output will be generated for each position in fixed/moving single and fixed cluster position targets.
#     AORs with fixed/moving cluster offset targets will just have the main position output (the offsets
#     are NOT output).
#  3. If filename.aor is run multiple times with this script with the output saved to a file, the
#     output file, filename_parsed.txt, WILL BE OVERWRITTEN each time.
# 
####################################################################################################
#
print "This program parses an AOR file and outputs basic information about each AOR\n";
print "only if the AOR file has saved observation times in it (INTERGATION_TIME line).\n";
print "\n";
print "Input AOR file name: ";
$infile = <STDIN>;
chomp $infile;
($outfile,$junk)=split(/\./,$infile);
$outfile=">$outfile"."_parsed.txt"; 
open IN, "<$infile" or die "cannot read $infile: $!\n";
#
print "Choose output delimiter (i.e. a space, |, or &; default is a |): ";
$delimiter = <STDIN>;
chomp $delimiter;
if ($delimiter eq "") {$delimiter ="|";}
#
print "Output to screen (enter a 1) or file (enter a 2; filename.aor => filename_parsed.txt): ";
$outtype = <STDIN>;
chomp $outtype;
if ($outtype eq 1) {$handle="STDOUT";}
else {$handle = "OUT";}
if ($outtype ne 1) {open($handle,$outfile);} 
#
print $handle "AOR# $delimiter Target_Name $delimiter RA $delimiter Dec $delimiter AOT $delimiter Est. Flux $delimiter On-source Times $delimiter \n";
#
$i=1; 
while (<IN>) {
 chomp;
 ($a,$b)=split(/\:/,$_,2);
  $a =~ s/^\s+//;
#
 if ($a =~ /AOT_TYPE/) {$aot = $b;$aot=~ s/^\s+//;$npositions=0;$nfluxes=0;}
 if ($a =~ /MOVING_TARGET/) {$tgttype=$b; $tgttype=~ s/^\s+//;}
 if ($a =~ /TARGET_NAME/) {$name = $b;$name=~ s/^\s+//;}
 if ($a =~ /POSITION/) {
      ++$npositions;
      $radec = $b;
      $radec=~ s/^\s+//;
      ($ra,$dec) = split(/\,/,$radec);
      ($junk,$ra) = split(/\=/,$ra);
      ($junk,$dec) = split(/\=/,$dec);
      $f_ra[$npositions]=$ra;
      $f_dec[$npositions]=$dec;
 }
 if ($a =~ /FD_SOURCE/) {
     ++$nfluxes;
     $flux[$nfluxes]=$b;
 } 
#
 if ($a =~ /EPHEMERIS/) {
      $b=~ s/^\s+//;
      ($tempnaifid,$tempnaifname)=split(/\,/,$b);
      ($junk,$naifid)=split(/\=/,$tempnaifid);
      ($junk,$naifname)=split(/\=/,$tempnaifname);
 }
#
 if ($a =~ /INTEGRATION_TIME/) {
    $times =$b; $times =~ s/^\s+//; 
    ($t[1],$t[2],$t[3],$t[4],$t[5],$t[6]) = split(/\,/,$times);
    $k=1;
    while ($k <7) {
       ($band,$tdt)=split(/=/,$t[$k]);
       ($seconds,$fraction)=split(/\./,$tdt);
       $tenth=substr($fraction,0,1);
       $hundreth=substr($fraction,1,1);
       if ($hundreth gt 6) {$tenth=$tenth+1};
       if ($tdt gt 0.0001) {$t[$k] = "$band"."="."$seconds.$tenth";}
       ++$k;
    }
   if ($tgttype =~ /NO/) {
        $n=1;
        while ($n < $npositions+1) {
           print $handle "$i$delimiter$name$delimiter$f_ra[$n]$delimiter$f_dec[$n]$delimiter$aot$delimiter";
           print $handle " $flux[$n] $delimiter";
           $k=1;
           while ($k<7) {print $handle "$t[$k] "; ++$k;}
           print $handle "$delimiter\n";
            ++$n;
        }
    }
    if ($tgttype =~ /YES/) {
          print $handle "$i$delimiter$name$delimiter$naifname$delimiter$naifid$delimiter$aot$delimiter";
          print $handle " $flux[1] $delimiter";
       $k=1;
       while ($k<7) {print $handle "$t[$k] ";++$k;}
        print $handle "$delimiter\n";
    }
   $k=1; while ($k<7) {$t[$k]=0;++$k;}
   $k=1; while ($k<7) {$flux[$k]=0;++$k;}
  ++$i;
 }
}
close(IN);
if ($outtype ne 1) {close($handle);}