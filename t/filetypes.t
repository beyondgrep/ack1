#!perl -Tw

use warnings;
use strict;

use Test::More tests => 8;

BEGIN {
    use_ok( 'App::Ack' );
}

my @foo_pod_types = App::Ack::filetypes( "foo.pod" ); # 5.6.1 doesn't like to sort(filetypes())
is_deeply( [sort @foo_pod_types], [qw( parrot perl )], 'foo.pod can be multiple things' );
is_deeply( [App::Ack::filetypes( "Bongo.pm" )], [qw( perl )], 'Bongo.pm' );
is_deeply( [App::Ack::filetypes( "Makefile.PL" )], [qw( perl )], 'Makefile.PL' );
is_deeply( [App::Ack::filetypes( "Unknown.wango" )], [], 'Unknown' );

ok(  App::Ack::is_filetype( "foo.pod", "perl" ), 'foo.pod can be perl' );
ok(  App::Ack::is_filetype( "foo.pod", "parrot" ), 'foo.pod can be parrot' );
ok( !App::Ack::is_filetype( "foo.pod", "ruby" ), 'foo.pod cannot be ruby' );

