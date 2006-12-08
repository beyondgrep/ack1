#!/usr/local/bin/perl

use warnings;
use strict;

our $VERSION   = '1.34';
our $COPYRIGHT = 'Copyright 2005-2006 Andy Lester, all rights reserved.';

# These are all our globals.
my $is_windows;
my %opt;
my %lang;
my $is_tty =  -t STDOUT;

BEGIN {
    $is_windows = ($^O =~ /MSWin32/);
}

BEGIN {
    eval 'use Term::ANSIColor' unless $is_windows;
}

use File::Next 0.22;
use App::Ack;
use Getopt::Long;


MAIN: {
    die "Version mismatch" unless $App::Ack::VERSION eq $main::VERSION;
    # Priorities! Get the --thpppt checking out of the way.
    /^--th[bp]+t$/ && App::Ack::_thpppt($_) for @ARGV;

    $opt{group} =   $is_tty;
    $opt{color} =   $is_tty && !$is_windows;
    $opt{all} =     0;
    $opt{help} =    0;
    $opt{m} =       0;

    my %options = (
        a           => \$opt{all},
        'all!'      => \$opt{all},
        c           => \$opt{count},
        count       => \$opt{count},
        f           => \$opt{f},
        h           => \$opt{h},
        H           => \$opt{H},
        i           => \$opt{i},
        l           => \$opt{l},
        'm=i'       => \$opt{m},
        n           => \$opt{n},
        'o|output:s' => \$opt{o},
        'Q|literal' => \$opt{Q},
        v           => \$opt{v},
        w           => \$opt{w},

        'group!'    => \$opt{group},
        'color!'    => \$opt{color},
        'help'      => \$opt{help},
        'version'   => sub { version(); exit 1; },
    );


    my @filetypes_supported = App::Ack::filetypes_supported();
    for my $i ( @filetypes_supported ) {
        $options{ "$i!" } = \$lang{ $i };
    }

    # Stick any default switches at the beginning, so they can be overridden
    # by the command line switches.
    unshift @ARGV, split( ' ', $ENV{ACK_SWITCHES} ) if defined $ENV{ACK_SWITCHES};

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

    my $filetypes_supported_set =   grep { defined $lang{$_} && ($lang{$_} == 1) } @filetypes_supported;
    my $filetypes_supported_unset = grep { defined $lang{$_} && ($lang{$_} == 0) } @filetypes_supported;

    # If anyone says --no-whatever, we assume all other languages must be on.
    if ( !$filetypes_supported_set ) {
        for my $i ( keys %lang ) {
            $lang{$i} = 1 unless ( defined( $lang{$i} ) || $i eq 'binary' );
        }
    }

    if ( $opt{help} || (!@ARGV && !$opt{f}) ) {
        App::Ack::show_help();
        exit 1;
    }

    my $regex;

    if ( !$opt{f} ) {
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
        return 1 if $lang{$type};
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
                    $out =~ s/($regex)/colored($1,"black on_yellow")/eg if $opt{color};
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

ack - grep-like text finder for large trees of text

=head1 DESCRIPTION

F<ack> is a F<grep>-like program with optimizations for searching through
large trees of source code.

Key improvements include:

=over 4

=item * Defaults to only searching program source code

=item * Defaults to recursively searching directories

=item * Ignores F<blib> directories.

=item * Ignores source code control directories, like F<CVS>, F<.svn> and F<_darcs>.

=item * Uses Perl regular expressions

=item * Highlights matched text

=back

=cut
