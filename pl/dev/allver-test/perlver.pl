#!/usr/bin/env perl
use warnings;
use strict;

sub perlver {
    # https://hub.docker.com/_/perl
    map { "5.$_" }
        "8.9-buster", "10.1-buster",
        map({($_*2)."-buster"} 6..14 ),
        map({"$_-bullseye"} 30,32,34 ),
        map({"$_-bookworm"} 36,38 )
}

unless (caller) {  # when run from command line
    require CPAN::Meta::YAML;  # really simple YAML module, core since v5.14
    print CPAN::Meta::YAML::Dump([perlver])
}
