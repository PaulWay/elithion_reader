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
        [ '81-c8',      'c' ],
        [ 'pwr_flag',   'c',    $tohexc ],      # 82
        [ 'count1',     's>'],                  # 83-84
        [ 'chg_pct',    'c',    $chg2pct ],     # 85
        [ 'count2',     'c' ],                  # 86
        [ 'count3',     'XL>',  $longto24bit],  # 87-89
        [ 'count4',     'XL>',  $longto24bit],  # 90-92
        [ 'count5',     'L>' ],                 # 93-96
    ],
    'extended' => [
        [ 'flag-01',    'c' ],                  # 01
        [ 'times_on',   'S>' ],                 # 02-03
        [ 'seconds_on', 'XL>',  $longto24bit ], # 04-06 - back up one byte and read a long
        [ 'charge_a',   's>',   $amps ],        # 07-08
        [ 'charge_b',   's>',   $amps ],        # 09-10
        [ '11-12',      's>' ],                 # 11-12
        [ 'flag-13',    'c',    $tohexc ],      # 13
        [ '14',         'c' ],                  # 14
        [ 'count-15-16', 's>' ],                # 15-16
        [ 'flag-17',    'c',    $tohexc ],
        [ '18',         'c',    $tohexc ],
        [ '19',         'c',    $tohexc ],
        [ '20-21',      's>' ],
        [ '22-23',      's>' ],
        [ 'flag-24-27', 'L>',   $tohexl ],
        [ 'flag-28-29', 's>',   $tohexs ],
        [ 'flag-30-31', 's>',   $tohexs ],
        [ 'flag-32',    'c',    $tohexc ],
        [ 'const-33-34', 's>' ],
        [ 'flag-35-38', 'L>',   $tohexl ],
        [ 'flag-39',    'c',    $tohexc ],
        [ 'const-40-41', 's>' ],
        [ 'const-43-43', 's>' ],
        [ 'cflag-44-47', 'L>',  $tohexl ],
        [ 'cflag-48',   'c',    $tohexc ],
        [ 'flag-49-52', 'L>',   $tohexl ],
        [ 'flag-53-56', 'L>',   $tohexl ],
        [ 'flag-57-60', 'L>',   $tohexl ],
        [ 'flag-61-62', 's>',   $tohexs ],
        [ 'flag-63',    'c',    $tohexc ],
        [ 'charge_c',   's>' ],                 # 64-65
        [ 'charge_d',   's>' ],                 # 66-67
        [ 'main_amps',  's>',   $amps ],        # 68-69
        [ 'count-70-71', 's>' ],                # 70-71
        [ 'AHrs_down',  'L>',   $amphrs ],      # 72-75
        [ '76',         'c' ],                  # 76
        [ 'flag-77-78', 's>', $tohexs ],        # 77-78
        [ 'flag-79',    'c', $tohexc ],         # 79
        [ 'flag-80',    'c', $tohexc ],         # 80
    ],
);

if (not exists $field_defs{$type}) {
    die "Error: type must be one of ", join(', ', sort keys %field_defs), ".\n";
}

my @field_defs = @{ $field_defs{$type} };

my $unpackformat = join(' ', map { $_->[1] } @{ $field_defs{$type} } );

print "Unpack format for $type = $unpackformat\n";

print join(',', 'date', grep { $_ ne 'ignore' } map { $_->[0] } @field_defs ), "\n";
while (<>) {
    chomp;
    my @fields = split m{,};
    my $bin = pack("H*", $fields[3]);
    # Unpack values via format
    my @vals = unpack($unpackformat, $bin);
    # Process with any scalers defined
    if ($do_conversions) {
        while (my ($fnum, $defref) = each @field_defs) {
            if (scalar @$defref > 2) {
                # print "converting $field_defs[$fnum][0] from $vals[$fnum]";
                $vals[$fnum] = $defref->[2]($vals[$fnum]);
                # print " to $vals[$fnum]\n";
            }
        }
    }
    print join(',', $fields[0], @vals), "\n";
}
