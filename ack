#!/usr/local/bin/perl

use warnings;
use strict;

our $VERSION   = '1.40';
our $COPYRIGHT = 'Copyright 2005-2006 Andy Lester, all rights reserved.';

# These are all our globals.
my $is_windows;
my %opt;
my %type_wanted;
my $is_tty =  -t STDOUT;

BEGIN {
    $is_windows = ($^O =~ /MSWin32/);
    eval 'use Term::ANSIColor' unless $is_windows;

    $ENV{ACK_COLOR_MATCH}    ||= 'black on_yellow';
    $ENV{ACK_COLOR_FILENAME} ||= 'bold green';
}

use File::Next 0.22;
use App::Ack;
use Getopt::Long;

MAIN: {
    if ( $App::Ack::VERSION ne $main::VERSION ) {
        die "Program/library version mismatch\n\t$0 is $main::VERSION\n\t$INC{'App/Ack.pm'} is $App::Ack::VERSION\n";
    }
    if ( exists $ENV{ACK_SWITCHES} ) {
        warn "ACK_SWITCHES is no longer supported.  Use ACK_OPTIONS.\n";
    }

    # Priorities! Get the --thpppt checking out of the way.
    /^--th[bp]+t$/ && App::Ack::_thpppt($_) for @ARGV;

    $opt{group} =   $is_tty;
    $opt{color} =   $is_tty && !$is_windows;
    $opt{all} =     0;
    $opt{m} =       0;

    my %options = (
        a           => \$opt{all},
        'all!'      => \$opt{all},
        c           => \$opt{count},
        'color!'    => \$opt{color},
        count       => \$opt{count},
        f           => \$opt{f},
        'group!'    => \$opt{group},
        h           => \$opt{h},
        H           => \$opt{H},
        'i|ignore-case'         => \$opt{i},
        'l|files-with-match'    => \$opt{l},
        'm|max-count=i'         => \$opt{m},
        n                       => \$opt{n},
        'o|output:s'            => \$opt{o},
        'Q|literal'             => \$opt{Q},
        'v|invert-match'        => \$opt{v},
        'w|word-regexp'         => \$opt{w},


        'version'   => sub { version(); exit 1; },
        'help|?:s'  => sub { shift; App::Ack::show_help(@_); exit; },
        'man'       => sub {require Pod::Usage; Pod::Usage::pod2usage({-verbose => 2}); exit},

        'type=s'    => sub {
            my $dummy = shift;
            my $type = shift;
            my $wanted = ($type =~ s/^no//) ? 0 : 1; # must not be undef later

            if ( exists $type_wanted{ $type } ) {
                $type_wanted{ $type } = $wanted;
            }
            else {
                die qq{Unknown type "$type"\n};
            }
        }, # type sub
    );

    my @filetypes_supported = App::Ack::filetypes_supported();
    for my $i ( @filetypes_supported ) {
        $options{ "$i!" } = \$type_wanted{ $i };
    }

    # Stick any default switches at the beginning, so they can be overridden
    # by the command line switches.
    unshift @ARGV, split( ' ', $ENV{ACK_OPTIONS} ) if defined $ENV{ACK_OPTIONS};

    Getopt::Long::Configure( 'bundling', 'no_ignore_case' );
    GetOptions( %options ) or die "ack --help for options.\n";

    if ( defined( my $val = $opt{o} ) ) {
        if ( $val eq '' ) {
            $val = '$&';
        }
        else {
            $val = qq{"$val"};
        }
        $opt{o} = eval qq[ sub { $val } ];
    }

    my $filetypes_supported_set =   grep { defined $type_wanted{$_} && ($type_wanted{$_} == 1) } @filetypes_supported;
    my $filetypes_supported_unset = grep { defined $type_wanted{$_} && ($type_wanted{$_} == 0) } @filetypes_supported;

    # If anyone says --no-whatever, we assume all other types must be on.
    if ( !$filetypes_supported_set ) {
        for my $i ( keys %type_wanted ) {
            $type_wanted{$i} = 1 unless ( defined( $type_wanted{$i} ) || $i eq 'binary' );
        }
    }

    if ( !@ARGV && !$opt{f} ) {
        App::Ack::show_help();
        exit 1;
    }

    my $regex;

    if ( !$opt{f} ) {
        # REVIEW: This shouldn't be able to happen because of the help
        # check above.
        $regex = shift @ARGV or die "No regex specified\n";

        if ( $opt{Q} ) {
            $regex = quotemeta( $regex );
        }
        if ( $opt{w} ) {
            $regex = $opt{i} ? qr/\b$regex\b/i : qr/\b$regex\b/;
        }
        else {
            $regex = $opt{i} ? qr/$regex/i : qr/$regex/;
        }
    }

    my @what;
    if ( @ARGV ) {
        @what = @ARGV;

        # Show filenames unless we've specified one single file
        $opt{show_filename} = (@what > 1) || (!-f $what[0]);
    }
    else {
        my $is_filter = !-t STDIN;
        if ( $is_filter ) {
            # We're going into filter mode
            for ( qw( f l ) ) {
                $opt{$_} and die "ack: Can't use -$_ when acting as a filter.\n";
            }
            $opt{show_filename} = 0;
            search( '-', $regex, %opt );
            exit 0;
        }
        else {
            $opt{defaulted_to_dot} = 1;
            @what = '.'; # Assume current directory
            $opt{show_filename} = 1;
        }
    }
    $opt{show_filename} = 0 if $opt{h};
    $opt{show_filename} = 1 if $opt{H};

    my $file_filter = $opt{all} ? \&dash_a : \&is_interesting;
    my $descend_filter = $opt{n} ? sub {0} : \&App::Ack::skipdir_filter;

    my $iter =
        File::Next::files( {
            file_filter     => $file_filter,
            descend_filter  => $descend_filter,
            error_handler   => sub { my $msg = shift; warn "ack: $msg\n" },
        }, @what );


    while ( my $file = $iter->() ) {
        if ( $opt{f} ) {
            print "$file\n";
        }
        else {
            search( $file, $regex, %opt );
        }
    }
    exit 0;
}

sub is_interesting {
    return if $File::Next::name =~ /^\./;

    for my $type ( App::Ack::filetypes( $File::Next::name ) ) {
        return 1 if $type_wanted{$type};
    }
    return;
}

sub dash_a {
    my @types = App::Ack::filetypes( $File::Next::name );
    return 0 if (@types == 1) && ($types[0] eq '-ignore');
    return 1;
}

sub search {
    my $filename = shift;
    my $regex = shift;
    my %opt = @_;

    my $nmatches = 0;
    my $is_binary;

    my $fh;
    if ( $filename eq '-' ) {
        $fh = *STDIN;
        $is_binary = 0;
    }
    else {
        if ( !open( $fh, '<', $filename ) ) {
            warn "ack: $filename: $!\n";
            return;
        }
        if ( $opt{defaulted_to_dot} ) {
            $filename =~ s{^\Q./}{};
        }
        $is_binary = -B $filename;
    }

    local $_ = undef;
    while (<$fh>) {
        if ( /$regex/ ) { # If we have a matching line
            ++$nmatches;
            if ( !$opt{count} ) {
                next if $opt{v};

                # No point in searching more if we only want a list
                last if ( $nmatches == 1 && $opt{l} );

                my $out;
                if ( $opt{o} ) {
                    $out = $opt{o}->() . "\n";
                    $opt{show_filename} = 0;
                }
                else {
                    $out = $_;
                    $out =~ s/($regex)/colored($1,$ENV{ACK_COLOR_MATCH})/eg if $opt{color};
                }

                if ( $is_binary ) {
                    print "Binary file $filename matches\n";
                    last;
                }
                elsif ( $opt{show_filename} ) {
                    my $colorname = $opt{color} ? colored( $filename, $ENV{ACK_COLOR_FILENAME} ) : $filename;
                    if ( $opt{group} ) {
                        print "$colorname\n" if $nmatches == 1;
                        print "$.:$out";
                    }
                    else {
                        print "${colorname}:$.:$out";
                    }
                }
                else {
                    print $out;
                }
            } # Not just --count

            last if $opt{m} && ( $nmatches >= $opt{m} );
        } # match
        else { # no match
            if ( $opt{v} ) {
                print "${filename}:" if $opt{show_filename};
                print $_;
            }
        }
    } # while
    close $fh;

    if ( $opt{count} ) {
        print "${filename}:" if $opt{show_filename};
        print "${nmatches}\n";
    }
    else {
        if ( $opt{l} ) {
            print "$filename\n" if ($opt{v} && !$nmatches) || ($nmatches && !$opt{v});
        }
        else {
            print "\n" if $nmatches && $opt{show_filename} && $opt{group} && !$opt{v};
        }
    }

    return;
}

sub version() { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    print <<"END_OF_VERSION";
ack $App::Ack::VERSION

$COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
END_OF_VERSION

    return;
}

=head1 NAME

ack - grep-like text finder

=head1 SYNOPSIS

    ack [options] PATTERN [FILE...]
    ack -f [options] [DIRECTORY...]

=head1 DESCRIPTION

Ack is designed as a replacement for F<grep>.

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

The following directories will never be descended into:

=over 4

=item * F<_darcs>

=item * F<CVS>

=item * F<RCS>

=item * F<SCCS>

=item * F<.svn>

=item * F<blib>

=back

=head1 WHEN TO USE GREP

I<ack> trumps I<grep> as an everyday tool 99% of the time, but don't
throw I<grep> away, because there are times you'll still need it.

I<ack> only searches through files of types that it recognizes.  If
it can't tell what type a file is, then it won't look.  If that's
annoying to you, use I<grep>.

If you truly want to search every file and every directory, I<ack>
won't do it.  You'll need to rely on I<grep>.

If you need context around your matches, use I<grep>, but check
back in on I<ack> in the near future, because I'm adding it.

=head1 OPTIONS

=over 4

=item B<-a>, B<--all>

Operate on all files, regardless of type (but still skip directories
like F<blib>, F<CVS>, etc.

=item B<-c>, B<--count>

Suppress normal output; instead print a count of matching lines for each
input file.

=item B<--color>, B<--nocolor>

B<--color> highlights the matching text.  B<--nocolor> supresses
the color.  This is on by default unless the output is redirected,
or running under Windows.

=item B<-f>

Only print the files that would be searched, without actually doing
any searching.  PATTERN must not be specified, or it will be taken as
a path to search.

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

=item B<-Q>

Quote all metacharacters.  PATTERN is treated as a literal.

=item B<--thpppt>

Display the crucial Bill The Cat logo.  Note that the exact spelling
of B<--thpppppt> is not important.  It's checked against a regular
expression.

=item B<--type=TYPE>, B<--type=noTYPE>

Specify the types of files to include or exclude from a search.
TYPE is a filetype, like I<perl> or I<xml>.  B<--type=perl> can
also be specified as B<--perl>, and B<--type=noperl> can be done
as B<--noperl>.

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

=head1 ENVIRONMENT VARIABLES

=over 4

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

Thanks to everyone who has contributed to ack in any way, including
Nilson Santos F. Jr,
Elliot Shank,
Merijn Broeren,
Uwe Voelker,
Rick Scott,
Ask Bjørn Hansen,
Jerry Gay,
Will Coleda,
Mike O'Regan,
Slaven Rezic,
Mark Stosberg,
David Alan Pisoni,
Adriano Ferreira,
James Keenan,
Leland Johnson,
Ricardo Signes
and Pete Krawczyk.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2006 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
