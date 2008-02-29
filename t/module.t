#!perl -Tw

use warnings;
use strict;

use Test::More tests => 9;
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

{
    my @filetypes = App::Ack::filetypes_supported();
    ok scalar(grep {$_ eq 'parrot'} @filetypes), 'parrot is supported filetype';
    cmp_ok scalar @filetypes, '>=', 39, 'At least 39 filetypes are supported';
}

{
    my $thppt = App::Ack::_get_thpppt();
    is length $thppt, 29, 'Bill the Cat';
}

{
    my $dir = 't/etc';
    my %opt;
    my $what = App::Ack::get_starting_points( [$dir], \%opt );
    is_deeply $what, [$dir], 'get_starting_points';

    my $iter = App::Ack::get_iterator( $what, \%opt );
    isa_ok $iter, 'CODE', 'get_iterator returs CODE';
}

