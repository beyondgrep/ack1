package App::Ack::Plugin::Tar;

package App::Ack::Repository::Tar;

use Archive::Tar;

sub extensions_handled {
    return qw( .tar .gz .tgz .tar.gz );
}

sub new {
    my $class = shift;
    my $filename = shift;

    my $self = bless {
        filename => $filename,
    }, $class;

    my $tar = Archive::Tar->new( $filename );
    if ( !$tar ) {
        return;
    }

    $self->{tar} = $tar;
    $self->{files} = [$tar->get_files];

    return $self;
}

sub next_resource {
    my $self = shift;

    my $file = shift @{$self->{files}};

    return unless $file;

    my $tar = $self->{tar};
    my $res = App::Ack::Resource::Tar->new( $self->{filename}, $file->name, $file->get_content );

    return $res;
}

sub close {
}


package App::Ack::Resource::Tar;

sub new {
    my $class    = shift;
    my $tarname  = shift;
    my $filename = shift;
    my $content  = shift;

    my $self = bless {
        tarname  => $tarname,
        filename => $filename,
        lines    => [split( /\n/, $content )],
        lineno   => 0,
    }, $class;

    return $self;
}

sub is_binary {
    return;
}

sub name {
    my $self = shift;

    return $self->{filename};
}

sub needs_line_scan {
    1; # XXX Do actual looking
}

sub reset {
}

sub next_text {
    my $self = shift;

    $_ = shift @{$self->{lines}};
    if ( defined $_ ) {
        $. = $self->{lineno}++;
        return 1;
    }

    return 0;
}

sub close {
}

1;
