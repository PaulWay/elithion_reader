#!/usr/bin/perl -w

use warnings;
use strict;

use Getopt::Long;

my $type = 'extended';
my $do_conversions = 0;

GetOptions(
    'type|t=s'      => \$type,
    'conversions|c' => \$do_conversions,
);

# Scaler functions

my $longto24bit = sub {
    return $_[0] & 0x00ffffff;
};
my $amps = sub {
    return $_[0]/4.0;
};
my $amphrs = sub {
    return $_[0]/1e6;
};
my $tohexc = sub {
    return sprintf "%02X", $_[0] & 0xff;
};
my $tohexs = sub {
    return sprintf "%04X", $_[0] & 0xffff;
};
my $tohexl = sub {
    return sprintf "%08X", $_[0] & 0xffffffff;
};
my $chg2pct = sub {
    return $_[0]/2;
};
my $unsc_avg = 141; my $unsc_max = 165; my $unsc_range = $unsc_max - $unsc_avg;
my $scal_avg = 3.2; my $scal_max = 3.6; my $scal_range = $scal_max - $scal_avg;
my $tovolts = sub {
    return sprintf('%1.3f', (($_[0] - $unsc_avg) / $unsc_range) * $scal_range + $scal_avg);
};

my %field_defs = (
    # The names don't matter here - if you're filling in space, name
    # them after column numbers.
    'stats' => [
        [ '01-04',      'L>' ],
        [ '05-08',      'L>' ],
        [ '09-12',      'L>' ],
        [ '13-16',      'L>' ],
        [ '17-20',      'L>' ],
        [ '21-24',      'L>' ],
        [ '25-28',      'L>' ],
        [ '29-32',      'L>' ],
        [ '33-36',      'L>' ],
        [ '37-40',      'L>' ],
        [ '41-44',      'L>' ],
        [ '45-48',      'L>' ],
        [ '49-52',      'L>' ],
        [ '53-56',      'L>' ],
        [ '57-60',      'L>' ],
        [ '61-64',      'L>' ],
        [ '65-68',      'L>' ],
        [ '69-72',      'L>' ],
        [ '73-76',      'L>' ],
        [ '77-80',      'L>' ],
        [ '81-c8',      'C' ],
        [ 'pwr_flag',   'C',    $tohexc ],      # 82
        [ 'count1',     'S>'],                  # 83-84
        [ 'chg_pct',    'C',    $chg2pct ],     # 85
        [ 'count2',     'C' ],                  # 86
        [ 'count3',     'XL>',  $longto24bit],  # 87-89
        [ 'count4',     'XL>',  $longto24bit],  # 90-92
        [ 'count5',     'L>' ],                 # 93-96
    ],
    'extended' => [
        [ 'flag-01',    'C' ],                  # 01
        [ 'times_on',   'S>' ],                 # 02-03
        [ 'seconds_on', 'XL>',  $longto24bit ], # 04-06 - back up one byte and read a long
        [ 'charge_a',   's>',   $amps ],        # 07-08
        [ 'charge_b',   's>',   $amps ],        # 09-10
        [ '11-12',      's>' ],                 # 11-12
        [ 'flag-13',    'C',    $tohexc ],      # 13
        [ '14',         'C' ],                  # 14
        [ 'count-15-16', 's>' ],                # 15-16
        [ 'flag-17',    'C',    $tohexc ],
        [ '18',         'C',    $tohexc ],
        [ '19',         'C',    $tohexc ],
        [ '20-21',      's>' ],
        [ '22-23',      's>' ],
        [ 'flag-24-27', 'L>',   $tohexl ],
        [ 'flag-28-29', 's>',   $tohexs ],
        [ 'flag-30-31', 's>',   $tohexs ],
        [ 'flag-32',    'C',    $tohexc ],
        [ 'const-33-34', 's>' ],
        [ 'flag-35-38', 'L>',   $tohexl ],
        [ 'flag-39',    'C',    $tohexc ],
        [ 'const-40-41', 's>' ],
        [ 'const-43-43', 's>' ],
        [ 'cflag-44-47', 'L>',  $tohexl ],
        [ 'cflag-48',   'C',    $tohexc ],
        [ 'flag-49-52', 'L>',   $tohexl ],
        [ 'flag-53-56', 'L>',   $tohexl ],
        [ 'flag-57-60', 'L>',   $tohexl ],
        [ 'flag-61-62', 's>',   $tohexs ],
        [ 'flag-63',    'C',    $tohexc ],
        [ 'charge_c',   's>' ],                 # 64-65
        [ 'charge_d',   's>' ],                 # 66-67
        [ 'main_amps',  's>',   $amps ],        # 68-69
        [ 'count-70-71', 's>' ],                # 70-71
        [ 'AHrs_down',  'L>',   $amphrs ],      # 72-75
        [ '76',         'C' ],                  # 76
        [ 'flag-77-78', 's>',   $tohexs ],      # 77-78
        [ 'flag-79',    'C',    $tohexc ],      # 79
        [ 'flag-80',    'C',    $tohexc ],      # 80
    ],
    'voltages' => [
        [ 'cell_1',     'C',    $tovolts ],
        [ 'cell_2',     'C',    $tovolts ],
        [ 'cell_3',     'C',    $tovolts ],
        [ 'cell_4',     'C',    $tovolts ],
        [ 'cell_5',     'C',    $tovolts ],
        [ 'cell_6',     'C',    $tovolts ],
        [ 'cell_7',     'C',    $tovolts ],
        [ 'cell_8',     'C',    $tovolts ],
        [ 'cell_9',     'C',    $tovolts ],
        [ 'cell_10',    'C',    $tovolts ],
        [ 'cell_11',    'C',    $tovolts ],
        [ 'cell_12',    'C',    $tovolts ],
        [ 'cell_13',    'C',    $tovolts ],
        [ 'cell_14',    'C',    $tovolts ],
        [ 'cell_15',    'C',    $tovolts ],
        [ 'cell_16',    'C',    $tovolts ],
        [ 'cell_17',    'C',    $tovolts ],
        [ 'cell_18',    'C',    $tovolts ],
        [ 'cell_19',    'C',    $tovolts ],
        [ 'cell_20',    'C',    $tovolts ],
        [ 'cell_21',    'C',    $tovolts ],
        [ 'cell_22',    'C',    $tovolts ],
        [ 'cell_23',    'C',    $tovolts ],
        [ 'cell_24',    'C',    $tovolts ],
        [ 'cell_25',    'C',    $tovolts ],
        [ 'cell_26',    'C',    $tovolts ],
        [ 'cell_27',    'C',    $tovolts ],
        [ 'cell_28',    'C',    $tovolts ],
        [ 'cell_29',    'C',    $tovolts ],
        [ 'cell_30',    'C',    $tovolts ],
        [ 'cell_31',    'C',    $tovolts ],
        [ 'cell_32',    'C',    $tovolts ],
        [ 'cell_33',    'C',    $tovolts ],
        [ 'cell_34',    'C',    $tovolts ],
        [ 'cell_35',    'C',    $tovolts ],
        [ 'cell_36',    'C',    $tovolts ],
        [ 'cell_37',    'C',    $tovolts ],
        [ 'cell_38',    'C',    $tovolts ],
    ],
);

