#!perl

use warnings;
use strict;

use Test::More tests => 2;

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

    @results = sort @results;
    @expected = sort @expected;

    is_deeply( \@results, \@expected, 'No religion please' );
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

    @results = sort @results;
    @expected = sort @expected;

    is_deeply( \@results, \@expected, 'Non-religion counts' );
}
