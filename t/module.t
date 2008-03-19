#!perl -Tw

use warnings;
use strict;

use Test::More tests => 32;
use Data::Dumper;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';

BEGIN {
    use_ok( 'App::Ack' );
}

my $dir_sep = $^O eq 'MSWin32' ? '\\' : '/';
{
    my $copyright = App::Ack::get_copyright();
    like( $copyright, qr{Copyright \d+-\d+ Andy Lester}, 'Copyright' );
}

{
    my $version = App::Ack::get_version_statement('Copyright');
    like( $version, qr{This program is free software; you can redistribute it and/or modify it}, 'free software' );
    like( $version, qr{Copyright}, 'Copyright' );
}

{
    my @filetypes = App::Ack::filetypes_supported();
    ok( scalar(grep {$_ eq 'parrot'} @filetypes), 'parrot is supported filetype' );
    cmp_ok( scalar @filetypes, '>=', 39, 'At least 39 filetypes are supported' );
}

{
    my $thppt = App::Ack::_get_thpppt();
    is( length $thppt, 29, 'Bill the Cat' );
}

{
    my $dir = 't/etc';
    my %opt;
    my $what = App::Ack::get_starting_points( [$dir], \%opt );
    is_deeply( $what, ["t${dir_sep}etc"], 'get_starting_points' );

    my $iter = App::Ack::get_iterator( $what, \%opt );
    isa_ok( $iter, 'CODE', 'get_iterator returs CODE' );
}

our @result;
our @warns;
{
    no warnings 'redefine';
    sub App::Ack::_print_first_filename { push @::result,  ['first_filename', @_]; }
    sub App::Ack::_print_separator      { push @::result,  ['separator',      @_]; }
    sub App::Ack::_print                { push @::result,  ['print',          @_]; }
    sub App::Ack::_print_filename       { push @::result,  ['filename',       @_]; }
    sub App::Ack::_print_line_no        { push @::result,  ['line_no',        @_]; }
    sub App::Ack::_print_count          { push @::result,  ['count',          @_]; }
    sub App::Ack::_print_count0         { push @::result,  ['count0',         @_]; }
    sub App::Ack::warn                  { push @::warns,   $_[0];                   } ## no critic (ProhibitBuiltinHomonyms)

}

my $iter1;
{
    @result = ();
    my %opts = (
        regex => 'Shooter',
        all   => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir], \%opts );
    is_deeply( $what, ["t${dir_sep}text"], 'get_starting_points' );
    my $iter = App::Ack::get_iterator( $what, \%opts );
    $iter1 = $iter;
    is( ref $iter, 'CODE' );
    App::Ack::filetype_setup();
    App::Ack::print_matches( $iter, \%opts );
    my $wanted = [
        [
        'filename',
        "t${dir_sep}text${dir_sep}4th-of-july.txt",
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
            ],
        ];
    is_deeply( \@result, $wanted ) or diag Dumper \@result;

    is_deeply( \@warns, [], 'no warning' );
}


{
    @result = ();
    my %opts = (
        regex => 'matter',
        all   => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir, 't/etc'], \%opts );
    is_deeply $what, ["t${dir_sep}text", "t${dir_sep}etc"], 'get_starting_points';
    my $iter = App::Ack::get_iterator( $what, \%opts );
    isnt $iter, $iter1, 'different iterators';
    is ref $iter, 'CODE';
    App::Ack::filetype_setup();
    App::Ack::print_matches( $iter, \%opts );
    is_deeply \@result,
        [
           [
             'filename',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             ':'
           ],
           [
             'line_no',
             '4',
             ':'
           ],
           [
             'print',
             "That spiritual matters are enslaved to history\n"
           ],
           [
             'filename',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             ':'
           ],
           [
             'line_no',
             '10',
             ':'
           ],
           [
             'print',
             "Somehow no matter what the world keeps turning\n"
           ],
           [
             'filename',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             ':'
           ],
           [
             'line_no',
             '20',
             ':'
           ],
           [
             'print',
             "It doesn't matter if it's real or not\n"
           ],
           [
             'filename',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             ':'
           ],
           [
             'line_no',
             '23',
             ':'
           ],
           [
             'print',
             "Somehow no matter what the world keeps turning\n"
           ]
         ];
    is_deeply \@warns, [], 'no warning';
}

