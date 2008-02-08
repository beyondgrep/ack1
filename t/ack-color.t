#!perl

use warnings;
use strict;

use Test::More;
use File::Next ();
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

plan skip_all => 'Highlighting does not work on Windows' if is_win32();
plan tests => 5;


NORMAL_COLOR: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( called --color --text );
    my @results = run_ack( @args, @files );

    ok( ( grep { /\e/ } @results ), 'normal match highlighted' );
}

MATCH_WITH_BACKREF: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = ( q/'(called).*\1'/,  '--text', '--color' );
    my @results = run_ack( @args, @files );

    is( @results, 1, 'backref pattern matches once' );

    ok( grep( /\e/, @results ), 'match with backreference highlighted' );
}
