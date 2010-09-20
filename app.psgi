use strict;
use warnings;
use lib 'lib';
use Plack::Builder;
use OEmbedder;

my $app = OEmbedder->webapp;

builder {
    enable 'Static', path => qr{^/eg};
    $app;
};
