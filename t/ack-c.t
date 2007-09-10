#!perl

use warnings;
use strict;

use Test::More tests => 5;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

DASH_L: {
    my @expected = qw(
        t/text/science-of-myth.txt
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -l );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for religion' );
}

DASH_CAPITAL_L: {
    my @expected = qw(
        t/text/4th-of-july.txt
        t/text/boy-named-sue.txt
        t/text/freedom-of-choice.txt
        t/text/shut-up-be-happy.txt
    );

    # -L and -l -v are identical
    for my $switches ( (['-L'], ['-l','-v']) ) {
        my @files = qw( t/text );
        my @args = ( 'religion', '-a', @{$switches} );
        my @results = run_ack( @args, @files );

        sets_match( \@results, \@expected, 'Looking for religion' );
    }
}

DASH_C: {
    my @expected = qw(
        t/text/4th-of-july.txt:1
        t/text/boy-named-sue.txt:2
        t/text/freedom-of-choice.txt:0
        t/text/science-of-myth.txt:0
        t/text/shut-up-be-happy.txt:0
    );

    my @files = qw( t/text );
    my @args = qw( boy -i -a -c );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Boy counts' );
}

DASH_LC: {
    my @expected = qw(
        t/text/science-of-myth.txt:2
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -l -c );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Religion counts -l -c' );
}
