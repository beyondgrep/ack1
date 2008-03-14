#!/usr/local/bin/perl

use warnings;
use strict;

our $VERSION   = '1.77_04';
# Check http://petdance.com/ack/ for updates

# These are all our globals.

use App::Ack ();

MAIN: {
    if ( $App::Ack::VERSION ne $main::VERSION ) {
        App::Ack::die( "Program/library version mismatch\n\t$0 is $main::VERSION\n\t$INC{'App/Ack.pm'} is $App::Ack::VERSION" );
    }

    # Do preliminary arg checking;
    my $env_ok = 1;
    for ( @ARGV ) {
        last if ( $_ eq '--' );

        # Priorities! Get the --thpppt checking out of the way.
        /^--th[pt]+t+$/ && App::Ack::_thpppt($_);

        # See if we want to ignore the environment. (Don't tell Al Gore.)
        if ( $_ eq '--noenv' ) {
            delete @ENV{qw( ACK_OPTIONS ACKRC ACK_COLOR_MATCH ACK_COLOR_FILENAME ACK_SWITCHES )};
            $env_ok = 0;
        }
    }
    unshift( @ARGV, App::Ack::read_ackrc() ) if $env_ok;
    App::Ack::load_colors();

    if ( exists $ENV{ACK_SWITCHES} ) {
        App::Ack::warn( 'ACK_SWITCHES is no longer supported.  Use ACK_OPTIONS.' );
    }

    if ( !@ARGV ) {
        App::Ack::show_help();
        exit 1;
    }

    main();
}

sub main {
    my %opt = App::Ack::get_command_line_options();
    if ( !-t STDIN && !eof(STDIN) ) {
        # We're going into filter mode
        filter_mode( \%opt );
        exit 0;
    }

    my $file_matching = $opt{f} || $opt{lines};
    if ( !$file_matching ) {
        @ARGV or App::Ack::die( 'No regular expression found.' );
        $opt{regex} = App::Ack::build_regex( defined $opt{regex} ? $opt{regex} : shift @ARGV, \%opt );
    }

    my $what = App::Ack::get_starting_points( \@ARGV, \%opt );
    my $iter = App::Ack::get_iterator( $what, \%opt );

    # check that all regexes do compile fine
    App::Ack::check_regex( $_ ) for @opt{ qw/regex G/ };

    App::Ack::filetype_setup();
    if ( $opt{f} ) {
        App::Ack::print_files( $iter, \%opt );
    }
    elsif ( $opt{l} || $opt{count} ) {
        App::Ack::print_files_with_matches( $iter, \%opt );
    }
    else {
        App::Ack::print_matches( $iter, \%opt );
    }
    exit 0;
}

sub filter_mode {
    my $opt = shift;

    for ( qw( f g l ) ) {
        $opt->{$_} and App::Ack::die( "Can't use -$_ when acting as a filter." );
    }
    $opt->{show_filename} = 0;
    $opt->{regex} = App::Ack::build_regex( defined $opt->{regex} ? $opt->{regex} : shift @ARGV, $opt );
    if ( my $nargs = @ARGV ) {
        my $s = $nargs == 1 ? '' : 's';
        App::Ack::warn( "Ignoring $nargs argument$s on the command-line while acting as a filter." );
    }
    App::Ack::search( \*STDIN, 0, '-', $opt );

    return;
}

=head1 NAME

ack - grep-like text finder

=head1 SYNOPSIS

    ack [options] PATTERN [FILE...]
    ack -f [options] [DIRECTORY...]

=head1 DESCRIPTION

Ack is designed as a replacement for 99% of the uses of F<grep>.

Ack searches the named input FILEs (or standard input if no files are
named, or the file name - is given) for lines containing a match to the
given PATTERN.  By default, ack prints the matching lines.

Ack can also list files that would be searched, without actually searching
them, to let you take advantage of ack's file-type filtering capabilities.

=head1 FILE SELECTION

I<ack> is intelligent about the files it searches.  It knows about
certain file types, based on both the extension on the file and,
in some cases, the contents of the file.  These selections can be
made with the B<--type> option.

With no file selections, I<ack> only searches files of types that
it recognizes.  If you have a file called F<foo.wango>, and I<ack>
doesn't know what a .wango file is, I<ack> won't search it.

The B<-a> option tells I<ack> to select all files, regardless of
type.

Some files will never be selected by I<ack>, even with B<-a>,
including:

=over 4

=item * Backup files: Files ending with F<~>, or F<#*#>

=item * Coredumps: Files matching F<core.\d+>

