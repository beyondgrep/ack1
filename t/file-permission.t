#!perl

use warnings;
use strict;

use Test::More;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

plan skip_all => q{Can't be checked under Win32} if is_win32;
plan tests => 8;

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
    is( $?,                0, 'Search normal: exit code zero' );
    is( scalar @{$stdout}, 0, 'Search normal: no normal output' );
    is( scalar @{$stderr}, 1, 'Search normal: one line of stderr output' );
    # don't check for exact text of warning, the message text depends on LC_MESSAGES
    like( $stderr->[0], qr(file-permission\.t:), 'Search normal: warning message ok' );
}


