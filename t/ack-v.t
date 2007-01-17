#!perl

use warnings;
use strict;

use Test::More tests => 2;
use File::Next ();

DASH_L: {
    my @expected = qw(
        t/text/boy-named-sue.txt
        t/text/freedom-of-choice.txt
        t/text/shut-up-be-happy.txt
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -v -l );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    file_sets_match( \@results, \@expected, 'No religion please' );
}

DASH_C: {
    my @expected = qw(
        t/text/boy-named-sue.txt:72
        t/text/freedom-of-choice.txt:50
        t/text/science-of-myth.txt:24
        t/text/shut-up-be-happy.txt:26
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -v -c );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    file_sets_match( \@results, \@expected, 'Non-religion counts' );
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
