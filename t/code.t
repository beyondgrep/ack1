#!perl -Tw

use warnings;
use strict;

use Test::More;

my @files = ( qw( ack ack-standalone Ack.pm ), glob( 't/*.t' ) );

plan tests => scalar @files;

for my $file ( @files ) {
    open( my $fh, '<', $file ) or die "Can't read $file: \n";
    my $text = join( '', <$fh> );
    close $fh;

    is( index($text, "\t"), -1, "$file should have no embedded tabs" );
}
