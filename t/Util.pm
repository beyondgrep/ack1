
use File::Next ();
use App::Ack ();
use IPC::Open3 qw( open3 );
use Symbol qw(gensym);
use IO::File ();

sub is_win32 {
    return $^O =~ /Win32/;
}

sub build_command_line {
    return "$^X -T ./ack-standalone @_";
}

sub slurp {
    my $iter = shift;

    my @files;
    while ( defined ( my $file = $iter->() ) ) {
        push( @files, $file );
    }

    return @files;
}

sub run_ack {
    my @args = @_;

    my @results;

    if ( $^O =~ /Win32/ ) {
        my $cmd = build_command_line( @args );
        @results = `$cmd`;
        pass( q{We can't check that there was no output to stderr on Win32, so it's a freebie.} );
    }
    else {
        my ($stdout,$stderr) = run_ack_with_stderr( @args );

        is( scalar @{$stderr}, 0, 'Should have no output to stderr' )
            or diag( join( "\n", "STDERR:", @{$stderr} ) );
        @results = @{$stdout};
    }

    chomp @results;

    return @results;
}

sub run_ack_with_stderr {
    my @args = @_;

    die 'You cannot use run_ack_with_stderr on Win32' if is_win32;

    my @stdout;
    my @stderr;

    my $cmd = build_command_line( @args );
    local *CATCHERR = IO::File->new_tmpfile;
    my $pid = open3( gensym, \*CATCHOUT, '>&CATCHERR', $cmd );
    while( <CATCHOUT> ) {
        push( @stdout, $_ );
    }
    waitpid($pid, 0);
    seek CATCHERR, 0, 0;
    while( <CATCHERR> ) {
        push( @stderr, $_ );
    }

    chomp @stdout;
    chomp @stderr;
    return ( \@stdout, \@stderr );
}

sub pipe_into_ack {
    my $input = shift;
    my @args = @_;

    my $cmd = build_command_line( @args );
    $cmd = "$^X -pe1 $input | $cmd";
    my @results = `$cmd`;
    chomp @results;

    return @results;
}

# Use this one if order is important
sub lists_match {
    my @actual = @{+shift};
    my @expected = @{+shift};
    my $msg = shift;

    # Normalize all the paths
    for my $path ( @expected, @actual ) {
        $path = File::Next::reslash( $path ); ## no critic (Variables::ProhibitPackageVars)
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic

    eval 'use Test::Differences';
    if ( !$@ ) {
        return eq_or_diff( [@actual], [@expected], $msg );
    }
    else {
        return is_deeply( [@actual], [@expected], $msg );
    }
}

# Use this one if you don't care about order of the lines
sub sets_match {
    my @actual = @{+shift};
    my @expected = @{+shift};
    my $msg = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic
    return lists_match( [sort @actual], [sort @expected], $msg );
}

sub is_filetype {
    my $filename = shift;
    my $wanted_type = shift;

    for my $maybe_type ( App::Ack::filetypes( $filename ) ) {
        return 1 if $maybe_type eq $wanted_type;
    }

    return;
}


1;
