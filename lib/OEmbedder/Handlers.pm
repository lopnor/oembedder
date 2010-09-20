package OEmbedder::Handlers;
use strict;
use warnings;
use utf8;

sub all {
    [
        '^/oembed$' => 'OEmbedder::Handler::OEmbed',
        '^/$' => 'OEmbedder::Handler::Root',
    ]
}

package OEmbedder::Handler;
use parent 'Tatsumaki::Handler';

package OEmbedder::Handler::Root;
use parent -norequire => 'OEmbedder::Handler';

sub get {
    my $self = shift;
    $self->write('This is yet another oembed provider. Enjoy!');
}

package OEmbedder::Handler::OEmbed;
use parent -norequire => 'OEmbedder::Handler';
__PACKAGE__->asynchronous(1);
use URI;
use Tatsumaki::HTTPClient;
use Web::Scraper;

sub json {
    my ($self, $obj) = @_;

    $self->response->content_type('application/json');
    my $json = $self->application->service('json')->json->encode($obj);
    if (my $jsonp = $self->request->param('callback')) { 
        $json = "$jsonp($json);";
    }
    return $json;
}

my $rule = { 
    nicovideo => qr{^http://www.nicovideo.jp/watch/(.+)$},
    pixiv => qr{^http://www.pixiv.net/member_illust.php},
};

sub get {
    my $self = shift;
    my $url = $self->request->param('url');

    for my $meth (keys %$rule) {
        if ($url =~ $rule->{$meth}) {
            my @args = grep {$_} ($1, $2, $3, $4);
            return $self->$meth(@args);
        }
    }
    Tatsumaki::Error::HTTP->throw(404);
    $self->finish;
}

sub nicovideo {
    my ($self, $id) = @_;

    my $src = URI->new("http://ext.nicovideo.jp/thumb_watch/$id");
    my $div_id = join('_', 'nicovideo', $id, time);
    my $func = "write_$div_id";
    $src->query_form(
        cb => $func,
    );
    my $html = <<END;
<div id="$div_id"></div>
<script type="text/javascript">
function $func(player) { player.write("$div_id"); }
</script>
<script type="text/javascript" src="$src"></script>
END
    my $json = $self->json(
        {
            version => '1.0',
            type => 'video',
            provider_name => 'Nico Nico Douga (9)',
            provider_url => 'http://www.nicovideo.jp/',
            title => '',
            html => $html,
        },
    );
    $self->write($json);
    $self->finish;
}

sub pixiv {
    my ($self) = @_;
    my $uri = URI->new($self->request->param('url'));
    my $id = { $uri->query_form }->{illust_id};
    my $client = Tatsumaki::HTTPClient->new;
    $client->get(
        "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=$id",
        $self->async_cb(sub {
                my $res = shift;
                my $result = scraper {
                    process '//div[@class="indexBoxLeft"]/img',
                        img => '@src',
                        title => '@alt';
                    process '//span[@class="f10"]',
                        meta => 'TEXT';
                }->scrape($res->decoded_content);
                my ($w_m, $h_m, $m);
                if (my ($w, $h) = ($result->{meta} =~ m{(\d+)×(\d+)})) {
                    ($m = $result->{img}) =~ s/_s.jpg$/_m.jpg/;
                    ($w_m, $h_m) = $w > $h ? 
                    (600, int(600 * $h/$w)) : (int(600 * $w/$h), 600);
                } elsif (my ($pages) = ($result->{meta} =~ m{漫画 (\d+)P})) {
                    my $page = do {
                        if (my $f = $uri->fragment) {
                            my ($page) = ($f =~ m{page(\d+)$});
                            $page || 0;
                        } else { 0 }
                    };
                    ($m = $result->{img}) =~ s/_s.jpg$/_p$page.jpg/;
                    warn $m;
                }
                my $json = $self->json(
                    {
                        version => '1.0',
                        type => 'photo',
                        provider_name => 'pixiv',
                        provider_url => 'http://www.pixiv.net/',
                        url => $m,
                        title => $result->{title},
                        width => $w_m,
                        height => $h_m,
                    }
                );
                $self->write($json);
                $self->finish;
            }
        )
    );
}

1;
