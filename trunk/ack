#!/usr/local/bin/perl

use warnings;
use strict;

our $is_windows;
BEGIN {
    $is_windows = ($^O =~ /MSWin32/);
}

BEGIN {
    eval { use Term::ANSIColor } unless $is_windows;
}

use App::Ack;
use Getopt::Long;

our %opt;
our %lang;

our $is_tty =  -t STDOUT;
$opt{group} =   $is_tty;
$opt{color} =   $is_tty && !$is_windows;
$opt{all} =     0;
$opt{help} =    0;
$opt{m} =       0;

my %options = (
    a           => \$opt{all},
    "all!"      => \$opt{all},
    c           => \$opt{count},
    count       => \$opt{count},
    f           => \$opt{f},
    h           => \$opt{h},
    H           => \$opt{H},
    i           => \$opt{i},
    l           => \$opt{l},
    "m=i"       => \$opt{m},
    n           => \$opt{n},
    o           => \$opt{o},
    v           => \$opt{v},
    w           => \$opt{w},

    "group!"    => \$opt{group},
    "color!"    => \$opt{color},
    "help"      => \$opt{help},
    "version"   => sub { print "ack $App::Ack::VERSION\n" and exit 1; },
);

my @filetypes_supported = App::Ack::filetypes_supported();
for my $i ( @filetypes_supported ) {
    $options{ "$i!" } = \$lang{ $i };
}
$options{ "js!" } = \$lang{ javascript };

# Stick any default switches at the beginning, so they can be overridden
# by the command line switches.
unshift @ARGV, split( " ", $ENV{ACK_SWITCHES} ) if defined $ENV{ACK_SWITCHES};

map { App::Ack::_thpppt($_) if /^--th[bp]+t$/ } @ARGV;
Getopt::Long::Configure( "bundling" );
GetOptions( %options ) or die "ack --help for options.\n";

my $filetypes_supported_set =   grep { defined $lang{$_} && ($lang{$_} == 1) } @filetypes_supported;
my $filetypes_supported_unset = grep { defined $lang{$_} && ($lang{$_} == 0) } @filetypes_supported;

# If anyone says --noperl, we assume all other languages must be on.
if ( !$filetypes_supported_set ) {
    for ( keys %lang ) {
        $lang{$_} = 1 unless defined $lang{$_};
    }
}

if ( $opt{help} || (!@ARGV && !$opt{f}) ) {
    App::Ack::show_help();
    exit 1;
}

my $re;

if ( !$opt{f} ) {
    $re = shift or die "No regex specified\n";

    if ( $opt{w} ) {
        $re = $opt{i} ? qr/\b$re\b/i : qr/\b$re\b/;
    }
    else {
        $re = $opt{i} ? qr/$re/i : qr/$re/;
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
        search( "-", $re, %opt );
        exit 0;
    }
    else {
        @what = ""; # Assume current directory
        $opt{show_filename} = 1;
    }
}
$opt{show_filename} = 0 if $opt{h};
$opt{show_filename} = 1 if $opt{H};

my $filter = $opt{all} ? sub {1} : \&is_interesting;
my $iter = App::Ack::interesting_files( $filter, !$opt{n}, @what );

while ( my $file = $iter->() ) {
    if ( $opt{f} ) {
        print "$file\n";
    }
    else {
        search( $file, $re, %opt );
    }
}
exit 0;

sub is_interesting {
    my $file = shift;

    return if $file =~ /~$/;
    return if $file =~ /^\./;

    for my $type ( App::Ack::filetypes( $file ) ) {
        return 1 if $lang{$type};
    }
    return;
}

sub search {
    my $filename = shift;
    my $regex = shift;
    my %opt = @_;

    my $nmatches = 0;

    my $fh;
    if ( $filename eq "-" ) {
        $fh = *STDIN;
    }
    else {
        if ( !open( $fh, "<", $filename ) ) {
            warn "ack: $filename: $!\n";
            return;
        }
    }

    local $_; ## no critic
    while (<$fh>) {
        if ( /$re/ ) { # If we have a matching line
            ++$nmatches;
            if ( !$opt{count} ) {
                if ( $nmatches == 1 ) {
                    # No point in searching more if we only want a list
                    last if $opt{l};
                }
                next if $opt{v};

                my $out;
                if ( $opt{o} ) {
                    $out = "$&\n";
                }
                else {
                    $out = $_;
                    $out =~ s/($re)/colored($1,"black on_yellow")/eg if $opt{color};
                }

                if ( $opt{show_filename} ) {
                    my $colorname = $opt{color} ? colored( $filename, "bold green" ) : $filename;
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
        print "${filename}:${nmatches}\n";
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

=head1 TODO

=over 4

=item * Search through standard input if no files specified

=item * Add a --[no]comment option to grep inside or exclude comments.

=back

=cut
