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

A repository is a container of resources.  XXX Explain & expand.

In normal, text-mode ack, looks like this:

    foo.pl:18:Blah blah blah

In this case, "foo.pl" is the "resource", "18" is the "ID", and
"Blah blah blah" is the "text".

For an MP3 file, you might have "take-it-off.mp3" as the resource,
"Title" as the ID, and "Take It Off" as the text.

On a PDF, resource could be "requirements.pdf", ID could be "page
24, line 34", and the line of text as the text.

=head1 FUNCTIONS

Each App::Ack::Plugin module must include the following functions,
with the specified functionality.

This is how, roughly, the app will call the plugin:

    my $repo = App::Ack::Repository->new( $filename );

    while ( my $res = $repo->next_resource() ) {
        # Handle start of the resource
        while ( my ($line,$id) = $res->next_text() ) {
            # Search for stuff in $line
        }
        $resource->close();
    }
    $repository->close();

=head1 REQUIRED FUNCTIONS

=head2 Repository functions

=over 4

=item * new( $filename )

Returns the next resource in the file.  Returns undef if there is none.

It is the caller's responsibility to call ->close() on the resource.

For files like MP3 files, there will only be one resource in the
file.  For an Excel workbook, it will likely return one resource
per worksheet.

=item * next_resource()

=item * close()

Closes the repository if necessary.  This might be closing a database connection.

=back

=head2 Resource functions

=over 4

=item * new()

Opens the resource.  The constructor can take whatever arguments
are necessary to open it.  Since the repository opens the resource,
not ack itself, you're free to pass whatever you like.

=item * name()

Returns the name of the resource, in whatever way the resource sees
fit to describe itself.  Usually, this will just be a file name,
but could also be a filename + sheet name in the case of an Excel
workbook.

=item * next_text()

Returns an array of the next text and its ID.  Returns an empty
list at the end of the resource.

For scanning through a file, the ID is probably just a line number.
It might also be a field name, or a database table row ID.

If there is no ID, because there is only one text item in the
resource, such as the description field on a GIF, then return
I<undef> for an ID.

=item * close()

Closes the resource if necessary.  This might be freeing memory
from scanning a SQL table, but not closing the database connection,
which would be at the repository level.

=back

=cut

1; # End of App::Ack::Plugin
