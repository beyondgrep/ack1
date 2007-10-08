#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use File::Next 0.34; # For the reslash() function
use lib 't';
use Util;

NO_SWITCHES_ONE_FILE: {
    my @expected = split( /\n/, <<'EOF' );
use strict;
EOF

    my @files = qw( t/swamp/options.pl );
    my @args = qw( strict );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict' );
}


NO_SWITCHES_MULTIPLE_FILES: {
    my $target_file = File::Next::reslash( 't/swamp/options.pl' );
    my @expected = split( /\n/, <<"EOF" );
$target_file:2:use strict;
EOF

    my @files = qw( t/swamp/options.pl t/swamp/pipe-stress-freaks.F );
    my @args = qw( strict );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict' );
}
