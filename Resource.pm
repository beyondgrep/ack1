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

=head2 name()

Returns the name of the resource.

=cut

sub name {
    my $self = shift;

    return $self->{filename};
}

=head2 next_text()

Returns an array of the next text and its ID.  Returns an empty
list at the end of the resource.

=cut

sub next_text {
    my $self = shift;

    my $text = readline $self->{fh};
    if ( defined $text ) {
        return ($text, ++$self->{line});
    }

    return;
}

=head2 close()

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
