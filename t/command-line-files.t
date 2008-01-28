#!perl -w

use warnings;
use strict;

use Test::More tests => 3;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

JUST_THE_DIR: {
    my @expected = split( /\n/, <<'EOF' );
t/swamp/options.pl:19:notawordhere
EOF

    my @files = qw( t/swamp );
    my @args = qw( notaword );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, q{One hit for specifying a dir} );
}


SPECIFYING_A_BAK_FILE: {
    my @expected = split( /\n/, <<'EOF' );
t/swamp/options.pl:19:notawordhere
t/swamp/options.pl.bak:19:notawordhere
EOF

    my @files = qw( t/swamp/options.pl t/swamp/options.pl.bak );
    my @args = qw( notaword );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, q{Two hits for specifying the file} );
}

FILE_NOT_THERE: {
    local $TODO = q{We haven't written anything to capture stdout yet};

    my @expected = split( /\n/, <<'EOF' );
ack-standalone: non-existent-file.txt: No such file or directory
EOF

    my @files = qw( non-existent-file.txt );
    my @args = qw( foo );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, q{Error if there's no file} );
}
