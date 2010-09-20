package OEmbedder::Handler::OEmbed::Nicovideo;
use strict;
use warnings;

sub regex {qr{^http://www.nicovideo.jp/watch/(.+)$}}

sub get {
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

1;
