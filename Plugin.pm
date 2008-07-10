package App::Ack::Plugin;

=head1 NAME

App::Ack::Plugin - Basic plugin documentation for ack

=head1 SYNOPSIS

This module defines and demonstrates how ack plugins work.

=head1 PLUGIN USES

This is designed as a framework to let the plugins do all the work.  Here are some ideas.

=over 4

=item .xls

Iterate through sheets within the workbook.

=item .doc

Search through text of the Word document.

=back

=head1 TERMS

A resource is...

A line is...

=head1 FUNCTIONS

Each App::Ack::Plugin module must include the following functions,
with the specified functionality.

This is how, roughly, the 

    my $plugin = App::Ack::Plugin::Example->new( $filename );

    while ( my $resource = $plugin->next_resource() ) {
        # Handle start of the resource
        while ( my $line = $plugin->next_line() ) {
            # Search for stuff in $line
        }
        $resource->close_resource();
    }
    $plugin->shutdown();

=head2 new( $filename )

=cut

=head2 next_resource()

=cut

=head2 next_line()

=cut

=head2 shutdown()

=cut

sub important_function_in_plugin() {
    print "blah";
}

1; # End of App::Ack::Plugin
