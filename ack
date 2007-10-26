#!/usr/local/bin/perl

use warnings;
use strict;

our $VERSION   = '1.69_01';
# Check http://petdance.com/ack/ for updates

# These are all our globals.

use File::Next 0.40;
use App::Ack ();

MAIN: {
    unshift( @ARGV, App::Ack::read_ackrc() );
    App::Ack::load_colors();

    if ( $App::Ack::VERSION ne $main::VERSION ) {
        App::Ack::die( "Program/library version mismatch\n\t$0 is $main::VERSION\n\t$INC{'App/Ack.pm'} is $App::Ack::VERSION" );
    }
    if ( exists $ENV{ACK_SWITCHES} ) {
        App::Ack::warn( 'ACK_SWITCHES is no longer supported.  Use ACK_OPTIONS.' );
    }

    # Priorities! Get the --thpppt checking out of the way.
    /^--th[bp]+t$/ && App::Ack::_thpppt($_) for @ARGV;
    if ( !@ARGV ) {
        App::Ack::show_help();
        exit 1;
    }

    main();
}

sub main {
    my %opt = App::Ack::get_command_line_options();
    if ( !-t STDIN ) {
        # We're going into filter mode
        for ( qw( f g l ) ) {
            $opt{$_} and App::Ack::die( "Can't use -$_ when acting as a filter." );
        }
        $opt{show_filename} = 0;
        my $regex = App::Ack::build_regex( shift @ARGV, \%opt );
        if ( my $nargs = @ARGV ) {
            my $s = $nargs == 1 ? '' : 's';
            App::Ack::warn( "Ignoring $nargs argument$s on the command-line while acting as a filter." );
        }
        App::Ack::search( \*STDIN, 0, '-', $regex, \%opt );
        exit 0;
    }

    my $regex;
    my $file_matching = $opt{f} || $opt{g};
    if ( !$file_matching ) {
        @ARGV or App::Ack::die( 'No regular expression found.' );
        $regex = App::Ack::build_regex( shift @ARGV, \%opt );
    }

    my @what;
    if ( @ARGV ) {
        @what = $App::Ack::is_windows ? <@ARGV> : @ARGV;

        # Show filenames unless we've specified one single file
        $opt{show_filename} = (@what > 1) || (!-f $what[0]);
    }
    else {
        @what = '.'; # Assume current directory
        $opt{show_filename} = 1;
    }
    #XXX Barf if the starting points don't exist

    my $iter =
        File::Next::files( {
            file_filter     => $opt{all}
                                    ? sub { return App::Ack::is_searchable( $File::Next::name ) }
                                    : \&App::Ack::is_interesting,
            descend_filter  => $opt{n}
                                    ? sub {0}
                                    : \&App::Ack::skipdir_filter,
            error_handler   => sub { my $msg = shift; App::Ack::warn( $msg ) },
            sort_files      => $opt{sort_files},
            follow_symlinks => $opt{follow},
        }, @what );


    App::Ack::filetype_setup();
    if ( $opt{f} ) {
        App::Ack::print_files($iter, $opt{1});
    }
    elsif ( $opt{g} ) {
        my $regex = $opt{i} ? qr/$opt{g}/i : qr/$opt{g}/;
        App::Ack::print_files($iter, $opt{1}, $regex);
    }
    elsif ( $opt{l} || $opt{count} ) {
        my $nmatches = 0;
        while ( defined ( my $filename = $iter->() ) ) {
            my ($fh) = App::Ack::open_file( $filename );
            $nmatches += App::Ack::search_and_list( $fh, $filename, $regex, \%opt );
            App::Ack::close_file( $fh, $filename );
            last if $nmatches && $opt{1};
        }
    }
    else {
        $opt{show_filename} = 0 if $opt{h};
        $opt{show_filename} = 1 if $opt{H};
        $opt{show_filename} = 0 if $opt{output};

        my $nmatches = 0;
        while ( defined ( my $filename = $iter->() ) ) {
            my ($fh,$could_be_binary) = App::Ack::open_file( $filename );
            $nmatches += App::Ack::search( $fh, $could_be_binary, $filename, $regex, \%opt );
            App::Ack::close_file( $fh, $filename );
            last if $nmatches && $opt{1};
        }
    }
    exit 0;
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

=head1 DIRECTORY SELECTION

I<ack> descends through the directory tree of the starting directories
specified.  However, it will ignore the shadow directories used by
many version control systems, and the build directories used by the
Perl MakeMaker system.

The following directories will never be descended into: F<_darcs>,
F<CVS>, F<RCS>, F<SCCS>, F<.svn>, F<blib>, F<.git>

=head1 WHEN TO USE GREP

I<ack> trumps I<grep> as an everyday tool 99% of the time, but don't
throw I<grep> away, because there are times you'll still need it.

I<ack> only searches through files of types that it recognizes.  If
it can't tell what type a file is, then it won't look.  If that's
annoying to you, use I<grep>.

If you truly want to search every file and every directory, I<ack>
won't do it.  You'll need to rely on I<grep>.

=head1 OPTIONS

=over 4

=item B<-a>, B<--all>

Operate on all files, regardless of type (but still skip directories
like F<blib>, F<CVS>, etc.)

=item B<-A I<NUM>>, B<--after-context=I<NUM>>

Print I<NUM> lines of trailing context after matching lines.

=item B<-B I<NUM>>, B<--after-context=I<NUM>>

Print I<NUM> lines of leading context before matching lines.

=item B<-C [I<NUM>]>, B<--after-context[=I<NUM>]>

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

=item B<-f>

Only print the files that would be searched, without actually doing
any searching.  PATTERN must not be specified, or it will be taken as
a path to search.

=item B<--follow>, B<--nofollow>

Follow or don't follow symlinks, other than whatever starting files
or directories were specified on the command line.

This is off by default.

=item B<-g=I<REGEX>>

Same as B<-f>, but only print files that match I<REGEX>.  The entire
path and filename are matched against I<REGEX>, and I<REGEX> is a
Perl regular expression, not a shell glob.

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

=item B<-l>, B<--files-with-matches>

Only print the filenames of matching files, instead of the matching text.

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

=item B<-Q>, B<--literal>

Quote all metacharacters.  PATTERN is treated as a literal.

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

=item B<-v>, B<--invert-match>

Invert match: select non-matching lines

=item B<--version>

Display version and copyright information.

=item B<-w>, B<--word-regexp>

Force PATTERN to match only whole words.  The PATTERN is wrapped with
C<\b> metacharacters.

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

=head1 GOTCHAS

Note that FILES must still match valid selection rules.  For example,

    ack something --perl foo.rb

will search nothing, because I<foo.rb> is a Ruby file.

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ack at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ack>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ENHANCEMENTS

There is a list of enhancements I want to make to F<ack> in the ack
issues list at Google Code: L<http://code.google.com/p/ack/issues/list>

Yes, we want to be able to specify filetypes.

Yes, we want to add support for a F<.ackrc> file.

Please look in the issues list before requesting an enhancement.
And, of course, patches are always welcome.

=head1 SUPPORT

Support for and information about F<ack> can be found at:

=over 4

=item * The ack homepage

L<http://petdance.com/ack/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ack>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ack>

=item * Search CPAN

L<http://search.cpan.org/dist/ack>

=item * Subversion repository

L<http://ack.googlecode.com/svn/>

=back

=head1 ACKNOWLEDGEMENTS

How appropriate to have I<ack>nowledgements!

Thanks to everyone who has contributed to ack in any way, including
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

Copyright 2005-2007 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
