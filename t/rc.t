#!perl

use warnings;
use strict;

use Test::More tests => 5;

use lib 't';
use Util;

prep_environment();

SINGLE_TEXT_MATCH: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -1 -h --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first instance of Sue!' );
    is( get_rc(), 0, 'found Sue so good RC needed');
}


NO_MATCH: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( Pumpkin  --text );
    my @results = run_ack( @args, @files );
    is(  get_rc(), 1, 'No Pumpkin  so bad RC needed');
}

## TBD RC 2 for bad file?

## TBD Core, Signal ??
