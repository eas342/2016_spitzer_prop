#!/usr/bin/perl
#
#   check_peakup_aors.pl - this script analyzes IRAC staring mode AORs with PCRS peakup and produces a summary table that may 
#                          be helpful in following best practices for precision photometry.    
#
#     Program syntax:  
#         prompt> check_peakup_aors.pl [aor files]
#                                        Optional 
#                                      (if no argument is given, the script will read all AOR files in the current directory)
#
#   To install: 
#     1) Put it somewhere in your path
#     2) Change the first line of the code so it points to the location of perl in your filesystem (type "which perl" at 
#        the command line -- it's currently set at /usr/bin/perl)
#     3) Make the code executable "chmod a+x check_peakup_aors.pl"
#
#   To run:
#     1) Type "check_peakup_aors.pl [aor file(s)]" for screen output
#            or 
#     2) Type "check_peakup_aors.pl [aor file(s)] > [output file]" for file output
#
#     The output is best viewed with a wide screen.  It is a table of most of the salient info for each of the AORs, 
#     organized per chain constraint.  It also lists the following extra facts in the "Notes" section:
#
#         -Whether or not the cluster offsets are correct for the given channel and readout mode
#         -When the first timing window opens (if any)
#         -It raises a flag if any of the of the following is true:
#               -PCRS peakup is not used
#               -Target is not specified as a cluster
#               -Cluster offsets are not in array coords
#               -Cluster mode is not set to observe offsets only ("OO" in output table)
#               -More than one array or data collection channel is specified
#               -The main or PU target coordinates are given with a proper motion and the Epoch is the default (2000.0)
#                (this may be correct, but you are informed just in case)
#               -The Peakup V magnitude is outside the acceptable range (7 to 12.1)
#               -The 1st timing window is less than 5 weeks away (i.e., it is unschedulable under normal circumstances)
#
#
#      In addition to the items listed above, you should examine the output to ensure the following:
#          -The first AOR in a chain is 1/2 hr long, at the same target and channel as the subsequent AOR in the chain.
#          -All AORs in a chain have the same target position and proper motion, and their peakup target coordinates are the same.
#          -All AORs with the same Peak-Up target have the same Peak-Up V Magnitude
#          -All AORs in a chain have the same readout modes and frametimes, per channel
#          -If you have specified a proper motion for your main or Peak-Up target, the given position should be consistent with the 
#           given Epoch (i.e., the current equinox J2000 position of the target may be derived from the given position by multiplying 
#           the proper motion by the time between the given Epoch and the current epoch).
#
#   HISTORY
#     V1.0   6 Nov 2012  - Initial version.  (J. Ingalls)
#     V1.01  8 Nov 2012  - Fixed PU Vmag range.  Fixed couple of bugs.
#     V1.02  5 Nov 2013  - Fixed minor bug.
#     V1.03  7 Feb 2014  - Changed PU Vmag range. 
#     V1.04 18 Feb 2014  - Fixed bug where the array offsets were not checked correctly.
#     V1.05 19 Feb 2015  - Error message when resource estimates haven't been computed.
#
#
use Time::Local 'timelocal_nocheck';

&define_constants;

if ($ARGV[0]) {
  my $nfiles = @ARGV;
  $s = '';
  if ($nfiles > 1) {$s = 's';}
    print STDOUT "Reading $nfiles AOR file$s\n";

    foreach my $aor_file(@ARGV) {
	print STDOUT "Processing: $aor_file\n";
	&parse_aor($aor_file);
      }
} else {
    
    opendir CURRNT,'.' or die "cannot open the current directory: $!\n";
    @SEQFILES = grep { /(\.aor)/ } readdir CURRNT;
    closedir CURRNT;
    foreach $filename(@SEQFILES) {
	if ($filename =~ /(\S+\.aor)/) {
	    $read_file = $1;
	    &parse_aor($read_file);
	}
    }
}
$TD_hr = $TotalDuration/3600.0;
print "
                                Total Duration: $TotalDuration s \($TD_hr hr\)
";

###########END MAIN#####################

