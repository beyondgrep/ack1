package App::Ack::Repository;

use App::Ack::Resource;

use warnings;
use strict;

sub new {
    my $class    = shift;
    my $filename = shift;

    my $self = bless {
        filename => $filename,
        nexted   => 0,
    }, $class;

    return $self;
}

=head2 next_resource

Returns a resource object for the next resource in the repository.

=cut

sub next_resource {
    my $self = shift;

    return if $self->{nexted};
    $self->{nexted} = 1;

    return App::Ack::Resource->new( $self->{filename} );
}

=head2 close

Does nothing, because file opening and closing is handled on the
resource level.

=cut

sub close {
}

1;
