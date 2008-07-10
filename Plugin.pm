package App::Ack::Plugin;

=head1 NAME

App::Ack::Plugin - Basic plugin documentation for ack

=head1 SYNOPSIS

This module depines and demonstrates how ack plugins work.

=head1 FUNCTIONS

Each App::Ack::Plugin module must include the following functions,
with the specified functionality.

=head2 new( $filename )

=cut

=head2 next_resource()

=cut

=head2 first_line( $filename )

=cut

=head2 next_line()

=cut

=head2 shutdown()

=cut

sub important_function_in_plugin() {
    print "blah";
}

1; # End of App::Ack::Plugin
