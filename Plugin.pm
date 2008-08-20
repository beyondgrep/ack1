package App::Ack::Plugin;

=head1 OVERVIEW

The premise is that each file is a repository of zero or more
resources.  Each resource contains zero or more lines of text, which
ack will process.

For the basic text file that ack handles now, it's simple: Each
text file is a repository that has one resource.  The repository
and resource are the same.

You can look at Repository.pm and Resource.pm and see how I'm calling
it.  It's really simple, and there's a lot of overhead.

Maybe now's the time for me to work on Plugin.pod. :-)

=head1 STRUCTURE

Say you have code that will let you search through DLL files.

=head2 App/Ack/Plugin/DLL.pm

    package App::Ack::Plugin::DLL;


    package App::Ack::Resource::DLL;

    our @ISA = qw( App::Ack::Resource );


    package App::Ack::Repository::DLL;

    our @ISA = qw( App::Ack::Repository );

=cut


1;
