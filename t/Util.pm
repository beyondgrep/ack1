
use File::Next ();
use App::Ack ();
use IPC::Open3 qw( open3 );
use Symbol qw(gensym);
use IO::File ();

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

    my ($stdout,$stderr) = run_ack_with_stderr( @args );
    is( scalar @{$stderr}, 0, 'Should have no output to stderr' );

    return @{$stdout};
}

sub run_ack_with_stderr {
    my @args = @_;

    my @stdout;
    my @stderr;

    my $cmd = "$^X -T ./ack-standalone @args";
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

    my $cmd = "$^X -pe1 $input | $^X -T ./ack-standalone @args";
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
