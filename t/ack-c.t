#!perl

use warnings;
use strict;

use Test::More tests => 3;

DASH_L: {
    my @expected = qw(
        t/text/science-of-myth.txt
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -l );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    @results = sort @results;
    @expected = sort @expected;

    is_deeply( \@results, \@expected, 'Looking for religion' );
}

DASH_C: {
    my @expected = qw(
        t/text/boy-named-sue.txt:0
        t/text/freedom-of-choice.txt:0
        t/text/science-of-myth.txt:2
        t/text/shut-up-be-happy.txt:0
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -c );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    @results = sort @results;
    @expected = sort @expected;

    is_deeply( \@results, \@expected, 'Religion counts' );
}

DASH_LC: {
    my @expected = qw(
        t/text/science-of-myth.txt:2
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -l -c );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    @results = sort @results;
    @expected = sort @expected;

    is_deeply( \@results, \@expected, 'Religion counts -l -c' );
}
