package OEmbedder::Handler::Root;
use strict;
use warnings;
use parent 'Tatsumaki::Handler';

sub get {
    my $self = shift;
    $self->write('This is yet another oembed provider. Enjoy!');
}

1;
