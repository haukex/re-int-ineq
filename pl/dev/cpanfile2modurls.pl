#!/usr/bin/env perl
use warnings;
use 5.014;
use IO::Socket::SSL 1.56;
use Net::SSLeay 1.49;
use HTTP::Tiny;
use JSON::PP;
use Module::CPANfile;

die "Usage: $0 [cpanfile]" if @ARGV>1;
my $cpanfile = @ARGV ? $ARGV[0] : 'cpanfile';

my $cpf = Module::CPANfile->load($cpanfile);
my @phases = $cpf->prereqs->phases;
die "unexpected phases @phases" unless @phases==1 && $phases[0] eq 'runtime';
my @types = $cpf->prereqs->types_in('runtime');
die "unexpected types @types" unless @types==1 && $types[0] eq 'requires';
my $reqs = $cpf->prereqs->requirements_for('runtime','requires');

my $http = HTTP::Tiny->new;
for my $mod (sort $reqs->required_modules) {
    my $modreq = $reqs->requirements_for_module($mod);
    warn "Warning: $mod: Ignoring requirements: $modreq\n" if $modreq;
    my $r = $http->get("https://fastapi.metacpan.org/v1/download_url/$mod");
    die "$r->{url} $r->{status} $r->{reason}" unless $r->{success};
    my $d = JSON::PP->new->utf8->decode($r->{content});
    say $d->{download_url};
}
