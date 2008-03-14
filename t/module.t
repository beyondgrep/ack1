#!perl -Tw

use warnings;
use strict;

use Test::More tests => 10;
use Data::Dumper qw(Dumper);
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

our @result;
{
    no warnings 'redefine';
    sub App::Ack::_print_first_filename { push @::result,  ['first_filename', @_]; }
    sub App::Ack::_print_separator      { push @::result,  ['separator',      @_]; }
    sub App::Ack::_print                { push @::result,  ['print',          @_]; }
    sub App::Ack::_print_filename       { push @::result,  ['filename',       @_]; }
    sub App::Ack::_print_line_no        { push @::result,  ['line_no',        @_]; }
}

{
    @result = ();
    my %opts = (
        regex => 'Shooter',
        all   => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir], \%opts );
    my $iter = App::Ack::get_iterator( $what, \%opts );
    App::Ack::filetype_setup();
    App::Ack::print_matches( $iter, \%opts );
    #diag Dumper \@result;
    is_deeply \@result, 
                [
                    [
                        'filename',
                        't/text/4th-of-july.txt',
                        ':'
                    ],
                    [
                        'line_no',
                        '37',
                        ':'
                    ],
                    [
                        'print',
                        qq(    -- "4th of July", Shooter Jennings\n)
                    ]
                ] or diag Dumper \@result;

}