=back

However, I<ack> always searches the files given on the command line,
no matter what type. Furthermore, by specifying the B<-u> option all
files will be searched.

=head1 DIRECTORY SELECTION

I<ack> descends through the directory tree of the starting directories
specified.  However, it will ignore the shadow directories used by
many version control systems, and the build directories used by the
Perl MakeMaker system.  You may add or remove a directory from this
list with the B<--[no]ignore-dir> option. The option may be repeated
to add/remove multiple directories from the ignore list.

For a complete list of directories that do not get searched, run
F<ack --help>.

=head1 WHEN TO USE GREP

I<ack> trumps I<grep> as an everyday tool 99% of the time, but don't
throw I<grep> away, because there are times you'll still need it.

E.g., searching through huge files looking for regexes that can be
expressed with I<grep> syntax should be quicker with I<grep>.

=head1 OPTIONS

=over 4

=item B<-a>, B<--all>

Operate on all files, regardless of type (but still skip directories
like F<blib>, F<CVS>, etc.)

=item B<-A I<NUM>>, B<--after-context=I<NUM>>

Print I<NUM> lines of trailing context after matching lines.

=item B<-B I<NUM>>, B<--before-context=I<NUM>>

Print I<NUM> lines of leading context before matching lines.

=item B<-C [I<NUM>]>, B<--context[=I<NUM>]>

Print I<NUM> lines (default 2) of context around matching lines.

=item B<-c>, B<--count>

Suppress normal output; instead print a count of matching lines for
each input file.  If B<-l> is in effect, it will only show the
number of lines for each file that has lines matching.  Without
B<-l>, some line counts may be zeroes.

=item B<--color>, B<--nocolor>

B<--color> highlights the matching text.  B<--nocolor> supresses
the color.  This is on by default unless the output is redirected,
or running under Windows.

=item B<--env>, B<--noenv>

B<--noenv> disables all environment processing. No F<.ackrc> is read
and all environment variables are ignored. By default, F<ack> considers
F<.ackrc> and settings in the environment.

=item B<-f>

Only print the files that would be searched, without actually doing
any searching.  PATTERN must not be specified, or it will be taken as
a path to search.

=item B<--follow>, B<--nofollow>

Follow or don't follow symlinks, other than whatever starting files
or directories were specified on the command line.

This is off by default.

=item B<-G I<REGEX>>

Only paths matching I<REGEX> are included in the search.  The entire
path and filename are matched against I<REGEX>, and I<REGEX> is a
Perl regular expression, not a shell glob.

The options B<-i>, B<-w>, B<-v>, and B<-Q> do not apply to this I<REGEX>.

=item B<-g I<REGEX>>

Print files where the relative path + filename matches I<REGEX>. This option is
a convenience shortcut for B<-f> B<-G I<REGEX>>.

The options B<-i>, B<-w>, B<-v>, and B<-Q> do not apply to this I<REGEX>.

=item B<--group>, B<--nogroup>

B<--group> groups matches by file name with.  This is the default when
used interactively.

B<--nogroup> prints one result per line, like grep.  This is the default
when output is redirected.

=item B<-H>, B<--with-filename>

Print the filename for each match.

=item B<-h>, B<--no-filename>

Suppress the prefixing of filenames on output when multiple files are
searched.

=item B<--help>

Print a short help statement.

=item B<-i>, B<--ignore-case>

Ignore case in the search strings.

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<--[no]ignore-dir=DIRNAME>

Ignore directory (as CVS, .svn, etc are ignored). May be used multiple times
to ignore multiple directories. For example, mason users may wish to include
B<--ignore-dir=data>. The B<--noignore-dir> option allows users to search
directories which would normally be ignored (perhaps to research the contents
of F<.svn/props> directories).

=item B<--line=I<NUM>>

Only print line I<NUM> of each file. Multiple lines can be given with multiple
B<--line> options or as a comma separated list (B<--line=3,5,7>). B<--line=4-7>
also works. The lines are always output in ascending order, no matter the
order given on the command line.

=item B<-l>, B<--files-with-matches>

Only print the filenames of matching files, instead of the matching text.

=item B<--match I<REGEX>>

Specify the I<REGEX> explicitly. This is helpful if you don't want to put the
regex as your first argument, e.g. when executing multiple searches over the
same set of files.

    # search for foo and bar in given files
    ack file1 t/file* --match foo
    ack file1 t/file* --match bar

=item B<-m=I<NUM>>, B<--max-count=I<NUM>>

Stop reading a file after I<NUM> matches.

=item B<--man>

