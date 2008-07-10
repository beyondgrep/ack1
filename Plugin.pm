package App::Ack::Plugin;

=head1 NAME

App::Ack::Plugin - Basic plugin documentation for ack

=head1 SYNOPSIS

This module defines and demonstrates how ack plugins work.

=head1 PLUGIN USES

This is designed as a framework to let the plugins do all the work.  Here are some ideas.

=over 4

=item .zip, .tar, .jar

Walk through individual files in the container

=item .gz, .Z

Expand the file content

=item .xls

Iterate through sheets within the workbook.

=item .doc

Search through text of the Word document.

=item .mp3

Search the ID3 tags.

=item Whatever you want

Maybe you have file that defines a connection to a database and you
have ack walk through rows of a table.

=back

=head1 TERMS

In normal, text-mode ack, looks like this:

    foo.pl:18:Blah blah blah

In this case, "foo.pl" is the "resource", "18" is the "ID", and
"Blah blah blah" is the "line".

=head1 FUNCTIONS

Each App::Ack::Plugin module must include the following functions,
with the specified functionality.

This is how, roughly, the app will call the plugin:

    my $plugin = App::Ack::Plugin::Example->new( $filename );

    while ( my $resource = $plugin->next_resource() ) {
        # Handle start of the resource
        while ( my ($line,$id) = $plugin->next_line() ) {
            # Search for stuff in $line
        }
        $resource->close_resource();
    }
    $plugin->shutdown();

=head2 new( $filename )

Standard constructor.  What you do inside, ack doesn't care.

=cut

=head2 next_resource()

Returns the next resource in the file.  Returns undef if there is none.

For files like MP3 files, there will only be one resource in the
file.  For an Excel workbook, it will likely return one resource
per worksheet.

=cut

=head2 next_line()

Returns an array of the next line and its ID.  Returns an empty
list at the end of the resource.

=cut

=head2 close_resource()

If there's some shutdown to be done on the resource, perhaps closing an opened database table, this is where to do it.

=cut

=head2 shutdown()

If you have to shutdown the file, such as closing a database connection,here's where to do it.

=cut

1; # End of App::Ack::Plugin
