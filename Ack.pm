package App::Ack;

use warnings;
use strict;

=head1 NAME

App::Ack - A container for functions for the ack program

=head1 VERSION

Version 1.56

=cut

our $VERSION;
BEGIN {
    $VERSION = '1.56';
}

our %types;
our %mappings;
our @ignore_dirs;
our %ignore_dirs;
our $path_sep;
our $is_cygwin;

BEGIN {
    @ignore_dirs = qw( blib CVS RCS SCCS .svn _darcs .git );
    %ignore_dirs = map { ($_,1) } @ignore_dirs;
    %mappings = (
        asm         => [qw( s S )],
        binary      => q{Binary files, as defined by Perl's -B op (default: off)},
        cc          => [qw( c h xs )],
        cpp         => [qw( cpp m h C H )],
        csharp      => [qw( cs )],
        css         => [qw( css )],
        elisp       => [qw( el )],
        haskell     => [qw( hs lhs )],
        html        => [qw( htm html shtml )],
        lisp        => [qw( lisp )],
        java        => [qw( java )],
        js          => [qw( js )],
        mason       => [qw( mas )],
        ocaml       => [qw( ml mli )],
        parrot      => [qw( pir pasm pmc ops pod pg tg )],
        perl        => [qw( pl pm pod tt ttml t )],
        php         => [qw( php phpt htm html )],
        python      => [qw( py )],
        ruby        => [qw( rb rhtml rjs )],
        scheme      => [qw( scm )],
        shell       => [qw( sh bash csh ksh zsh )],
        sql         => [qw( sql ctl )],
        tex         => [qw( tex cls sty )],
        tt          => [qw( tt tt2 )],
        vim         => [qw( vim )],
        yaml        => [qw( yaml yml )],
        xml         => [qw( xml dtd xslt )],
    );

    use File::Spec ();
    $path_sep = File::Spec->catfile( '', '' );
    $path_sep = quotemeta( $path_sep );

    while ( my ($type,$exts) = each %mappings ) {
        if ( ref $exts ) {
            for my $ext ( @{$exts} ) {
                push( @{$types{$ext}}, $type );
            }
        }
    }

    $is_cygwin = ($^O eq 'cygwin');
}

=head1 SYNOPSIS

If you want to know about the F<ack> program

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 skipdir_filter

Standard filter to pass as a L<File::Next> descend_filter.  It
returns true if the directory is any of the ones we know we want
to skip.

=cut

sub skipdir_filter {
    return !exists $ignore_dirs{$_};
}

=head2 filetypes( $filename )

Returns a list of types that I<$filename> could be.  For example, a file
F<foo.pod> could be "perl" or "parrot".

The filetype will be C<undef> if we can't determine it.  This could
be if the file doesn't exist, or it can't be read.

It will be '-ignore' if it's something that ack should always ignore,
even under -a.

=cut

sub filetypes {
    my $filename = shift;

    return '-ignore' if should_ignore( $filename );

    # If there's an extension, look it up
    if ( $filename =~ m{\.([^\.$path_sep]+)$} ) {
        my $ref = $types{lc $1};
        return @{$ref} if $ref;
    }

    return unless -e $filename;

    # From Elliot Shank:
    #     I can't see any reason that -r would fail on these-- the ACLs look
    #     fine, and no program has any of them open, so the busted Windows
    #     file locking model isn't getting in there.  If I comment the if
    #     statement out, everything works fine
    # So, for cygwin, don't bother trying to check for readability.
    if ( !$is_cygwin ) {
        if ( !-r $filename ) {
            App::Ack::warn( "$filename: Permission denied" );
            return;
        }
    }

    return 'binary' if -B $filename;

    # If there's no extension, or we don't recognize it, check the shebang line
    my $fh;
    if ( !open( $fh, '<', $filename ) ) {
        App::Ack::warn( "$filename: $!" );
        return;
    }
    my $header = <$fh>;
    close $fh;
    return unless defined $header;
    if ( $header =~ /^#!/ ) {
        return 'perl'   if $header =~ /\bperl/;
        return 'php'    if $header =~ /\bphp\b/;
        return 'python' if $header =~ /\bpython\b/;
        return 'ruby'   if $header =~ /\bruby\b/;
        return 'shell'  if $header =~ /\b(ba|c|k|z)?sh\b/;
    }
    return 'xml' if $header =~ /<\?xml /;

    return;
}

=head2 should_ignore( $filename )

Returns true if the filename is one that we should ignore regardless
of filetype, like a coredump or a backup file.

=cut

sub should_ignore {
    my $filename = shift;

    return 1 if $filename =~ /~$/;
    return 1 if $filename =~ m{$path_sep?#.+#$};
    return 1 if $filename =~ m{$path_sep?core\.\d+$};

    return;
}

=head2 options_sanity_check( %opts )

Checks for sane command-line options.  For example, I<-l> doesn't
make sense with I<-C>.

=cut

sub options_sanity_check {
    my %opts = @_;
    my $ok = 1;

    $ok = 0 if _option_conflict( \%opts, 'l', [qw( A B C o group )] );
    $ok = 0 if _option_conflict( \%opts, 'l', [qw( m )] );
    $ok = 0 if _option_conflict( \%opts, 'f', [qw( A B C o m group )] );

    return $ok;
}

sub _option_conflict {
    my $opts = shift;
    my $used = shift;
    my $exclusives = shift;

    return if not defined $opts->{$used};

    my $bad = 0;
    for ( @$exclusives ) {
        if ( defined $opts->{$_} ) {
            print "The ", _opty($_), " option cannot be used with the ", _opty($used), " option.\n";
            $bad = 1;
        }
    }

    return $bad;
}

sub _opty {
    my $opt = shift;
    return length($opt)>1 ? "--$opt" : "-$opt";
}

=head2 warn( @_ )

Put out an ack-specific warning.

=cut

sub warn {
    CORE::warn( _my_program(), ": ", @_, "\n" );
}

=head2 die( @_ )

Die in an ack-specific way.

=cut

sub die {
    CORE::die( _my_program(), ": ", @_, "\n" );
}

sub _my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}


=head2 filetypes_supported()

Returns a list of all the types that we can detect.

=cut

sub filetypes_supported {
    return keys %mappings;
}

sub _thpppt {
    my $y = q{_   /|,\\'!.x',=(www)=,   U   };
    $y =~ tr/,x!w/\nOo_/;
    print "$y ack $_[0]!\n";
    exit 0;
}

=head2 show_help()

Dumps the help page to the user.

=cut

sub show_help {
    my $help_arg = shift || 0;

    return show_help_types() if $help_arg =~ /^types?/;

    my $ignore_dirs = _listify( @ignore_dirs );

    print <<"END_OF_HELP";
Usage: ack [OPTION]... PATTERN [FILES]
Search for PATTERN in each source file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories are checked.
ack may also search STDIN, but only if no FILES are specified, or if
one of FILES is "-".

Default switches may be specified in ACK_OPTIONS environment variable.

Example: ack -i select

Searching:
    -i              Ignore case distinctions
    -v              Invert match: select non-matching lines
    -w              Force PATTERN to match only whole words
    -Q              Quote all metacharacters; expr is literal

Search output:
    -l              Only print filenames containing matches
    -o              Show only the part of a line matching PATTERN
                    (turns off text highlighting)
    --output=expr   Output the evaluation of expr for each line
                    (turns off text highlighting)
    -m=NUM          Stop after NUM matches
    -H              Print the filename for each match
    -h              Suppress the prefixing filename on output
    -c, --count     Show number of lines matching per file

    --group         Group matches by file name.
                    (default: on when used interactively)
    --nogroup       One result per line, including filename, like grep
                    (default: on when the output is redirected)

    --[no]color     Highlight the matching text (default: on unless
                    output is redirected, or on Windows)

Context control:
    -B, --before-context=NUM
    -A, --after-context=NUM
    -C, --context=NUM
                    print NUM lines of context before and/or after
                    matching lines

File finding:
    -f              Only print the files found, without searching.
                    The PATTERN must not be specified.
    --sort-files    Sort the found files lexically.

File inclusion/exclusion:
    -n              No descending into subdirectories
    -a, --all       All files, regardless of extension (but still skips
                    $ignore_dirs dirs)
    --perl          Include only Perl files.
    --type=perl     Include only Perl files.
    --noperl        Exclude Perl files.
    --type=noperl   Exclude Perl files.
                    See "ack --help type" for supported filetypes.
    --[no]follow    Follow symlinks.  Default is off.

Miscellaneous:
    --help          This help
    --man           Man page
    --version       Display version & copyright
    --thpppt        Bill the Cat
END_OF_HELP

    return;
}


=head2 show_help_types()

Display the filetypes help subpage.

=cut

sub show_help_types {
    print <<'END_OF_HELP';
Usage: ack [OPTION]... PATTERN [FILES]

The following is the list of filetypes supported by ack.  You can
specify a file type with the --type=TYPE format, or the --TYPE
format.  For example, both --type=perl and --perl work.

Note that some extensions may appear in multiple types.  For example,
.pod files are both Perl and Parrot.

END_OF_HELP

    my @types = filetypes_supported();
    for my $type ( sort @types ) {
        next if $type =~ /^-/; # Stuff to not show
        my $ext_list = $mappings{$type};

        if ( ref $ext_list ) {
            $ext_list = join( ' ', map { ".$_" } @{$ext_list} );
        }
        printf( "    --[no]%-9.9s %s\n", $type, $ext_list );
    }

    return;
}

sub _listify {
    my @whats = @_;

    return '' if !@whats;

    my $end = pop @whats;
    return @whats ? join( ', ', @whats ) . " and $end" : $end;
}

=head2 version_statement( $copyright )

Prints the version information for ack.

=cut

sub version_statement {
    my $copyright = shift;
    print <<"END_OF_VERSION";
ack $App::Ack::VERSION

$copyright

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
END_OF_VERSION

    return;
}

1; # End of App::Ack
