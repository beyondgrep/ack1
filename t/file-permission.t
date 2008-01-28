#!perl

use warnings;
use strict;

use Test::More tests => 8;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

my $old_mode;
(undef, undef, $old_mode) = stat($0);
chmod 0000, $0;

# execute a search on this file
ERROR_WITH_UNREADABLE_FILE: {
    my @results = run_ack( 'regex', $0, '2>&1');
    ok( $? == 0, 'Search normal: exit code zero' );
    ok( @results == 1, 'Search normal: one line of output' );
    like( $results[0], qr(^ack-standalone: t/file-permission\.t:), 'Search normal: warning message ok' );
}

# ack takes a different execution pass with --count
# therefore a 2nd test
ERROR_WITH_UNREADABLE_FILE_COUNT: {
    my @results = run_ack( 'regex', $0, '2>&1');
    ok( $? == 0, 'Search --count: exit code zero' );
    ok( @results == 1, 'Search  --count: one line of output' );
    like( $results[0], qr(^ack-standalone: t/file-permission\.t:), 'Search --count: warning message ok' );
}

chmod $old_mode, $0;