sub define_constants{
  %months = ( 'Jan' => 1, 'Feb'=>2, 'Mar'=>3, 'Apr'=>4, 'May'=>5, 'Jun'=>6, 'Jul'=>7, 'Aug'=>8, 'Sep'=>9, 'Oct'=>10, 'Nov'=>11, 'Dec'=>12 );
  %offsets = (
	      '1' => {
		      'FULL' => {
				 'FULL' => [-0.344,0.171],
				 'SUB' => [130.932,127.429],
				},
		      'SUB' => {
				'SUB' => [-0.352,0.064],
			       },
		     },
	      '2' => {
		      'FULL' => {
				 'FULL' => [-0.113,0.398],
				 'SUB' => [126.649,124.529],
				},
		      'SUB' => {
				'SUB' => [-0.511,0.039],
			       },
		     },
	     );

$header = '
AOR Title                                         Est. Duration    Right Ascension  Declination   Proper Motion   Epoch |-------Cluster Offset-------|-----------------------PCRS Peak-Up--------------------| Readout  CH   Frame    N           Notes
                                                                       (J2000)        (J2000)     RA(")  Dec(")           Row(")   Col(")  Array? OO?     RA/OFF     DEC/OFF     VMAG   PMRA   PMDec   Epoch    Mode         Time   Frames
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

';
format STDOUT = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @######.## (@#.##hr)  @# @# @#.#   @## @# @#.#   @#.###  @#.###  @###.## @##.###  @##.###    @    @  @>>>>>>>>>>> @>>>>>>>>>>>  @#.##  @#.###  @#.###  @###.##   @<<<   @>>  @##.##   @####  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$SEQ_title,$Duration,$Duration/3600.,$RAhr,$RAmin,$RAsec,$DecDeg,$DecMin,$DecSec,$pmRa,$pmDec,$Epoch,$offRow1,$offCol1,$arraycoord,$offonly,$puRa,$puDec,$puVmag,$puRaPM,$puDecPM,$puEpoch,$roMode,$ch,$frameTime,$nFrames,join(';',@notes);
.

$TotalDuration = 0;

}

