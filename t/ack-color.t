#!perl

use warnings;
use strict;

use Test::More tests => 3;
use File::Next ();
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

my $is_windows = ($^O =~ /MSWin32/);

NORMAL_COLOR: {
    SKIP: {
        skip 'Highlighting does not work on Windows', 1 if $is_windows;

        my @files = qw( t/text/boy-named-sue.txt );
        my @args = qw( called --color --text );
        my @results = run_ack( @args, @files );

        ok( ( grep { /\e/ } @results ), 'normal match highlighted' );
    }
}

MATCH_WITH_BACKREF: {
    SKIP: {
        skip 'Highlighting does not work on Windows', 2 if $is_windows;

        my @files = qw( t/text/boy-named-sue.txt );
        my @args = ( q/'(called).*\1'/,  '--text', '--color' );
        my @results = run_ack( @args, @files );

        ok( @results == 1, 'backref pattern matches once' );

        ok( grep( /\e/, @results ), 'match with backreference highlighted' );
    }
}
