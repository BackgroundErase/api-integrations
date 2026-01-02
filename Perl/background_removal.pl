#!/usr/bin/env perl
use strict;
use warnings;

# (Optional) help Perl find modules installed in ~/perl5 even if the shell isn't configured yet
use lib "$ENV{HOME}/perl5/lib/perl5";

use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use File::Basename;
use LWP::MediaTypes qw(guess_media_type);

my $API_KEY = $ENV{BG_ERASE_API_KEY} // 'YOUR_API_KEY';

sub background_removal {
    my ($src, $dst) = @_;
    die "Usage: perl $0 input.jpg output.png\n" unless $src && $dst;
    die "Set BG_ERASE_API_KEY env var or edit the script.\n" if $API_KEY eq 'YOUR_API_KEY';

    my $fname = basename($src);
    my $ctype = guess_media_type($fname) || 'application/octet-stream';

    my $ua = LWP::UserAgent->new( agent => 'BackgroundEraseClient/1.0', timeout => 60 );

    my $req = POST(
        'https://api.backgrounderase.net/v2',
        Content_Type => 'form-data',
        Content      => [
            image_file => [ $src, $fname, 'Content-Type' => $ctype ],
        ],
    );
    # Add the custom header explicitly
    $req->header('x-api-key' => $API_KEY);

    my $res = $ua->request($req);
    if ($res->is_success) {
        open my $fh, '>', $dst or die "Can't open $dst: $!";
        binmode $fh;
        print {$fh} $res->content;   # write bytes
        close $fh;
        print "✅ Saved: $dst\n";
    } else {
        my $body = eval { $res->decoded_content } // $res->content;
        print "❌ ", $res->status_line, "\n$body\n";
        exit 1;
    }
}

background_removal(@ARGV);
