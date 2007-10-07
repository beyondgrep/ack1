#!perl -Tw

use warnings;
use strict;

use Test::More tests => 4;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';

BEGIN {
    use_ok( 'App::Ack' );
}

{
    my $copyright = App::Ack::get_copyright();
    like $copyright, qr{Copyright \d+-\d+ Andy Lester}, 'Copyright';
}

{
    my $version = App::Ack::get_version_statement('Copyright');
    like $version, qr{This program is free software; you can redistribute it and/or modify it}, 'free software';
    like $version, qr{Copyright}, 'Copyright';
}

