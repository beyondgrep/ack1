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

Does nothing.  For the base repository, the opening & closing are
handled at the resource level.

If this repository were, say, an Excel workbook, you'd probably
close the file.  If it were a database, you'd close the database
connection.

=cut

sub close {
}

1;