sub parse_aor{    
    my $FN = $_[0];
    open(AORFILE, "<$FN") || die "Cannot open $FN\n";
    @AORLINES = <AORFILE>;
    close(AORFILE);
    &examine_constraints;
### First line of output is the header
    print $header;

### Now loop through all constraints and their respective AORs (including the fake "WITHOUT CONSTRAINT" constraint)
    foreach $constraint ( @Constraint_titles_in_order ) {
      print "$constraint\:\n";
      foreach $aortitle (@{$CONSTRAINT{$constraint}}) {
	@offRow = ();
	@offCol = ();
	$offRow1 = 0;
	$offCol1 = 0;
	$noff = 0;
## Loop over the line numbers previously recorded for the current AOR
	for (my $i=$AOR_line_numbers{$aortitle}[0]; $i<=$AOR_line_numbers{$aortitle}[1]; $i++) {
	  $line = $AORLINES[$i];
	  if ($line =~ /AOR_LABEL\:\s*(\S.+\S)\s/) {
## Found a new entry.  Reset the default values of the variables.
	    ($Duration,$RAhr,$RAmin,$RAsec,$DecDeg,$DecMin,$DecSec,$pmRa,$pmDec,$offRow1,$offCol1,$arraycoord,$offonly,$puRa,$puDec,$puVmag,$roMode,$ch,$frameTime,$nFrames,$Epoch,$puEpoch,$yr,$monthname,$mday,$hr,$min,$sec,$fulltime,$current_time,$puRaPM,$puDecPM) = ('','','','','','','','','','N','N','N/A','N/A','','','','','','','N/A','','','','','','',0,0,'N/A','N/A');
	    $SEQ_title = $1;  ## AOR title
	    %array = ();
	    %data = ();
	    @notes = ();
	    $nopu = 1;
	    $nocluster = 1;
	    $havetimingconstraint = 0;
	    $toosoon = 0;
	    next;
	  } 
	  if ($line =~/RA\_LON\s*\=\s*(\d{1,2})h(\d\d)m([\d\.]+)s\,\s*DEC\_LAT\s*\=\s*([+-]?\d{1,2})d(\d\d)m([\d\.]+)s\,\s+PM\_RA\=(\-?[\d\.]+)\"\,\s+PM\_DEC\=(-?[\d\.]+)\"\,\s*EPOCH\=([\d\.]+)/) {
## Target postion information
	    $RAhr = $1;
	    $RAmin = $2;
	    $RAsec = $3;
	    $DecDeg = $4;
	    $DecMin = $5;
	    $DecSec = $6;
            $pmRa = $7;
            $pmDec = $8;
	    $Epoch = $9;
	    next;
	  }
	  if ($line =~/PCRS\_PEAK\_UP\:\s+RAJ2000\=(\d{1,2}h\d\dm[\d\.]*s)\,\s+DECJ2000\=([-+]?\d{1,2}d\d\dm[\d\.]*s)\,\s+PM\_RA\=(\-?\S+)\,\s+PM\_DEC\=(\-?\S+)\, EPOCH\=([\d\.]+)\,\s+FLUX\_DENSITY\=([\d\.]+)/) {
## Peakup target information "Position" form
	    $puRa = $1;
	    $puDec = $2;
	    $puRaPM = $3;
	    $puDecPM = $4;
	    $puEpoch = $5;
	    $puVmag = $6;
	    $nopu = 0;  ## Turn off the nopu flag
	    next;
	  }
	  if ($line =~/PCRS\_PEAK\_UP\:\s+RA\_OFFSET\=(\-?[\d\.]+\")\,\s+DEC\_OFFSET\=(\-?[\d\.]+\")\,\s+.FLUX\_DENSITY\=([\d\.]+)/) {
## Peakup target information "Offset" form
	    $puRa = $1;
	    $puDec = $2;
	    $puVmag = $3;
	    $nopu = 0;  ## Turn off the nopu flag
	    next;
	  }
	  if ($line =~ /OFFSET\_P(\d+)\:\s*EAST\_ROW\_PERP\=(\-?[\d\.]+)\"\,\s+NORTH\_COL\_PARA\=(\-?[\d\.]+)\"/) {
## Cluster Offset information
	    $offNum = $1+0;
#	    print "offNum = $offNum\n";
	    if ($offNum == 2) {
	      $offRow1 = $2;
	      $offCol1 = $3;
#	      print "offRow1 = $offRow1 offCol1= $offCol1\n";
	    }
	    push @offRow,$2;
	    push @offCol,$3;
	    $noff++;
	    $nocluster = 0;  ## Turn off the nocluster flag
	    next;
	  }
	  if ($line =~ /OFFSETS_IN_ARRAY\:\s+(\w+)/) {
## Cluster offset in array coords?
	    if ($1 =~ /[yY][eE][sS]/) { $arraycoord = 'Y';} else {push @notes,'Offsets not set in Array coords';}
	    next;
	  }
	  if ($line =~ /OBSERVE_OFFSETS_ONLY\:\s+(\w+)/) {
## Observe Offsets Only?
	    if ($1 =~ /[yY][eE][sS]/) { $offonly = 'Y';} else {push @notes,'Not set to Observe Offsets Only';}
	    next;
	  }
	  if ($line =~ /READOUT\_MODE\:\s+(FULL|SUB)\_?ARRAY/) {
## Readout Mode
	    $roMode = $1;
	    next;
	  }
	  if ($line =~ /ARRAY\:\s+36u\=(YES|NO)\,\s+45u\=(YES|NO)/){
## Array channel
	    $ch1array = $1;
	    $ch2array = $2;
	    $array{'3.6'} = ($ch1array =~ 'YES');
	    $array{'4.5'} = ($ch2array =~ 'YES');
	    next;
	  }
	  if ($line =~ /DATA\_COLLECTION\:\s+36u\=(YES|NO)\,\s+45u\=(YES|NO)/){
	    $ch1data = $1;
	    $ch2data = $2;
## Data Collection Channel
	    $data{'3.6'} = ($ch1data =~ 'YES');
	    $data{'4.5'} = ($ch2data =~ 'YES');
	    next;
	  }
	  if ($line =~ /FRAME\_TIME\:\s*([\d\.]+)/) {
## Frame Time
	    $frameTime = $1;
	    next;
	  }
	  if ($line =~ /N\_FRAMES\_PER\_POINTING\:\s*(\d+)/) {
## Number of DCEs
	    $nFrames = $1;
	    next;
	  }
	  if ($line =~ /TOTAL\_DURATION\=(.+?)\,/) {
## AOR Duration
	    $Duration = $1;
	    $TotalDuration += $Duration;
## At the end of the AOR (for our purposes).  Check to see if there is a timing window set for the AOR
	    if ($AORLINES[$i+2] =~ /TIMING1\:\s*START\_DATE\=(\d{4})\s+(\w{3})\s+(\d{1,2})\,\s+START\_TIME\=(\d\d)\:(\d\d)\:(\d\d)\,/) {
	       $yr = $1;
	       $monthname = $2;
	       $mday = $3;
	       $hr = $4;
	       $min = $5;
	       $sec = $6;
	       $havetimingconstraint=1;  # Turn on the havetimingconstraint flag
## Compare the start date of the timing window with the current time.  
	       $fulltime = timelocal_nocheck($sec,$min,$hr,$3,$months{$monthname}-1,$yr-1900);
	       $current_time = time();
	       $diff =  ($fulltime-$current_time)/86400;
## It's too soon to schedule if less than 5 weeks away.
	       $toosoon = $diff < 35.;
	     }
## Determine the channel (need to do it now after we are sure all the Array and Data Collection lines are read in)
	    if ($array{'3.6'} && $data{'3.6'} && !$array{'4.5'} && !$data{'4.5'}) {
	      $ch = '1';
	    } elsif ($array{'4.5'} && $data{'4.5'} && !$array{'3.6'} && !$data{'3.6'}) {
	      $ch = '2';
	    } else {
## If more than one channel is selected for either Array or Data Collection, then set $ch to 'B' (both)
	      $ch = '1&2';
	    }

## Create a report for the "Notes" column. 
##  Compare cluster Row,Column offsets to the values appropriate to the Channel and Readout Mode	  
	    if ($roMode =~ /FULL/ && $offRow1 == $offsets{$ch}{'FULL'}{'FULL'}[0] &&  $offCol1 == $offsets{$ch}{'FULL'}{'FULL'}[1] ) {
	      push @notes,"Correct Offset for CH$ch FULL\/FULL";
	    }
#            print "$offRow1,$offCol1,$ch,$roMode,$offsets{$ch}{$roMode}{'SUB'}[0],$offsets{$ch}{$roMode}{'SUB'}[1] \n";
	    if ( $offRow1 == $offsets{$ch}{$roMode}{'SUB'}[0] && $offCol1 == $offsets{$ch}{$roMode}{'SUB'}[1]) {
	      push @notes,"Correct Offset for CH$ch $roMode\/SUB";
	    }
	    if ( $offRow1 != $offsets{$ch}{$roMode}{'FULL'}[0] && $offRow1 != $offsets{$ch}{$roMode}{'SUB'}[0] ) {
	      if ($ch !~ /1\&2/) {push @notes,"Incorrect Row Offset for CH$ch and readout $roMode";}
	    }
	    if ( $offCol1 != $offsets{$ch}{$roMode}{'FULL'}[1] && $offCol1 != $offsets{$ch}{$roMode}{'SUB'}[1] ) {
	      if ($ch !~ /1\&2/) {push @notes,"Incorrect Column Offset for CH$ch and readout $roMode";}
	    }

	    if ($nopu) {
	      push @notes,'PCRS Peakup is not used';
	    }
	    if ($nocluster) {
	      push @notes,'Target is not specified as a cluster';
	    }
	    if ($ch =~ /1\&2/) {
	      push @notes,'Specified more than one Array or Data Collection Channel';
	    }
## Check with observer that Epoch of 2000.0 is appropriate for the coordinates and proper motion
	    if ( ($pmRa != 0 || $pmDec != 0) && $Epoch == 2000 ) {
	      push @notes,'Epoch 2000.0--is this correct?';
	    }
	    if ( ($puRaPM != 0 || $puDecPM != 0) && $puEpoch == 2000 ) {
	      push @notes,'PU Target Epoch 2000.0--is this correct? ';
	    }
	    if ($puVmag > 12.1 || $puVmag < 7) { push @notes,'Peakup V outside acceptable range (7 to 12.1)';}
## Comment on the timing window (if any)
	    if ($havetimingconstraint==1) {
	      if ( $toosoon ) {  
		## the first timing constraint is less than 35 days away
		push @notes,"1st timing window opens $yr $monthname $mday\, less than 5 weeks away";
	      } else {
		push @notes,"1st timing window opens $yr $monthname $mday";
	      }  
	    }
	    write;
	    if ($noff > 1) {
	      for ($k=1; $k<$noff; $k++) {
		printf '                                                                                                                          %6.3f   %6.3f'."\n",$offRow[$k],$offCol[$k];
	      }
	    }

	  }
	}
      }
      print "\n";
    }
  }


sub examine_constraints {
    %AOR_line_numbers = ();
    %CONSTRAINT = ();
    %HasConstraint = ();
    @Constraint_titles_in_order = ();
    $without = 'NOT PART OF A CHAIN';
### Go through the file line by line, separating out each AOR, and finding the chain constraints
    for($i=0; $i<=$#AORLINES; $i++) {
      if ($AORLINES[$i] =~ /AOR_LABEL\:\s*(\S.+\S)\s/) {
	$label = $1;
# Record the line number where the current AOR starts
	$AOR_line_numbers{$label}[0] = $i;
# Loop forward until we find the end of the AOR
	for($j=$i+1; $j<=$#AORLINES; $j++) {
	  if ($AORLINES[$j] =~ /INTEGRATION_TIME\:/) {
#	    Found end of current AOR, record the line number 
	    $AOR_line_numbers{$label}[1] = $j;
	    last;
	  }
	}
        die "***No time estimate for $label.  Please run \"Tools-\>Recompute All Estimates\" in Spot.  Stopping.\n" unless ($j < $#AORLINES);
	$i = $j+1;
      }
      if ($AORLINES[$i] =~ /CONSTRAINT\:\s+TYPE\=CHAIN,\s+NAME\=(.+)$/) {
## Found a chain constraint; record the title
	$constraint_title = $1;
## Loop forward until we find the list of AORs pertaining to the constraint
	for($j=$i+1; $j<=$#AORLINES; $j++){
	  if ($AORLINES[$j] =~/AOR(\d+)\=(\S.+\w)\,?/) {
## Found an AOR title 
 ## Make sure the constraint is in the list
	    if( ! exists($CONSTRAINT{$constraint_title}) ) {push @Constraint_titles_in_order,$constraint_title;} 

	    my $aornum = $1;
	    my $title = $2;
## Store the AOR title in the %CONSTRAINT hash
	    $CONSTRAINT{$constraint_title}[$aornum-1] = $title;
## Record that the AOR has a constraint
	    $HasConstraint{$title}++;
	  } else {
	    last;
	  }
	  $i = $j;
	}
      }
    }
    ### Now check that each AOR in the file is part of a constraint:
    foreach my $aortitle(keys(%AOR_line_numbers)){
      if (!$HasConstraint{$aortitle}) {
	if( ! exists($CONSTRAINT{$without}) ) { push @Constraint_titles_in_order,$without;}
## If not add the AOR to the special "constraint" 'NOT PART OF A CHAIN'
	push @{ $CONSTRAINT{$without} },$aortitle;
      }
    }
## Ensure that the list of AORs without constraints is in alphanumeric order (since there is no constraint time order telling how to order it)
    @{ $CONSTRAINT{$without} } = sort { $a cmp $b } @{ $CONSTRAINT{$without} };
    
  }