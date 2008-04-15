#!perl

use warnings;
use strict;

use Test::More;
use File::Next ();

use lib 't';
use Util;

plan tests => 5;

prep_environment();

NORMAL_COLOR: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( called --color --text );
    my @results = run_ack( @args, @files );

    ok( grep { /\e/ } @results, 'normal match highlighted' );
}

MATCH_WITH_BACKREF: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = ( '(called).*\1',  '--text', '--color' );
    my @results = run_ack( @args, @files );

    is( @results, 1, 'backref pattern matches once' );

    ok( grep { /\e/ } @results, 'match with backreference highlighted' );
}