Print this manual page.

=item B<-n>

No descending into subdirectories.

=item B<-o>

Show only the part of each line matching PATTERN (turns off text
highlighting)

=item B<--output=I<expr>>

Output the evaluation of I<expr> for each line (turns off text
highlighting)

=item B<--passthru>

Prints all lines, whether or not they match the expression.  Highlighting
will still work, though, so it can be used to highlight matches while
still seeing the entire file, as in:

    # Watch a log file, and highlight a certain IP address
    $ tail -f ~/access.log | ack --passthru 123.45.67.89

=item B<--print0>

Only works in conjunction with -f, -g, -l or -c (filename output). The filenames
are output separated with a null byte instead of the usual newline. This is
helpful when dealing with filenames that contain whitespace, e.g.

    # remove all files of type html
    ack -f --html --print0 | xargs -0 rm -f

=item B<-Q>, B<--literal>

Quote all metacharacters in PATTERN, it is treated as a literal.

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<--rc=file>

Specify a path to an alternate F<.ackrc> file.

=item B<--sort-files>

Sorts the found files lexically.  Use this if you want your file
listings to be deterministic between runs of I<ack>.

=item B<--thpppt>

Display the all-important Bill The Cat logo.  Note that the exact
spelling of B<--thpppppt> is not important.  It's checked against
a regular expression.

=item B<--type=TYPE>, B<--type=noTYPE>

Specify the types of files to include or exclude from a search.
TYPE is a filetype, like I<perl> or I<xml>.  B<--type=perl> can
also be specified as B<--perl>, and B<--type=noperl> can be done
as B<--noperl>.

If a file is of both type "foo" and "bar", specifying --foo and
--nobar will exclude the file, because an exclusion takes precedence
over an inclusion.

Type specifications can be repeated and are ORed together.

See I<ack --help=types> for a list of valid types.

=item B<--type-add I<TYPE>=I<.EXTENSION>[,I<.EXT2>[,...]]>

Files with the given EXTENSION(s) are recognized as being of (the
existing) type TYPE. See also L</"Defining your own types">.


=item B<--type-set I<TYPE>=I<.EXTENSION>[,I<.EXT2>[,...]]>

Files with the given EXTENSION(s) are recognized as being of type
TYPE. This replaces an existing definition for type TYPE.  See also
L</"Defining your own types">.

=item B<-u, --unrestricted>

All files and directories (including blib/, core.*, ...) are searched,
nothing is skipped. When both B<-u> and B<--ignore-dir> are used, the
B<--ignore-dir> option has no effect.

=item B<-v>, B<--invert-match>

Invert match: select non-matching lines

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<--version>

Display version and copyright information.

=item B<-w>, B<--word-regexp>

Force PATTERN to match only whole words.  The PATTERN is wrapped with
C<\b> metacharacters.

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<-1>

Stops after reporting first match of any kind.  This is different
from B<--max-count=1> or B<-m1>, where only one match per file is
shown.  Also, B<-1> works with B<-f> and B<-g>, where B<-m> does
not.

=back

=head1 THE .ackrc FILE

The F<.ackrc> file contains command-line options that are prepended
to the command line before processing.  Multiple options may live
on multiple lines.  Lines beginning with a # are ignored.  A F<.ackrc>
might look like this:

    # Always sort the files
    --sort-files

    # Always color, even if piping to a filter
    --color

F<ack> looks in your home directory for the F<.ackrc>.  You can
specify another location with the F<ACKRC> variable, below.

If B<--noenv> is specified on the command line, the F<.ackrc> file
is ignored.

=head1 Defining your own types

ack allows you to define your own types in addition to the predefined
types. This is done with command line options that are best put into
an F<.ackrc> file - then you do not have to define your types over and
over again. In the following examples the options will always be shown
on one command line so that they can be easily copy & pasted.

I<ack --perl foo> searches for foo in all perl files. I<ack --help=types>
tells you, that perl files are files ending
in .pl, .pm, .pod or .t. So what if you would like to include .xs
files as well when searching for --perl files? I<ack --type-add perl=.xs --perl foo>
does this for you. B<--type-add> appends
additional extensions to an existing type.

If you want to define a new type, or completely redefine an existing
type, then use B<--type-set>. I<ack --type-set
eiffel=.e,.eiffel> defines the type I<eiffel> to include files with
the extensions .e or .eiffel. So to search for all eiffel files
containing the word Bertrand use I<ack --type-set eiffel=.e,.eiffel --eiffel Bertrand>.
As usual, you can also write B<--type=eiffel>
instead of B<--eiffel>. Negation also works, so B<--noeiffel> excludes
all eiffel files from a search. Redefining also works: I<ack --type-set cc=.c,.h>
and I<.xs> files no longer belong to the type I<cc>.

