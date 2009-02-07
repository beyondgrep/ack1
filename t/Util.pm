
use File::Next ();
use App::Ack ();

sub prep_environment {
    delete @ENV{qw( ACK_OPTIONS ACKRC ACK_PAGER )};
}

# capture stderr output into this file
my $catcherr_file = 'stderr.log';

sub is_win32 {
    return $^O =~ /Win32/;
}

# capture-stderr is executing ack and storing the stderr output in
# $catcherr_file in a portable way.
#
# The quoting of command line arguments depends on the OS
sub build_command_line {
    my @args = @_;

    if ( is_win32() ) {
        for ( @args ) {
            s/(\\+)$/$1$1/;     # Double all trailing backslashes
            s/"/\\"/g;          # Backslash all quotes
            $_ = qq("$_");
        }
    }
    else {
        @args = map { quotemeta $_ } @args;
    }

    return "$^X -T ./capture-stderr $catcherr_file ./ack @args";
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
	
    my ($stdout, $stderr) = run_ack_with_stderr( @args );

    if ( $TODO ) {
        fail( q{Automatically fail stderr check for TODO tests.} );
    }
    else {
        is( scalar @{$stderr}, 0, 'Should have no output to stderr' )
            or diag( join( "\n", "STDERR:", @{$stderr} ) );
    }

    return @{$stdout};
}

{ # scope for $AckReturnCode;

# capture returncode
our $AckReturnCode;

sub run_ack_with_stderr {
    my @args = @_;

    my @stdout;
    my @stderr;

    if ( !grep { $_ =~ /^--(no)?env$/ } @args ) {
        unshift( @args, '--noenv' );
    }

    my $cmd = build_command_line( @args );
	
    @stdout = `$cmd`;
    my ($sig,$core,$rc)=( ($? & 127),  ($? & 128) , ($? >> 8) );
    $AckReturnCode=$rc;
	## XXX what do do with $core or $sig?

    open( CATCHERR, '<', $catcherr_file );
    while( <CATCHERR> ) {
        push( @stderr, $_ );
    }
    close CATCHERR;
    unlink $catcherr_file;

    chomp @stdout;
    chomp @stderr;
    return ( \@stdout, \@stderr );
}

sub get_rc{
  return $AckReturnCode;
}

} # scope for $AckReturnCode

sub pipe_into_ack {
    my $input = shift;
    my @args = @_;

    my $cmd = build_command_line( @args );
    $cmd = "$^X -pe1 $input | $cmd";
    my @results = `$cmd`;
    chomp @results;

    unlink $catcherr_file;

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

sub ack_lists_match {
    my $args     = shift;
    my $expected = shift;
    my $message  = shift;
    my @args     = @{$args};

    my @results = run_ack( @args );
    my $ok = lists_match( \@results, $expected, $message );
    $ok or diag( join( ' ', '$ ack', @args ) );

    return $ok;
}

# Use this one if you don't care about order of the lines
sub sets_match {
    my @actual = @{+shift};
    my @expected = @{+shift};
    my $msg = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic
    return lists_match( [sort @actual], [sort @expected], $msg );
}

sub ack_sets_match {
    my $args     = shift;
    my $expected = shift;
    my $message  = shift;
    my @args     = @{$args};

    my @results = run_ack( @args );
    my $ok = sets_match( \@results, $expected, $message );
    $ok or diag( join( ' ', '$ ack', @args ) );

    return $ok;
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
