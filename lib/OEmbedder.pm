package OEmbedder;

use strict;
use warnings;
our $VERSION = '0.01';
use Tatsumaki::Application;
use OEmbedder::JSON;
use OEmbedder::Handler::OEmbed;
use OEmbedder::Handler::Root;

sub webapp {
    my ($class, $config) = @_;
    $config ||= {};

    my $app = Tatsumaki::Application->new(
        [
            '^/oembed$' => 'OEmbedder::Handler::OEmbed',
            '^/$' => 'OEmbedder::Handler::Root',
        ]
    );
    $app->add_service(json => OEmbedder::JSON->new);
    $app->psgi_app;
}

1;
__END__

=head1 NAME

OEmbedder -

=head1 SYNOPSIS

  use OEmbedder;

=head1 DESCRIPTION

OEmbedder is

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
