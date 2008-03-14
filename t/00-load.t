#!perl -Tw

use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
    use_ok( 'App::Ack' );
    use_ok( 'File::Next' );
}

diag( "Testing App::Ack $App::Ack::VERSION, File::Next $File::Next::VERSION, Perl $], $^X" );
