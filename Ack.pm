package App::Ack;

use warnings;
use strict;

use File::Next 0.40;

=head1 NAME

App::Ack - A container for functions for the ack program

=head1 VERSION

Version 1.80

=cut

our $VERSION;
our $COPYRIGHT;
BEGIN {
    $VERSION = '1.80';
    $COPYRIGHT = 'Copyright 2005-2008 Andy Lester, all rights reserved.';
}

our $fh;

BEGIN {
    $fh = *STDOUT;
}


our %types;
our %type_wanted;
our %mappings;
our %ignore_dirs;

our $dir_sep_chars;
our $is_cygwin;
our $is_windows;
our $to_screen;

use File::Spec ();
use File::Glob ':glob';
use Getopt::Long ();

BEGIN {
    %ignore_dirs = (
        '.bzr'              => 'Bazaar',
        '.cdv'              => 'Codeville',
        '~.dep'             => 'Interface Builder',
        '~.dot'             => 'Interface Builder',
        '~.nib'             => 'Interface Builder',
        '~.plst'            => 'Interface Builder',
        '.git'              => 'Git',
        '.hg'               => 'Mercurial',
        '.pc'               => 'quilt',
        '.svn'              => 'Subversion',
        blib                => 'Perl module building',
        CVS                 => 'CVS',
        RCS                 => 'RCS',
        SCCS                => 'SCCS',
        _darcs              => 'darcs',
        _sgbak              => 'Vault/Fortress',
        'autom4te.cache'    => 'autoconf',
        'cover_db'          => 'Devel::Cover',
        _build              => 'Module::Build',
    );

    %mappings = (
        actionscript => [qw( as mxml )],
        asm         => [qw( asm s )],
        batch       => [qw( bat cmd )],
        binary      => q{Binary files, as defined by Perl's -B op (default: off)},
        cc          => [qw( c h xs )],
        cfmx        => [qw( cfc cfm cfml )],
        cpp         => [qw( cpp cc m hpp hh h )],
        csharp      => [qw( cs )],
        css         => [qw( css )],
        elisp       => [qw( el )],
        erlang      => [qw( erl )],
        fortran     => [qw( f f77 f90 f95 f03 for ftn fpp )],
        haskell     => [qw( hs lhs )],
        hh          => [qw( h )],
        html        => [qw( htm html shtml xhtml )],
        java        => [qw( java properties )],
        js          => [qw( js )],
        jsp         => [qw( jsp jspx jhtm jhtml )],
        lisp        => [qw( lisp lsp )],
        make        => q{Makefiles},
        mason       => [qw( mas mhtml mpl mtxt )],
        objc        => [qw( m h )],
        objcpp      => [qw( mm h )],
        ocaml       => [qw( ml mli )],
        parrot      => [qw( pir pasm pmc ops pod pg tg )],
        perl        => [qw( pl pm pod t )],
        php         => [qw( php phpt php3 php4 php5 )],
        plone       => [qw( pt cpt metadata cpy py )],
        python      => [qw( py )],
        ruby        => [qw( rb rhtml rjs rxml )],
        scheme      => [qw( scm )],
        shell       => [qw( sh bash csh ksh zsh )],
        skipped     => q{Files, but not directories, normally skipped by ack (default: off)},
        smalltalk   => [qw( st )],
        sql         => [qw( sql ctl )],
        tcl         => [qw( tcl itcl itk )],
        tex         => [qw( tex cls sty )],
        text        => q{Text files, as defined by Perl's -T op (default: off)},
        tt          => [qw( tt tt2 ttml )],
        vb          => [qw( bas cls frm ctl vb resx )],
        vim         => [qw( vim )],
        yaml        => [qw( yaml yml )],
        xml         => [qw( xml dtd xslt ent )],
    );

    while ( my ($type,$exts) = each %mappings ) {
        if ( ref $exts ) {
            for my $ext ( @{$exts} ) {
                push( @{$types{$ext}}, $type );
            }
        }
    }

    $is_cygwin      = ($^O eq 'cygwin');
    $is_windows     = ($^O =~ /MSWin32/);
    $to_screen      = -t *STDOUT;
    $dir_sep_chars  = $is_windows ? quotemeta( '\\/' ) : quotemeta( File::Spec->catfile( '', '' ) );
}

=head1 SYNOPSIS

If you want to know about the F<ack> program, see the F<ack> file itself.

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 read_ackrc

Reads the contents of the .ackrc file and returns the arguments.

=cut

sub read_ackrc {
    my @files = ( $ENV{ACKRC} );
    my @dirs =
        $is_windows
            ? ( $ENV{HOME}, $ENV{USERPROFILE} )
            : ( '~', $ENV{HOME} );
    for my $dir ( grep { defined } @dirs ) {
        for my $file ( '.ackrc', '_ackrc' ) {
            push( @files, bsd_glob( "$dir/$file", GLOB_TILDE ) );
        }
    }
    for my $filename ( @files ) {
        if ( defined $filename && -e $filename ) {
            open( my $fh, '<', $filename ) or App::Ack::die( "$filename: $!\n" );
            my @lines = grep { /./ && !/^\s*#/ } <$fh>;
            chomp @lines;
            close $fh or App::Ack::die( "$filename: $!\n" );

            return @lines;
        }
    }

    return;
}

=head2 get_command_line_options()

Gets command-line arguments and does the Ack-specific tweaking.

=cut

sub get_command_line_options {
    my %opt = (
        pager => $ENV{ACK_PAGER},
    );

    my $getopt_specs = {
        1                       => sub { $opt{1} = $opt{m} = 1 },
        'A|after-context=i'     => \$opt{after_context},
        'B|before-context=i'    => \$opt{before_context},
        'C|context:i'           => sub { shift; my $val = shift; $opt{before_context} = $opt{after_context} = ($val || 2) },
        'a|all-types'           => \$opt{all},
        'break!'                => \$opt{break},
        c                       => \$opt{count},
        'color!'                => \$opt{color},
        count                   => \$opt{count},
        'env!'                  => sub { }, # ignore this option, it is handled beforehand
        f                       => \$opt{f},
        'follow!'               => \$opt{follow},
        'g=s'                   => sub { shift; $opt{G} = shift; $opt{f} = 1 },
        'G=s'                   => \$opt{G},
        'group!'                => sub { shift; $opt{heading} = $opt{break} = shift },
        'heading!'              => \$opt{heading},
        'h|no-filename'         => \$opt{h},
        'H|with-filename'       => \$opt{H},
        'i|ignore-case'         => \$opt{i},
        'lines=s'               => sub { shift; my $val = shift; push @{$opt{lines}}, $val },
        'l|files-with-matches'  => \$opt{l},
        'L|files-without-match' => sub { $opt{l} = $opt{v} = 1 },
        'm|max-count=i'         => \$opt{m},
        'match=s'               => \$opt{regex},
        n                       => \$opt{n},
        o                       => sub { $opt{output} = '$&' },
        'output=s'              => \$opt{output},
        'pager=s'               => \$opt{pager},
        'nopager'               => sub { $opt{pager} = undef },
        'passthru'              => \$opt{passthru},
        'print0'                => \$opt{print0},
        'Q|literal'             => \$opt{Q},
        'sort-files'            => \$opt{sort_files},
        'u|unrestricted'        => \$opt{u},
        'v|invert-match'        => \$opt{v},
        'w|word-regexp'         => \$opt{w},

        'ignore-dirs=s'         => sub { shift; my $dir = remove_dir_sep( shift ); $ignore_dirs{$dir} = '--ignore-dirs' },
        'noignore-dirs=s'       => sub { shift; my $dir = remove_dir_sep( shift ); delete $ignore_dirs{$dir} },

        'version'   => sub { print_version_statement(); exit 1; },
        'help|?:s'  => sub { shift; show_help(@_); exit; },
        'help-types'=> sub { show_help_types(); exit; },
        'man'       => sub { require Pod::Usage; Pod::Usage::pod2usage({-verbose => 2}); exit; },

        'type=s'    => sub {
            # Whatever --type=xxx they specify, set it manually in the hash
            my $dummy = shift;
            my $type = shift;
            my $wanted = ($type =~ s/^no//) ? 0 : 1; # must not be undef later

            if ( exists $type_wanted{ $type } ) {
                $type_wanted{ $type } = $wanted;
            }
            else {
                App::Ack::die( qq{Unknown --type "$type"} );
            }
        }, # type sub
    };

    # Stick any default switches at the beginning, so they can be overridden
    # by the command line switches.
    unshift @ARGV, split( ' ', $ENV{ACK_OPTIONS} ) if defined $ENV{ACK_OPTIONS};

    # first pass through options, looking for type definitions
    def_types_from_ARGV();

    for my $i ( filetypes_supported() ) {
        $getopt_specs->{ "$i!" } = \$type_wanted{ $i };
    }


    my $parser = Getopt::Long::Parser->new();
    $parser->configure( 'bundling', 'no_ignore_case', );
    $parser->getoptions( %{$getopt_specs} ) or
        App::Ack::die( 'See ack --help or ack --man for options.' );

    my %defaults = (
        all            => 0,
        color          => $to_screen && !$is_windows,
        follow         => 0,
        break          => $to_screen,
        heading        => $to_screen,
        before_context => 0,
        after_context  => 0,
    );
    while ( my ($key,$value) = each %defaults ) {
        if ( not defined $opt{$key} ) {
            $opt{$key} = $value;
        }
    }

    if ( defined $opt{m} && $opt{m} <= 0 ) {
        App::Ack::die( '-m must be greater than zero' );
    }

    for ( qw( before_context after_context ) ) {
        if ( defined $opt{$_} && $opt{$_} < 0 ) {
            App::Ack::die( "--$_ may not be negative" );
        }
    }

    if ( defined( my $val = $opt{output} ) ) {
        $opt{output} = eval qq[ sub { "$val" } ];
    }
    if ( defined( my $l = $opt{lines} ) ) {
        # --line=1 --line=5 is equivalent to --line=1,5
        my @lines = split( /,/, join( ',', @{$l} ) );

        # --line=1-3 is equivalent to --line=1,2,3
        @lines = map {
            my @ret;
            if ( /-/ ) {
                my ($from, $to) = split /-/, $_;
                if ( $from > $to ) {
                    App::Ack::warn( "ignoring --line=$from-$to" );
                    @ret = ();
                }
                else {
                    @ret = ( $from .. $to );
                }
            }
            else {
                @ret = ( $_ );
            };
            @ret
        } @lines;

        if ( @lines ) {
            my %uniq;
            @uniq{ @lines } = ();
            $opt{lines} = [ sort { $a <=> $b } keys %uniq ];   # numerical sort and each line occurs only once!
        }
        else {
            # happens if there are only ignored --line directives
            App::Ack::die( 'All --line options are invalid.' );
        }
    }

    return \%opt;
}

=head2 def_types_from_ARGV

Go through the command line arguments and look for
I<--type-set foo=.foo,.bar> and I<--type-add xml=.rdf>.
Remove them from @ARGV and add them to the supported filetypes,
i.e. into %mappings, etc.

=cut

sub def_types_from_ARGV {
    my @typedef;

    my $parser = Getopt::Long::Parser->new();
        # pass_through   => leave unrecognized command line arguments alone
        # no_auto_abbrev => otherwise -c is expanded and not left alone
    $parser->configure( 'no_ignore_case', 'pass_through', 'no_auto_abbrev' );
    $parser->getoptions(
        'type-set=s' => sub { shift; push @typedef, ['c', shift] },
        'type-add=s' => sub { shift; push @typedef, ['a', shift] },
    ) or App::Ack::die( 'See ack --help or ack --man for options.' );

    for my $td (@typedef) {
        my ($type, $ext) = split '=', $td->[1];

        if ( $td->[0] eq 'c' ) {
            # type-set
            if ( exists $mappings{$type} ) {
                # can't redefine types 'make', 'skipped', 'text' and 'binary'
                App::Ack::die( qq{--type-set: Builtin type "$type" cannot be changed.} )
                    if ref $mappings{$type} ne 'ARRAY';

                delete_type($type);
            }
        }
        else {
            # type-add

            # can't append to types 'make', 'skipped', 'text' and 'binary'
            App::Ack::die( qq{--type-add: Builtin type "$type" cannot be changed.} )
                if exists $mappings{$type} && ref $mappings{$type} ne 'ARRAY';

            App::Ack::warn( qq{--type-add: Type "$type" does not exist, creating with "$ext" ...} )
                unless exists $mappings{$type};
        }

        my @exts = map { s/^\.//; $_ } split ',', $ext; # %types stores extensions without leading '.'

        if ( !exists $mappings{$type} || ref($mappings{$type}) eq 'ARRAY' ) {
            push @{$mappings{$type}}, @exts;
            for my $e ( @exts ) {
                push @{$types{$e}}, $type;
            }
        }
        else {
            App::Ack::die( qq{Cannot append to type "$type".} );
        }
    }

    return;
}

=head2 delete_type

Removes a type from the internal structures containing type
information: %mappings, %types and %type_wanted.

=cut

sub delete_type {
    my $type = shift;

    App::Ack::die( qq{Internal error: Cannot delete builtin type "$type".} )
        unless ref $mappings{$type} eq 'ARRAY';

    delete $mappings{$type};
    delete $type_wanted{$type};
    for my $ext ( keys %types ) {
        $types{$ext} = [ grep { $_ ne $type } @{$types{$ext}} ];
    }
}

=head2 ignoredir_filter

Standard filter to pass as a L<File::Next> descend_filter.  It
returns true if the directory is any of the ones we know we want
to ignore.

=cut

sub ignoredir_filter {
    return !exists $ignore_dirs{$_};
}

=head2 remove_dir_sep( $path )

This functions removes a trailing path separator, if there is one, from its argument

=cut

sub remove_dir_sep {
    my $path = shift;
    $path =~ s/[$dir_sep_chars]$//;

    return $path;
}

=head2 filetypes( $filename )

Returns a list of types that I<$filename> could be.  For example, a file
F<foo.pod> could be "perl" or "parrot".

The filetype will be C<undef> if we can't determine it.  This could
be if the file doesn't exist, or it can't be read.

It will be 'skipped' if it's something that ack should avoid searching,
even under -a.

=cut

use constant TEXT => 'text';

sub filetypes {
    my $filename = shift;

    return 'skipped' unless is_searchable( $filename );

    return ('make',TEXT) if $filename =~ m{[$dir_sep_chars]?Makefile$}io;

    # If there's an extension, look it up
    if ( $filename =~ m{\.([^\.$dir_sep_chars]+)$}o ) {
        my $ref = $types{lc $1};
        return (@{$ref},TEXT) if $ref;
    }

    # At this point, we can't tell from just the name.  Now we have to
    # open it and look inside.

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
    close_file( $fh, $filename ) or return;

    if ( $header =~ /^#!/ ) {
        return ($1,TEXT)       if $header =~ /\b(ruby|p(?:erl|hp|ython))\b/;
        return ('shell',TEXT)  if $header =~ /\b(?:ba|c|k|z)?sh\b/;
    }
    else {
        return ('xml',TEXT)    if $header =~ /\Q<?xml /i;
    }

    return (TEXT);
}

=head2 is_searchable( $filename )

Returns true if the filename is one that we can search, and false
if it's one that we should skip like a coredump or a backup file.

Recognized files:
  /~$/            - Unix backup files
  /#.+#$/         - Emacs swap files
  /[._].*\.swp$/  - Vi(m) swap files
  /core\.\d+$/    - core dumps

=cut

sub is_searchable {
    my $filename = shift;

    # If these are updated, update the --help message
    return if $filename =~ /\.bak$/;
    return if $filename =~ /~$/;
    return if $filename =~ m{[$dir_sep_chars]?(?:#.+#|core\.\d+|[._].*\.swp)$}o;

    return 1;
}

=head2 build_regex( $str, \%opts )

Returns a regex object based on a string and command-line options.

=cut

sub build_regex {
    my $str = shift;
    my $opt = shift;

    $str = quotemeta( $str ) if $opt->{Q};
    if ( $opt->{w} ) {
        $str = "\\b$str" if $str =~ /^\w/;
        $str = "$str\\b" if $str =~ /\w$/;
    }

    return $str;
}

=head2 check_regex( $regex_str )

Checks that the $regex_str can be compiled into a perl regular expression.
Dies with the error message if this is not the case.

No return value.

=cut

sub check_regex {
    my $regex = shift;

    return unless defined $regex;

    eval { qr/$regex/ };
    if ($@) {
        (my $error = $@) =~ s/ at \S+ line \d+.*//;
        chomp($error);
        App::Ack::die( "Invalid regex '$regex':\n  $error" );
    }

    return;
}



=head2 warn( @_ )

Put out an ack-specific warning.

=cut

sub warn { ## no critic (ProhibitBuiltinHomonyms)
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}

=head2 die( @_ )

Die in an ack-specific way.

=cut

sub die { ## no critic (ProhibitBuiltinHomonyms)
    return CORE::die( _my_program(), ': ', @_, "\n" );
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

sub _get_thpppt {
    my $y = q{_   /|,\\'!.x',=(www)=,   U   };
    $y =~ tr/,x!w/\nOo_/;
    return $y;
}

sub _thpppt {
    my $y = _get_thpppt();
    App::Ack::print( "$y ack $_[0]!\n" );
    exit 0;
}

sub _key {
    my $str = lc shift;
    $str =~ s/[^a-z]//g;

    return $str;
}

=head2 show_help()

Dumps the help page to the user.

=cut

sub show_help {
    my $help_arg = shift || 0;

    return show_help_types() if $help_arg =~ /^types?/;

    my $ignore_dirs = _listify( sort { _key($a) cmp _key($b) } keys %ignore_dirs );

    App::Ack::print( <<"END_OF_HELP" );
Usage: ack [OPTION]... PATTERN [FILES]

Search for PATTERN in each source file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories are checked.
ack may also search STDIN, but only if no FILES are specified, or if
one of FILES is "-".

Default switches may be specified in ACK_OPTIONS environment variable or
an .ackrc file. If you want no dependency on the environment, turn it
off with --noenv.

Example: ack -i select

Searching:
  -i, --ignore-case     Ignore case distinctions in PATTERN
  -v, --invert-match    Invert match: select non-matching lines
  -w, --word-regexp     Force PATTERN to match only whole words
  -Q, --literal         Quote all metacharacters; PATTERN is literal

Search output:
  --line=NUM            Only print line(s) NUM of each file
  -l, --files-with-matches
                        Only print filenames containing matches
  -L, --files-without-match
                        Only print filenames with no match
  -o                    Show only the part of a line matching PATTERN
                        (turns off text highlighting)
  --passthru            Print all lines, whether matching or not
  --output=expr         Output the evaluation of expr for each line
                        (turns off text highlighting)
  --match PATTERN       Specify PATTERN explicitly.
  -m, --max-count=NUM   Stop searching in each file after NUM matches
  -1                    Stop searching after one match of any kind
  -H, --with-filename   Print the filename for each match
  -h, --no-filename     Suppress the prefixing filename on output
  -c, --count           Show number of lines matching per file

  -A NUM, --after-context=NUM
                        Print NUM lines of trailing context after matching
                        lines.
  -B NUM, --before-context=NUM
                        Print NUM lines of leading context before matching
                        lines.
  -C [NUM], --context[=NUM]
                        Print NUM lines (default 2) of output context.

  --print0              Print null byte as separator between filenames,
                        only works with -f, -g, -l, -L or -c.

File presentation:
  --[no]heading         Print a filename heading above each file's results.
                        (default: on when used interactively)
  --[no]break           Print a break between results from different files.
                        (default: on when used interactively)
  --group               Same as --heading --break
  --nogroup             Same as --noheading --nobreak
  --[no]color           Highlight the matching text (default: on unless
                        output is redirected, or on Windows)

File finding:
  -f                    Only print the files found, without searching.
                        The PATTERN must not be specified.
  -g REGEX              Same as -f, but only print files matching REGEX.
  --sort-files          Sort the found files lexically.

File inclusion/exclusion:
  -a, --all-types       All file types searched;
                        Ignores CVS, .svn and other ignored directories
  -u, --unrestricted    All files and directories searched
  --[no]ignore-dir=name Add/Remove directory from the list of ignored dirs
  -n                    No descending into subdirectories
  -G REGEX              Only search files that match REGEX

  --perl                Include only Perl files.
  --type=perl           Include only Perl files.
  --noperl              Exclude Perl files.
  --type=noperl         Exclude Perl files.
                        See "ack --help type" for supported filetypes.

  --type-add TYPE=.EXTENSION[,.EXT2[,...]]
                        Files with the given EXTENSION(s) are recognized as
                        being of (the existing) type TYPE
  --type-set TYPE=.EXTENSION[,.EXT2[,...]]
                        Files with the given EXTENSION(s) are recognized as
                        being of type TYPE. This replaces an existing
                        definition for type TYPE.

  --[no]follow          Follow symlinks.  Default is off.

  Directories ignored by default:
    $ignore_dirs

  Files not checked for type:
    /~\$/           - Unix backup files
    /#.+#\$/        - Emacs swap files
    /[._].*\\.swp\$/ - Vi(m) swap files
    /core\\.\\d+\$/   - core dumps

Miscellaneous:
  --noenv               Ignore environment variables and ~/.ackrc
  --help                This help
  --man                 Man page
  --version             Display version & copyright
  --thpppt              Bill the Cat
END_OF_HELP

    return;
 }


=head2 show_help_types()

Display the filetypes help subpage.

=cut

sub show_help_types {
    App::Ack::print( <<'END_OF_HELP' );
Usage: ack [OPTION]... PATTERN [FILES]

The following is the list of filetypes supported by ack.  You can
specify a file type with the --type=TYPE format, or the --TYPE
format.  For example, both --type=perl and --perl work.

Note that some extensions may appear in multiple types.  For example,
.pod files are both Perl and Parrot.

END_OF_HELP

    my @types = filetypes_supported();
    my $maxlen = 0;
    for ( @types ) {
        $maxlen = length if $maxlen < length;
    }
    for my $type ( sort @types ) {
        next if $type =~ /^-/; # Stuff to not show
        my $ext_list = $mappings{$type};

        if ( ref $ext_list ) {
            $ext_list = join( ' ', map { ".$_" } @{$ext_list} );
        }
        App::Ack::print( sprintf( "    --[no]%-*.*s %s\n", $maxlen, $maxlen, $type, $ext_list ) );
    }

    return;
}

sub _listify {
    my @whats = @_;

    return '' if !@whats;

    my $end = pop @whats;
    my $str = @whats ? join( ', ', @whats ) . " and $end" : $end;

    no warnings 'once';
    require Text::Wrap;
    $Text::Wrap::columns = 75;
    return Text::Wrap::wrap( '', '    ', $str );
}

=head2 get_version_statement( $copyright )

Returns the version information for ack.

=cut

sub get_version_statement {
    my $copyright = get_copyright();
    return <<"END_OF_VERSION";
ack $VERSION

$copyright

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
END_OF_VERSION
}

=head2 print_version_statement( $copyright )

Prints the version information for ack.

=cut

sub print_version_statement {
    App::Ack::print( get_version_statement() );

    return;
}

=head2 get_copyright

Return the copyright for ack.

=cut

sub get_copyright {
    return $COPYRIGHT;
}

=head2 load_colors

Set default colors, load Term::ANSIColor on non Windows platforms

=cut

sub load_colors {
    if ( not $is_windows ) {
        eval 'use Term::ANSIColor ()';

        $ENV{ACK_COLOR_MATCH}    ||= 'black on_yellow';
        $ENV{ACK_COLOR_FILENAME} ||= 'bold green';
    }

    return;
}

=head2 is_interesting

File type filter, filtering based on the wanted file types

=cut

sub is_interesting {
    return if /^\./;

    my $include;

    for my $type ( filetypes( $File::Next::name ) ) {
        if ( defined $type_wanted{$type} ) {
            if ( $type_wanted{$type} ) {
                $include = 1;
            }
            else {
                return;
            }
        }
    }

    return $include;
}


=head2 open_file( $filename )

Opens the file specified by I<$filename> and returns a filehandle and
a flag that says whether it could be binary.

If there's a failure, it throws a warning and returns an empty list.

=cut

sub open_file {
    my $filename = shift;

    my $fh;
    my $could_be_binary;

    if ( $filename eq '-' ) {
        $fh = *STDIN;
        $could_be_binary = 0;
    }
    else {
        if ( !open( $fh, '<', $filename ) ) {
            App::Ack::warn( "$filename: $!" );
            return;
        }
        $could_be_binary = 1;
    }

    return ($fh,$could_be_binary);
}

=head2 close_file( $fh, $filename )

Close L<$fh> opened from L<$filename>.

=cut

sub close_file {
    if ( close $_[0] ) {
        return 1;
    }
    App::Ack::warn( "$_[1]: $!" );
    return 0;
}


=head2 needs_line_scan( $fh, $regex, \%opts )

Slurp up an entire file up to 100K, see if there are any matches
in it, and if so, let us know so we can iterate over it directly.
If it's bigger than 100K or the match is inverted, we have to do
the line-by-line, too.

=cut

sub needs_line_scan {
    my $fh = shift;
    my $regex = shift;
    my $opt = shift;

    return 1 if $opt->{v};

    my $size = -s $fh;

    if ( $size > 100_000 ) {
        return 1;
    }

    my $buffer;
    my $rc = sysread( $fh, $buffer, $size );
    return 0 unless $rc && ( $rc == $size );

    return
        $opt->{i}
            ? ( $buffer =~ /$regex/im )
            : ( $buffer =~ /$regex/m );
}

# print subs added in order to make it easy for a third party
# module (such as App::Wack) to redefine the display methods
# and show the results in a different way.
sub print                   { print {$fh} @_ }
sub print_first_filename    { App::Ack::print( $_[0], "\n" ) }
sub print_blank_line        { App::Ack::print( "\n" ) }
sub print_separator         { App::Ack::print( "--\n" ) }
sub print_filename          { App::Ack::print( $_[0], $_[1] ) }
sub print_line_no           { App::Ack::print( $_[0], $_[1] ) }
sub print_count {
    my $filename = shift;
    my $nmatches = shift;
    my $ors = shift;
    my $count = shift;

    App::Ack::print( $filename );
    App::Ack::print( ':', $nmatches ) if $count;
    App::Ack::print( $ors );
}

sub print_count0 {
    my $filename = shift;
    my $ors = shift;

    App::Ack::print( $filename, ':0', $ors );
}


=head2 search( $fh, $could_be_binary, $filename, \%opt )

Main search method

=cut

{
    my $filename;
    my $regex;
    my $display_filename;

    my $keep_context;

    my $last_output_line;             # number of the last line that has been output
    my $any_output;                   # has there been any output for the current file yet
    my $context_overall_output_count; # has there been any output at all

sub search {
    my $fh = shift;
    my $could_be_binary = shift;
    $filename = shift;
    my $opt = shift;

    my $v = $opt->{v};
    my $passthru = $opt->{passthru};
    my $max = $opt->{m};
    my $nmatches = 0;

    $display_filename = undef;

    # for --line processing
    my $has_lines = 0;
    my @lines;
    if ( defined $opt->{lines} ) {
        $has_lines = 1;
        @lines = ( @{$opt->{lines}}, -1 );
        undef $regex; # Don't match when printing matching line
    }
    else {
        $regex = $opt->{i} ? qr/$opt->{regex}/i : qr/$opt->{regex}/;
    }


    # for context processing
    $last_output_line = -1;
    $any_output = 0;
    my $before_context = $opt->{before_context};
    my $after_context  = $opt->{after_context};

    $keep_context = ($before_context || $after_context) && !$passthru;

    my @before;
    my $before_starts_at_line;
    my $after = 0; # number of lines still to print after a match

    my $line;
    while ($line = <$fh>) {
        # XXX Optimize away the case when there are no more @lines to find.
        if ( $has_lines
               ? $. != $lines[0]  # $lines[0] should be a scalar
               : $v ? $line =~ m/$regex/ : $line !~ m/$regex/ ) {
            if ( $passthru ) {
                App::Ack::print( $line );
                next;
            }

            if ( $keep_context ) {
                if ( $after ) {
                    print_match_or_context( $opt, 0, $., $line );
                    $after--;
                }
                elsif ( $before_context ) {
                    if ( @before ) {
                        if ( @before >= $before_context ) {
                            shift @before;
                            ++$before_starts_at_line;
                        }
                    }
                    else {
                        $before_starts_at_line = $.;
                    }
                    push @before, $line;
                }
                last if $max && ( $nmatches >= $max ) && !$after;
            }
            next;
        } # not a match

        ++$nmatches;

        # print an empty line as a divider before first line in each file (not before the first file)
        if ( !$any_output && $opt->{show_filename} && $opt->{break} && defined( $context_overall_output_count ) ) {
            App::Ack::print_blank_line();
        }

        shift @lines if $has_lines;

        if ( $could_be_binary ) {
            if ( -B $filename ) {
                App::Ack::print( "Binary file $filename matches\n" );
                last;
            }
            $could_be_binary = 0;
        }
        if ( $keep_context ) {
            if ( @before ) {
                print_match_or_context( $opt, 0, $before_starts_at_line, @before );
                @before = ();
                $before_starts_at_line = 0;
            }
            if ( $max && $nmatches > $max ) {
                --$after;
            }
            else {
                $after = $after_context;
            }
        }
        print_match_or_context( $opt, 1, $., $line );

        last if $max && ( $nmatches >= $max ) && !$after;
    } # while

    return $nmatches;
}   # search()


=head2 print_match_or_context( $opt, $is_match, $starting_line_no, @lines )

Prints out a matching line or a line of context around a match.

=cut

sub print_match_or_context {
    my $opt      = shift; # opts array
    my $is_match = shift; # is there a match on the line?
    my $line_no  = shift;

    my $color = $opt->{color};
    my $heading = $opt->{heading};
    my $show_filename = $opt->{show_filename};

    if ( $show_filename ) {
        if ( not defined $display_filename ) {
            $display_filename =
                $color
                    ? Term::ANSIColor::colored( $filename, $ENV{ACK_COLOR_FILENAME} )
                    : $filename;
            if ( $heading && !$any_output ) {
                App::Ack::print_first_filename($display_filename);
            }
        }
    }

    my $sep = $is_match ? ':' : '-';
    my $output_func = $opt->{output};
    for ( @_ ) {
        if ( $keep_context && !$output_func ) {
            if ( ( $last_output_line != $line_no - 1 ) &&
                ( $any_output || ( !$heading && defined( $context_overall_output_count ) ) ) ) {
                App::Ack::print_separator();
            }
            # to ensure separators between different files when --noheading

            $last_output_line = $line_no;
        }

        if ( $show_filename ) {
            App::Ack::print_filename($display_filename, $sep) if not $heading;
            App::Ack::print_line_no($line_no, $sep);
        }

        if ( $output_func ) {
            while ( /$regex/go ) {
                App::Ack::print( $output_func->() . "\n" );
            }
        }
        else {
            if ( $color && $is_match && $regex &&
                 s/$regex/Term::ANSIColor::colored( substr($_, $-[0], $+[0] - $-[0]), $ENV{ACK_COLOR_MATCH} )/eg ) {
                # At the end of the line reset the color and remove newline
                s/[\r\n]*\z/\e[0m\e[K/;
            }
            else {
                # remove any kind of newline at the end of the line
                s/[\r\n]*\z//;
            }
            App::Ack::print($_ . "\n");
        }
        $any_output = 1;
        ++$context_overall_output_count;
        ++$line_no;
    }

    return;
} # print_match_or_context()

} # scope around search() and print_match_or_context()


=head2 search_and_list( $fh, $filename, \%opt )

Optimized version of searching for -l and --count, which do not
show lines.

=cut

sub search_and_list {
    my $fh = shift;
    my $filename = shift;
    my $opt = shift;

    my $nmatches = 0;
    my $count = $opt->{count};
    my $ors = $opt->{print0} ? "\0" : "\n"; # output record separator

    my $regex = $opt->{i} ? qr/$opt->{regex}/i : qr/$opt->{regex}/;

    if ( $opt->{v} ) {
        while (<$fh>) {
            if ( /$regex/ ) {
                return 0 unless $count;
            }
            else {
                ++$nmatches;
            }
        }
    }
    else {
        while (<$fh>) {
            if ( /$regex/ ) {
                ++$nmatches;
                last unless $count;
            }
        }
    }

    if ( $nmatches ) {
        App::Ack::print_count($filename, $nmatches, $ors, $count);
    }
    elsif ( $count && !$opt->{l} ) {
        App::Ack::print_count0($filename, $ors);
    }

    return $nmatches ? 1 : 0;
}   # search_and_list()


=head2 filetypes_supported_set

True/False - are the filetypes set?

=cut

sub filetypes_supported_set {
    return grep { defined $type_wanted{$_} && ($type_wanted{$_} == 1) } filetypes_supported();
}


=head2 print_files( $iter, $one [, $regex, [, $ors ]] )

Prints all the files returned by the iterator matching I<$regex>.

If I<$one> is set, stop after the first.
The output record separator I<$ors> defaults to C<"\n"> and defines, what to
print after each filename.

=cut

sub print_files {
    my $iter = shift;
    my $opt = shift;

    my $ors = $opt->{print0} ? "\0" : "\n";

    while ( defined ( my $file = $iter->() ) ) {
        App::Ack::print $file, $ors;
        last if $opt->{1};
    }

    return;
}

=head2 print_files_with_matches( $iter, $opt )

Prints the name of the files where a match was found.

=cut

sub print_files_with_matches {
    my $iter = shift;
    my $opt = shift;

    my $nmatches = 0;
    while ( defined ( my $filename = $iter->() ) ) {
        my ($fh) = open_file( $filename );
        next unless defined $fh; # error while opening file
        $nmatches += search_and_list( $fh, $filename, $opt );
        close_file( $fh, $filename );
        last if $nmatches && $opt->{1};
    }

    return;
}

=head2 print_matches( $iter, $opt )

Print matching lines.

=cut

sub print_matches {
    my $iter = shift;
    my $opt = shift;

    $opt->{show_filename} = 0 if $opt->{h};
    $opt->{show_filename} = 1 if $opt->{H};

    my $nmatches = 0;
    while ( defined ( my $filename = $iter->() ) ) {
        my ($fh,$could_be_binary) = open_file( $filename );
        next unless defined $fh; # error while opening file
        my $needs_line_scan;
        if ( $opt->{regex} && !$opt->{passthru} ) {
            $needs_line_scan = needs_line_scan( $fh, $opt->{regex}, $opt );
            if ( $needs_line_scan ) {
                seek( $fh, 0, 0 );
            }
        }
        else {
            $needs_line_scan = 1;
        }
        if ( $needs_line_scan ) {
            $nmatches += search( $fh, $could_be_binary, $filename, $opt );
        }
        close_file( $fh, $filename );
        last if $nmatches && $opt->{1};
    }
    return;
}

=head2 filetype_setup()

Minor housekeeping before we go matching files.

=cut

sub filetype_setup {
    my $filetypes_supported_set = filetypes_supported_set();
    # If anyone says --no-whatever, we assume all other types must be on.
    if ( !$filetypes_supported_set ) {
        for my $i ( keys %type_wanted ) {
            $type_wanted{$i} = 1 unless ( defined( $type_wanted{$i} ) || $i eq 'binary' || $i eq 'text' || $i eq 'skipped' );
        }
    }
    return;
}

=head2 expand_filenames( \@ARGV )

Returns reference to list of expanded filename globs (Win32 only).

=cut

EXPAND_FILENAMES_SCOPE: {
    my $filter;

    sub expand_filenames {
        my $argv = shift;

        my $attr;
        my @files;

        foreach my $pattern ( @{$argv} ) {
            my @results = bsd_glob( $pattern );

            if (@results == 0) {
                @results = $pattern; # Glob didn't match, pass it thru unchanged
            }
            elsif ( (@results > 1) or ($results[0] ne $pattern) ) {
                if (not defined $filter) {
                    eval 'require Win32::File;';
                    if ($@) {
                        $filter = 0;
                    }
                    else {
                        $filter = Win32::File::HIDDEN()|Win32::File::SYSTEM();
                    }
                } # end unless we've tried to load Win32::File
                if ( $filter ) {
                    # Filter out hidden and system files:
                    @results = grep { not(Win32::File::GetAttributes($_, $attr) and $attr & $filter) } @results;
                    App::Ack::warn( "$pattern: Matched only hidden files" ) unless @results;
                } # end if we can filter by file attributes
            } # end elsif this pattern got expanded

            push @files, @results;
        } # end foreach pattern

        return \@files;
    } # end expand_filenames
} # EXPAND_FILENAMES_SCOPE


=head2 get_starting_points( \@ARGV, \%opt )

Returns reference to list of starting directories and files.

=cut

sub get_starting_points {
    my $argv = shift;
    my $opt = shift;

    my @what;

    if ( @{$argv} ) {
        @what = @{ $is_windows ? expand_filenames($argv) : $argv };
        $_ = File::Next::reslash( $_ ) for @what;

        # Show filenames unless we've specified one single file
        $opt->{show_filename} = (@what > 1) || (!-f $what[0]);
    }
    else {
        @what = '.'; # Assume current directory
        $opt->{show_filename} = 1;
    }

    for my $start_point (@what) {
        App::Ack::warn( "$start_point: No such file or directory" ) unless -e $start_point;
    }
    return \@what;
}


=head2 get_iterator

Return the File::Next file iterator

=cut

sub get_iterator {
    my $what = shift;
    my $opt = shift;

    # Starting points are always search, no matter what
    my $is_starting_point = sub { return grep { $_ eq $_[0] } @{$what} };

    my $file_filter
        = $opt->{u}   && defined $opt->{G} ? sub { $File::Next::name =~ /$opt->{G}/o }
        : $opt->{all} && defined $opt->{G} ? sub { $is_starting_point->( $File::Next::name ) || ( $File::Next::name =~ /$opt->{G}/o && is_searchable( $File::Next::name ) ) }
        : $opt->{u}                        ? sub {1}
        : $opt->{all}                      ? sub { $is_starting_point->( $File::Next::name ) || is_searchable( $File::Next::name ) }
        : defined $opt->{G}                ? sub { $is_starting_point->( $File::Next::name ) || ( $File::Next::name =~ /$opt->{G}/o && is_interesting( @_ ) ) }
        :                                    sub { $is_starting_point->( $File::Next::name ) || is_interesting( @_ ) }
        ;
    my $iter =
        File::Next::files( {
            file_filter     => $file_filter,
            descend_filter  => $opt->{n}
                                    ? sub {0}
                                    : $opt->{u}
                                        ? sub {1}
                                        : \&ignoredir_filter,
            error_handler   => sub { my $msg = shift; App::Ack::warn( $msg ) },
            sort_files      => $opt->{sort_files},
            follow_symlinks => $opt->{follow},
        }, @{$what} );
    return $iter;
}

=head2 set_up_pager( $command )

=cut

sub set_up_pager {
    my $command = shift;

    my $pager;
    if ( not open( $pager, '|-', $command ) ) {
        App::Ack::die( qq{Unable to pipe to pager "$command": $!} );
    }
    $fh = $pager;
}

=head1 COPYRIGHT & LICENSE

Copyright 2005-2008 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Ack