{
    @result = ();
    my %opts = (
        regex => 'matter',
        all   => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir, 't/nosuchdir'], \%opts );
    TODO: {
        local $TODO = 'remove the non-existing directory from the starting_points';
        is_deeply $what, [$dir], 'get_starting_points';
    }
    # XXX should the error be 't\nosuchdir: No such file or directory' on Windows?
    is_deeply \@warns, [ 't/nosuchdir: No such file or directory' ], "warning";
}

{
    @result = ();
    my %opts = (
        regex => 'Shooter',
        all   => 1,
        count => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir], \%opts );
    is_deeply( $what, ["t${dir_sep}text"], 'get_starting_points' );
    my $iter = App::Ack::get_iterator( $what, \%opts );
    is( ref $iter, 'CODE' );
    App::Ack::filetype_setup();
    App::Ack::print_files_with_matches( $iter, \%opts );
    my $expected = [
           [
             'count',
             "t${dir_sep}text${dir_sep}4th-of-july.txt",
             1,
             "\n",
             1
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}boy-named-sue.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}shut-up-be-happy.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}freedom-of-choice.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}me-and-bobbie-mcgee.txt",
             "\n"
           ]
         ];

    is_deeply \@result, $expected;
}

{
    @result = ();
    my %opts = (
        regex => 'matter',
        all   => 1,
        count => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir, 't/etc'], \%opts );
    is_deeply $what, ["t${dir_sep}text", "t${dir_sep}etc"], 'get_starting_points';
    my $iter = App::Ack::get_iterator( $what, \%opts );
    is ref $iter, 'CODE';
    App::Ack::filetype_setup();
    App::Ack::print_files_with_matches( $iter, \%opts );
    my $expected = [
           [
             'count0',
             "t${dir_sep}text${dir_sep}4th-of-july.txt",
             "\n",
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}boy-named-sue.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}shut-up-be-happy.txt",
             "\n"
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             4,
             "\n",
             1
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}freedom-of-choice.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}text${dir_sep}me-and-bobbie-mcgee.txt",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.rb.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}buttonhook.xml.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.php.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.foobar.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.py.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}buttonhook.html.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.sh.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.pl.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}buttonhook.rss.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}shebang.empty.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}buttonhook.rfc.xxx",
             "\n"
           ],
           [
             'count0',
             "t${dir_sep}etc${dir_sep}buttonhook.noxml.xxx",
             "\n"
           ]
         ];
    is_deeply \@result, $expected;
}


{
    @result = ();
    my %opts = (
        regex => 'Shooter',
        all   => 1,
        count => 1,
        v     => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir], \%opts );
    is_deeply( $what, ["t${dir_sep}text"], 'get_starting_points' );
    my $iter = App::Ack::get_iterator( $what, \%opts );
    is( ref $iter, 'CODE' );
    App::Ack::filetype_setup();
    App::Ack::print_files_with_matches( $iter, \%opts );
    my $expected = [
           [
             'count',
             "t${dir_sep}text${dir_sep}4th-of-july.txt",
             36,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}boy-named-sue.txt",
             72,
             "\n",
             1,
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}shut-up-be-happy.txt",
             26,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             26,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}freedom-of-choice.txt",
             50,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}me-and-bobbie-mcgee.txt",
             32,
             "\n",
             1
           ]
         ];

    is_deeply \@result, $expected;
}

{
    @result = ();
    my %opts = (
        regex => 'matter',
        all   => 1,
        count => 1,
        v     => 1,
    );
    my $dir = 't/text';
    my $what = App::Ack::get_starting_points( [$dir], \%opts );
    is_deeply( $what, ["t${dir_sep}text"], 'get_starting_points' );
    my $iter = App::Ack::get_iterator( $what, \%opts );
    is( ref $iter, 'CODE' );
    App::Ack::filetype_setup();
    App::Ack::print_files_with_matches( $iter, \%opts );
    my $expected = [
           [
             'count',
             "t${dir_sep}text${dir_sep}4th-of-july.txt",
             37,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}boy-named-sue.txt",
             72,
             "\n",
             1,
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}shut-up-be-happy.txt",
             26,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}science-of-myth.txt",
             22,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}freedom-of-choice.txt",
             50,
             "\n",
             1
           ],
           [
             'count',
             "t${dir_sep}text${dir_sep}me-and-bobbie-mcgee.txt",
             32,
             "\n",
             1
           ]
         ];

    is_deeply \@result, $expected;
}
