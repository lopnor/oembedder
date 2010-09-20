package OEmbedder::Handler::OEmbed::Pixiv;
use strict;
use warnings;
use utf8;
use URI;
use Tatsumaki::HTTPClient;
use Web::Scraper;

sub regex {qr{^http://www.pixiv.net/member_illust.php}}

sub get {
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
