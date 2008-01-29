#!perl

use warnings;
use strict;

use Test::More tests => 8;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

# change permissions of this file to unreadable
my $old_mode;
(undef, undef, $old_mode) = stat($0);
chmod 0000, $0;

# execute a search on this file
check_with( 'regex', $0 );
#   --count takes a different execution path
check_with( 'regex', '--count', $0 );

# change permissions back
chmod $old_mode, $0;

sub check_with {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($stdout, $stderr) = run_ack_with_stderr( @_ );
    ok( $? == 0,       'Search normal: exit code zero' );
    ok( @$stdout == 0, 'Search normal: no normal output' );
    ok( @$stderr == 1, 'Search normal: one line of stderr output' );
    # don't check for exact text of warning, the message text depends on LC_MESSAGES
    like( $stderr->[0], qr(file-permission\.t:), 'Search normal: warning message ok' );
}


