#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use lib 't';
use Util;

NO_SPEC_ONE_FILE: {
    my @expected = split( /\n/, <<'EOF' );
use strict;
EOF

    my @files = qw( t/swamp/options.pl );
    my @args = qw( strict );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict' );
}
    my @files = qw( t/swamp/options.pl t/swamp/pipe-stress-freaks.F );