In order to see all currently defined types, use I<--help types>, e.g.
I<ack --type-set backup=.bak --type-add perl=.perl --help types>

Restrictions:

=over 4

=item

The types 'skipped', 'make', 'binary' and 'text' are considered "builtin" and
cannot be altered.

=item

The shebang line recognition of the types 'perl', 'ruby', 'php', 'python',
'shell' and 'xml' cannot be redefined by I<--type-set>, it is always
active. However, the shebang line is only examined for files where the
extension is not recognised. Therefore it is possible to say
I<ack --type-set perl=.perl --type-set foo=.pl,.pm,.pod,.t --perl --nofoo> and
only find your shiny new I<.perl> files (and all files with unrecognized extension
and perl on the shebang line).

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item ACKRC

Specifies the location of the F<.ackrc> file.  If this file doesn't
exist, F<ack> looks in the default location.

=item ACK_OPTIONS

This variable specifies default options to be placed in front of
any explicit options on the command line.

=item ACK_COLOR_FILENAME

Specifies the color of the filename when it's printed in B<--group>
mode.  By default, it's "bold green".

The recognized attributes are clear, reset, dark, bold, underline,
underscore, blink, reverse, concealed black, red, green, yellow,
blue, magenta, on_black, on_red, on_green, on_yellow, on_blue,
on_magenta, on_cyan, and on_white.  Case is not significant.
Underline and underscore are equivalent, as are clear and reset.
The color alone sets the foreground color, and on_color sets the
background color.

=item ACK_COLOR_MATCH

Specifies the color of the matching text when printed in B<--color>
mode.  By default, it's "black on_yellow".

See B<ACK_COLOR_FILENAME> for the color specifications.

=back

Note: The above environment variables are ignored if B<--noenv> is
specified on the command line.

=head1 ACK & OTHER TOOLS

=head2 Vim integration

F<ack> integrates easily with the Vim text editor. Set this in your
F<.vimrc> to use F<ack> instead of F<grep>:

    set grepprg=ack\ -a

That examples uses C<-a> to search through all files, but you may
use other default flags. Now you can search with F<ack> and easily
step through the results in Vim:

  :grep Dumper perllib

=cut

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to the issues list at
Google Code: L<http://code.google.com/p/ack/issues/list>

=head1 ENHANCEMENTS

All enhancement requests MUST first be posted to the ack-users
mailing list at L<http://groups.google.com/group/ack-users>.  I
will not consider a request without it first getting seen by other
ack users.

There is a list of enhancements I want to make to F<ack> in the ack
issues list at Google Code: L<http://code.google.com/p/ack/issues/list>

Patches are always welcome, but patches with tests get the most
attention.

=head1 SUPPORT

Support for and information about F<ack> can be found at:

=over 4

=item * The ack homepage

L<http://petdance.com/ack/>

=item * The ack issues list at Google Code

L<http://code.google.com/p/ack/issues/list>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ack>

=item * Search CPAN

L<http://search.cpan.org/dist/ack>

=item * Subversion repository

L<http://ack.googlecode.com/svn/>

=back

=head1 ACKNOWLEDGEMENTS

How appropriate to have I<ack>nowledgements!

Thanks to everyone who has contributed to ack in any way, including
Jan Dubois,
Christopher J. Madsen,
Matthew Wickline,
David Dyck,
Jason Porritt,
Jjgod Jiang,
Thomas Klausner,
Uri Guttman,
Peter Lewis,
Kevin Riggle,
Ori Avtalion,
Torsten Blix,
Nigel Metheringham,
Gabor Szabo,
Tod Hagan,
Michael Hendricks,
Ævar Arnfjörð Bjarmason,
Piers Cawley,
Stephen Steneker,
Elias Lutfallah,
Mark Leighton Fisher,
Matt Diephouse,
Christian Jaeger,
Bill Sully,
Bill Ricker,
David Golden,
Nilson Santos F. Jr,
Elliot Shank,
Merijn Broeren,
Uwe Voelker,
Rick Scott,
Ask Bjørn Hansen,
Jerry Gay,
Will Coleda,
Mike O'Regan,
Slaven Rezić,
Mark Stosberg,
David Alan Pisoni,
Adriano Ferreira,
James Keenan,
Leland Johnson,
Ricardo Signes
and Pete Krawczyk.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2008 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
