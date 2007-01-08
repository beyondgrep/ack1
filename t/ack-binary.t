#!perl

use warnings;
use strict;

use Test::More tests => 3;
use App::Ack ();
use File::Next ();


TYPES: {
    my $file = 't/etc/shebang.pl.xxx';
    my @types = App::Ack::filetypes( $file );
    is( scalar @types, 1, 'Only one type' );
    is( $types[0], 'perl', 'Type matches' );
}

ACK_F: {
    my @expected = qw(
        t/etc/shebang.empty.xxx
        t/swamp/moose-andy.jpg
    );

    my @files = qw( t );
    my @args = qw( -f --binary );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    file_sets_match( \@results, \@expected, 'Looking for binary' );
}


sub file_sets_match {
    my @expected = @{+shift};
    my @actual = @{+shift};
    my $msg = shift;

    # Normalize all the paths
    for my $path ( @expected, @actual ) {
        $path = File::Next::reslash( $path ); ## no critic (Variables::ProhibitPackageVars)
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic
    return is_deeply( [sort @expected], [sort @actual], $msg );
}
