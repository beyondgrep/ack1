#!/usr/local/bin/perl

use warnings;
use strict;

our $VERSION   = '1.38';
our $COPYRIGHT = 'Copyright 2005-2006 Andy Lester, all rights reserved.';

# These are all our globals.
my $is_windows;
my %opt;
my %type_wanted;
my $is_tty =  -t STDOUT;

BEGIN {
    $is_windows = ($^O =~ /MSWin32/);
    eval 'use Term::ANSIColor' unless $is_windows;
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
        count       => \$opt{count},
        f           => \$opt{f},
        h           => \$opt{h},
        H           => \$opt{H},
        'i|ignore-case'         => \$opt{i},
        'l|files-with-match'    => \$opt{l},
        'm|max-count=i'         => \$opt{m},
        n           => \$opt{n},
        'o|output:s' => \$opt{o},
        'Q|literal'             => \$opt{Q},
        'v|invert-match'        => \$opt{v},
        'w|word-regexp'         => \$opt{w},

        'group!'    => \$opt{group},
        'color!'    => \$opt{color},
        'version'   => sub { version(); exit 1; },

        'help|?'    => sub {App::Ack::show_help(); exit},
        'man'       => sub {require Pod::Usage; Pod::Usage::pod2usage({-verbose => 2}); exit},
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

    my $is_filter = !-t STDIN;
    my @what;
    if ( @ARGV ) {
        @what = @ARGV;

        # Show filenames unless we've specified one single file
        $opt{show_filename} = (@what > 1) || (!-f $what[0]);
    }
    else {
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

    my $file_filter = $opt{all} ? sub {1} : \&is_interesting;
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
    return if /~$/;
    return if /^\./;

    my $filename = $File::Next::name;
    for my $type ( App::Ack::filetypes( $filename ) ) {
        return 1 if $type_wanted{$type};
    }
    return;
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

    local $_; ## no critic
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
                    $out =~ s/($regex)/colored($1,'black on_yellow')/eg if $opt{color};
                }

                if ( $is_binary ) {
                    print "Binary file $filename matches\n";
                    last;
                }
                elsif ( $opt{show_filename} ) {
                    my $colorname = $opt{color} ? colored( $filename, 'bold green' ) : $filename;
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

This variable specifies default options to be placed in front of any explicit options.

=back

=head1 GOTCHAS

Note that FILES must still match valid selection rules.  For example,

    ack something --perl foo.rb

will search nothing, because I<foo.rb> is a Ruby file.

=cut
