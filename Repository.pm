package App::Ack::Repository;

use App::Ack::Resource;

use warnings;
use strict;

sub FAIL {
    require Carp;
    Carp::confess( 'Must be overloaded' );
}

=head1 METHODS

=head2 CLASS->new( $filename )

Creates an instance of the repository.

=cut

sub new {
    FAIL();
}

=head2 next_resource

Returns a resource object for the next resource in the repository.

=cut

sub next_resource {
    FAIL();
}

=head2 close

Closes the repository.

If this repository were, say, an Excel workbook, you'd probably
close the file.  If it were a database, you'd close the database
connection.

=cut

sub close {
    FAIL();
}

1;
