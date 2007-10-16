#!perl

use warnings;
use strict;

use Test::More tests => 2;
use File::Next ();

delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

DASH_L: {
    my @expected = qw(
        t/text/4th-of-july.txt
        t/text/boy-named-sue.txt
        t/text/freedom-of-choice.txt
        t/text/shut-up-be-happy.txt
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -v -l );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'No religion please' );
}

DASH_C: {
    my @expected = qw(
        t/text/4th-of-july.txt:37
        t/text/boy-named-sue.txt:72
        t/text/freedom-of-choice.txt:50
        t/text/science-of-myth.txt:24
        t/text/shut-up-be-happy.txt:26
    );

    my @files = qw( t/text );
    my @args = qw( religion -i -a -v -c );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Non-religion counts' );
}
