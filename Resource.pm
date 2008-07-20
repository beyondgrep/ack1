package App::Ack::Resource;

use warnings;
use strict;

=head1 METHODS

=head2 new( $filename )

Opens the file specified by I<$filename> and returns a filehandle and
a flag that says whether it could be binary.

If there's a failure, it throws a warning and returns an empty list.

=cut

sub new {
    my $class    = shift;
    my $filename = shift;

    my $self = bless {
        filename        => $filename,
        fh              => undef,
        could_be_binary => undef,
        opened          => undef,
        id              => undef,
    }, $class;

    if ( $self->{filename} eq '-' ) {
        $self->{fh} = *STDIN;
        $self->{could_be_binary} = 0;
    }
    else {
        if ( !open( $self->{fh}, '<', $self->{filename} ) ) {
            App::Ack::warn( "$self->{filename}: $!" );
            return;
        }
        $self->{could_be_binary} = 1;
    }

    return $self;
}

=head2 $res->name()

Returns the name of the resource.

=cut

sub name {
    my $self = shift;

    return $self->{filename};
}

=head2 $res->is_binary()

Tells whether the resource is binary.

=cut

sub is_binary() {
    my $self = shift;

    if ( $self->{could_be_binary} ) {
        return -B $self->{fh};
    }

    return 0;
}


=head2 $res->needs_line_scan( $regex, \%opts )

Slurp up an entire file up to 100K, see if there are any matches
in it, and if so, let us know so we can iterate over it directly.
If it's bigger than 100K or the match is inverted, we have to do
the line-by-line, too.

=cut

sub needs_line_scan {
    my $self  = shift;
    my $regex = shift;
    my $opt   = shift;

    return 1 if $opt->{v};

    my $size = -s $self->{fh};

    if ( $size > 100_000 ) {
        return 1;
    }

    my $buffer;
    my $rc = sysread( $self->{fh}, $buffer, $size );
    return 0 unless $rc && ( $rc == $size );

    return $buffer =~ /$regex/m;
}

=head2 $res->next_text()

Returns an array of the next text and its ID.  Returns an empty
list at the end of the resource.

=cut

sub next_text {
    my $self = shift;

    # XXX Can/should I read directly into $.?
    my $text = readline $self->{fh};
    if ( defined $text ) {
        $_ = $text;
        $. = ++$self->{line};
        return 1;
    }

    return;
}

=head2 $res->close()

Close the resource.  In this case, it's just a text file.

=cut

sub close {
    my $self = shift;

    if ( not close $self->{fh} ) {
        App::Ack::warn( $self->name() . ": $!" );
    }

    return;
}

1;
