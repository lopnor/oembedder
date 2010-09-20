package OEmbedder::JSON;
use Any::Moose;
extends 'Tatsumaki::Service';
use JSON::Any;

has json => ( is => 'rw', isa => 'JSON::Any', lazy_build => 1);
sub _build_json {JSON::Any->new(utf8 => 1)}

sub start { shift->json }

1;
