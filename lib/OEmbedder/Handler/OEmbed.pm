package OEmbedder::Handler::OEmbed;
use strict;
use warnings;
use parent 'Tatsumaki::Handler';
use Module::Pluggable search_path => ['OEmbedder::Handler::OEmbed'], require => 1;
__PACKAGE__->asynchronous(1);

sub json {
    my ($self, $obj) = @_;

    $self->response->content_type('application/json');
    my $json = $self->application->service('json')->json->encode($obj);
    if (my $jsonp = $self->request->param('callback')) { 
        $json = "$jsonp($json);";
    }
    return $json;
}

sub get {
    my $self = shift;
    my $url = $self->request->param('url');

    for my $site ($self->plugins) {
        if ($url =~ $site->regex) {
            my @args = grep {$_} ($1, $2, $3, $4);
            my $meth = $site->can('get');
            return $self->$meth(@args);
        }
    }
    Tatsumaki::Error::HTTP->throw(404);
    $self->finish;
}

1;
