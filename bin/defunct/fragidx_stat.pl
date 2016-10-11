#!/usr/bin/perl
#
# fragidx.pl
#
# This prints out the fragmentation index for the requested order
# using the buddyinfo_at_fails* files generated by bench-stresshighalloc.
# This can be used to generate a chart showing the fragmentation index
# at each time of failure

use FindBin qw($Bin);
use lib "$Bin/lib";

use Getopt::Long;
use Pod::Usage;
use VMR::File;
use VMR::Report;
use File::Basename;
use strict;

# Option variables
my $man  =0;
my $help =0;
my $opt_delay = -1;
my $opt_verbose = 0;
my $opt_order = 0;
my $opt_zone = "Normal";
my $opt_report = "buddyinfo_at_fails-pass2.txt";

# Whole report
my $report;

# Output related

# Time related
my $starttime;
my $duration;

# Get options
GetOptions(
	'help|h'     => \$help, 
	'man'        => \$man,
	'verbose'    => \$opt_verbose,
	'report|r=s' => \$opt_report,
	'order|o=s'  => \$opt_order,
	'zone|z=s'   => \$opt_zone);

# Print usage if requested
pod2usage(-exitstatus => 0, -verbose => 0) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
$opt_verbose && setVerbose();

# Print fragmentation index
$report = readproc($opt_report);
my $line;
my $attempt;
my $freeblocks;
my $freememory;
my $failures = 0;
my $order;

# Process proc entry
foreach $line (split /\n/, $report) {
  my @buddyinfo = split(/\s+/, $line);

  if ($line =~ /^Buddyinfo/) {
    $failures++;
    $attempt = $buddyinfo[2];
    printVerbose("Processing failure at attempt $attempt\n");
    next;
  }

  if ($buddyinfo[3] ne $opt_zone) {
    printVerbose("Skipping unrequested zone $buddyinfo[3]\n");
    next;
  }

  $freeblocks = 0;
  $freememory = 0;
  for ($order = 0; $order <= $opt_order; $order++) {
    $freeblocks += $buddyinfo[4+$order];
    $freememory += $buddyinfo[4+$order] << $order;
  }

  my $sizerequested = 1 << $opt_order;
  my $bare_fragidx = 1 - ( ($freememory / $sizerequested) / $freeblocks);
  printf("%4s %s\n", $attempt, ($bare_fragidx * $failures) / $attempt);
      
}
        
# Below this line is help and manual page information
__END__

=head1 NAME

extfrag_stat - Measure the extend of external fragmentation in the kernel

=head1 SYNOPSIS

extfrag_stat.pl [options]

 Options:
  --help          Print help messages
  --man           Print man page
  n, --delay      Print a report every n seconds

=head1 OPTIONS

=over 8

=item B<--help>

Print a help message and exit

=item B<-n, --delay>

By default, a single report is generated and the program exits. This option
will generate a report every requested number of seconds.

=back

=head1 DESCRIPTION

No detailed description available. Consult the full documentation in the
docs/ directory

=head1 AUTHOR

Written by Mel Gorman (mel@csn.ul.ie)

=head1 REPORTING BUGS

Report bugs to the author

=cut