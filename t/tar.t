#!perl -w

use warnings;
use strict;

use Test::More skip_all => 'Testing the uncompleted feature of acking through a tar file.';
use Test::More tests => 6;

use lib 't';
use Util;
use File::Next ();

prep_environment();

my @files = qw(
    pit/jackson.pl
    pit/roundhouse.c
    pit/toast.rb
);

$_ = File::Next::reslash($_) for @files;
my $tar = File::Next::reslash( 't/swamp/solution8.tar' );

=pod

stuff to test

* filetypes works

=cut

BASIC_SEARCH: {
    my @expected = split( /\n/, <<"EOF" );
$tar:$files[0]:3:use constant NAME => 'Foo';
$tar:$files[1]:1:#define FOO 1
$tar:$files[2]:2:    FOO = 47
EOF

    # $ ack --plugin=Tar -i foo t/swamp
    my @files = qw( t/swamp );
    my @args = qw( --plugin=Tar -i foo );

    ack_sets_match( [ @args, @files ], \@expected, q{Basic case-insensitive searching} );
}
