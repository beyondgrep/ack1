#!perl -Tw

use warnings;
use strict;

use Test::More tests => 1;

my $file = './ack';

my $ok = 1;
open( my $fh, '<', $file ) or die "Can't read $file: \n";
while ( my $line = <$fh> ) {
    chomp $line;
    if ( $line =~ /[^ -~]/ ) {
        my $col = $-[0] + 1;
        diag( "$file has hi-bit characters at $.:$col" );
        $ok = 0;
    }
}
close $fh;

ok( $ok, "$file has no hi-bit characters" );
