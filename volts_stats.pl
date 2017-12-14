#!/usr/bin/perl -w

use warnings;
use strict;
use autodie;

use Date::Parse;

my ($mincell, $minrval, $mindate) = (0, 255, 0);
my ($maxcell, $maxrval, $maxdate) = (0, 0, 0);
my ($total, $count);
my (@rminima, @rmaxima);
my @total; my $cell_count;

# Values for scaling calculation
my $unsc_avg = 141; my $unsc_max = 165; my $unsc_range = $unsc_max - $unsc_avg;
my $scal_avg = 3.2; my $scal_max = 3.6; my $scal_range = $scal_max - $scal_avg;

sub val2volts {
    my ($val) = @_;
    return (($val - $unsc_avg) / $unsc_range) * $scal_range + $scal_avg;
}
foreach my $fname (@ARGV) {
    open my $fh, '<', $fname;
    while (<$fh>) {
        chomp;
        next unless length($_) > 16; # Must be at least a date there.
        my ($datestr, $type, $lenstr, $datastr, $checkstr) = split m{,};
        next unless defined $checkstr; # Must have a defined checkstr, i.e. split succeeded
        # my $date = str2time($datestr);
        my $len = hex($lenstr);
        if ($datastr eq 'FF' x $len) {
            warn "Warning: got all high read at $datestr in $fname\n";
            next;
        }
        $cell_count = $len;
        my @rawvals = map { hex($_) } unpack "A2"x$len, $datastr;
        my @values = map { val2volts($_) } @rawvals;
        if (length($datastr) != $len*2) {
            warn "Warning: len not correct on $lenstr,$datastr in $fname\n";
            next;
        }
        while (my ($cell, $val) = each @values) {
            my $rawval = $rawvals[$cell];
            $cell++; # humans count from 1.
            $total += $val;
            $total[$cell] += $val;
            $count ++;
            if ($rawval < $minrval) {
                $mincell = $cell;
                $minrval = $rawval;
                $mindate = $datestr;
            }
            if (not defined $rminima[$cell]) {
                $rminima[$cell] = $rawval;
            } elsif ($rawval < $rminima[$cell]) {
                $rminima[$cell] = $rawval;
            }
            if ($rawval > $maxrval) {
                $maxcell = $cell;
                $maxrval = $rawval;
                $maxdate = $datestr;
            }
            if (not defined $rmaxima[$cell]) {
                $rmaxima[$cell] = $rawval;
            } elsif ($rawval > $rmaxima[$cell]) {
                $rmaxima[$cell] = $rawval;
            }
        }
    }
    close $fh;
}

my $minval = val2volts($minrval); my $maxval = val2volts($maxrval);
printf "Minimum: %2d was %3d (%.2fV) at %s\n", $mincell, $minrval, $minval, $mindate;
printf "Maximum: %2d was %3d (%.2fV) at %s\n", $maxcell, $maxrval, $maxval, $maxdate;
printf "From %d values, average = %3.2fV\n", $count, $total / $count;
foreach my $i (sort { ($rmaxima[$a] - $rminima[$a]) <=> ($rmaxima[$b] - $rminima[$b]) } 1..$#rmaxima) {
    my $minvolt = val2volts($rminima[$i]); my $maxvolt = val2volts($rmaxima[$i]);
    my $range = $rmaxima[$i] - $rminima[$i]; my $vrange = val2volts($range);
    my $avvolts = $total[$i] / $count * $cell_count;
    printf "Range for cell %2d = %3d (%3.2fV): %3d (%.2fV) - %3d (%.2fV), average %.2fV.\n",
     $i, $range, $vrange, $rminima[$i], $minvolt, $rmaxima[$i], $maxvolt, $avvolts;
}

