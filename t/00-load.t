#!perl -Tw

use warnings;
use strict;
use Test::More tests => 1;

use App::Ack;
use App::Ack::Repository;
use App::Ack::Resource;
use File::Next;

pass( 'All modules loaded OK' );
diag( "Testing App::Ack $App::Ack::VERSION, File::Next $File::Next::VERSION, Perl $], $^X" );

done_testing();
