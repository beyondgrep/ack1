#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use lib 't';
use Util;

ANCHORED: {
    my @expected = split( /\n/, <<'EOF' );
Science and religion are not mutually exclusive
EOF

    my @files = qw( t/text );
    my @args = qw( --text -h -i ^science );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for anchored science' );
}

UNANCHORED: {
    my @expected = split( /\n/, <<'EOF' );
Science and religion are not mutually exclusive
In fact, for better understanding we take the facts of science and apply them
    -- "The Science Of Myth", Screeching Weasel
EOF

    my @files = qw( t/text );
    my @args = qw( --text -h -i science );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for unanchored science' );
}



