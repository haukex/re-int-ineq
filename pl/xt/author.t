#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Author tests for the Perl module L<Regexp::IntInequality>.

=head1 Author, Copyright, and License

Copyright (c) 2024 Hauke Daempfling (haukex@zero-g.net).

This file is part of the "Regular Expression Integer Inequalities" library.

This library is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License
along with this program. If not, see L<https://www.gnu.org/licenses/>

=cut

use FindBin ();
use File::Spec::Functions qw/ updir catfile abs2rel catdir /;
use File::Glob 'bsd_glob';

our ($BASEDIR,@PERLFILES);
BEGIN {
	$BASEDIR = catdir($FindBin::Bin,updir);
	@PERLFILES = (
		catfile($BASEDIR,qw/ lib Regexp IntInequality.pm /),
		bsd_glob("$BASEDIR/{t,xt}/*.{t,pm,pl}"),
	);
}
my @TASKFILES = (
	bsd_glob("$BASEDIR/{t,xt}/*.{json}"),
	map {catfile($BASEDIR,$_)} 'Changes', 'Makefile.PL', 'README.md'
);

use Test::More tests => 3*@PERLFILES + 2;
note explain \@PERLFILES;

use File::Temp qw/tempfile/;
my $critfn;
BEGIN {
	my $fh; ($fh,$critfn) = tempfile UNLINK=>1;
	print $fh <<'END_CRITIC';
severity = 3
verbose = 9
[ErrorHandling::RequireCarping]
severity = 4
[RegularExpressions::RequireExtendedFormatting]
severity = 2
[Variables::ProhibitReusedNames]
severity = 4
[Modules::ProhibitExcessMainComplexity]
severity = 2
END_CRITIC
	close $fh;
}
use Test::Perl::Critic -profile=>$critfn;
use Test::MinimumVersion;
use Test::Pod;
use Test::DistManifest;
use Pod::Simple::SimpleTree;
use Capture::Tiny qw/capture_merged/;

subtest 'MANIFEST' => sub { manifest_ok() };

for my $file (@PERLFILES) {
	pod_file_ok($file);
	critic_ok($file);
	minimum_version_ok($file, $file=~m{/xt/allver-test-docker\.pl$}
		? '5.036' : '5.008');
}

subtest 'synopsis code' => sub { plan tests=>2;
	my $verbatim = getverbatim($PERLFILES[0], qr/\b(?:synopsis)\b/i);
	is @$verbatim, 1, 'verbatim block count' or diag explain $verbatim;
	is capture_merged {
		my $code = <<"END_CODE"; eval "{$code\n;1}" or die $@; ## no critic (ProhibitStringyEval, RequireCarping)
			use warnings; use strict;
			$$verbatim[0]
			;  # in case the last line ends without semicolon but with comment
			#is \$foo, 'foo', 'synopsis foo';
END_CODE
	}, "Match: 74\nMatch: 47\n-123 matches\n42 matches\n47 doesn't match\n",
		'output of synopsis correct';
};

my @tasks;
for my $file (@PERLFILES, @TASKFILES) {
	open my $fh, '<', $file or die "$file: $!";  ## no critic (RequireCarping)
	while (<$fh>) {
		s/\A\s+|\s+\z//g;
		push @tasks, [abs2rel($file,$BASEDIR), $., $_] if /TO.?DO/i;
	}
	close $fh;
}
diag "To-","Do Report: ", 0+@tasks, " To-","Dos found";
diag "### TO","DOs ###" if @tasks;
diag "$$_[0]:$$_[1]: $$_[2]" for @tasks;
diag "### ###" if @tasks;
diag "To run coverage tests:\nperl Makefile.PL && make authorcover "
	. "&& firefox cover_db/coverage.html\n"
	. "rm -rf cover_db && make distclean && git clean -dxn";

sub getverbatim {
	my ($file,$regex) = @_;
	my $tree = Pod::Simple::SimpleTree->new->parse_file($file)->root;
	my ($curhead,@v);
	for my $e (@$tree) {
		next unless ref $e eq 'ARRAY';
		if (defined $curhead) {
			if ($e->[0]=~/^\Q$curhead\E/) { $curhead = undef }
			elsif ($e->[0] eq 'Verbatim') { push @v, $e->[2] }
		}
		elsif ($e->[0]=~/^head\d\b/ && $e->[2]=~$regex)
			{ $curhead = $e->[0] }
	}
	return \@v;
}
