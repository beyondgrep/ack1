#!perl -Tw

use warnings;
use strict;

use Test::More tests => 3;
delete $ENV{ACK_OPTIONS};

use lib 't';

BEGIN {
    use_ok( 'App::Ack' );
}

{
    my $version = App::Ack::get_version_statement('Copyright');
    like $version, qr{This program is free software; you can redistribute it and/or modify it}, 'free software';
    like $version, qr{Copyright}, 'Copyright';
}

