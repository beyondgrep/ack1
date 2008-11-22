#!perl -w

use warnings;
use strict;

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

=pod

stuff to test

* filetypes works

=cut

BASIC_SEARCH: {
    my @expected = split( /\n/, <<"EOF" );
$files[0]:3:use constant NAME => 'Foo';
$files[1]:1:#define FOO 1
$files[2]:2:    FOO = 47
EOF

    # $ ack --plugin=Tar -i foo t/swamp
    my @files = qw( t/swamp );
    my @args = qw( --plugin=Tar -i foo );

    ack_sets_match( [ @args, @files ], \@expected, q{Basic case-insensitive searching} );
}