sub process_file {
    my ($infile, $outfile) = @_;
    open my $ifh, '<', $infile;

    my $intype = $type;
    if ($type eq 'auto') {
        if ($infile =~ m{^(.*/)*(?<intype>\w+)\.[^/]+$}) {
            $intype = $+{'intype'};
        } else {
            warn "Warning: could not automatically determine type of file '$infile' - ignoring\n";
            return;
        }
    }
    if (not exists $field_defs{$intype}) {
        warn "Warning: type '$intype' " . ($type eq 'auto' ? 'from filename ' : '')
         . "unknown - ignoring\n";
        return;
    }
    my $field_defsref = $field_defs{$intype};
    my $unpackformat = join(' ', map { $_->[1] } @$field_defsref );

    open my $ofh, '>', $outfile;
    print $ofh join(',', 'date', map { $_->[0] } @$field_defsref ), "\n";
    while (<$ifh>) {
        chomp;
        my @fields = split m{,};
        my $bin = pack("H*", $fields[3]);
        # Unpack values via format
        my @vals = unpack($unpackformat, $bin);
        # Process with any scalers defined
        if ($do_conversions) {
            while (my ($fnum, $defref) = each @$field_defsref) {
                if (scalar @$defref > 2) {
                    # print "converting $field_defs[$fnum][0] from $vals[$fnum]";
                    $vals[$fnum] = $defref->[2]($vals[$fnum]);
                    # print " to $vals[$fnum]\n";
                }
            }
        }
        print $ofh join(',', $fields[0], @vals), "\n";
    }
    close $ifh;
    close $ofh;
}

#foreach my $file (@ARGV) {
process_file($ARGV[0], 'processed/' . $ARGV[0]);
