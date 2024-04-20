#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Regexp::IntInequality>.

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

use Test::More tests => 13;
use FindBin ();
use File::Spec::Functions qw/ catfile /;
use JSON::PP;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)

diag "This is Perl $] at $^X on $^O";
BEGIN { use_ok 'Regexp::IntInequality', 're_int_ineq' }
is $Regexp::IntInequality::VERSION, '0.98', 'version matches tests';

# space_after: https://github.com/makamaka/JSON-PP/issues/89
my $json = JSON::PP->new->utf8->space_after;
my $TESTCASES_FILE = catfile($FindBin::Bin,'testcases.json');
open my $fh, '<:raw:encoding(UTF-8)', $TESTCASES_FILE
    or die "$TESTCASES_FILE: $!";  ## no critic (RequireCarping)
my $TESTCASES = $json->decode(do { local $/=undef; <$fh> });
close $fh;

my %_op_matrix = (
    #        n-x n n+x
    '>'  => [ 0, 0, 1 ],
    '>=' => [ 0, 1, 1 ],
    '<'  => [ 1, 0, 0 ],
    '<=' => [ 1, 1, 0 ],
    '!=' => [ 1, 0, 1 ],
    '==' => [ 0, 1, 0 ],
);
subtest 'test manual testcases' => sub {
    # This test case makes sure the manual_tests compile and match as expected
    # (without actually testing re_int_ineq)
    my @TESTS = grep {ref} @{ $TESTCASES->{manual_tests} };
    for my $t (@TESTS) {
        my ($op, $n, $ai) = @$t[0, 1, 2];
        my $re = qr/\A$$t[5]\z/;
        for my $o (10,2,1) {
            next if !$ai && $n-$o<0;
            if ($_op_matrix{$op}[0])
                {    like $n-$o, $re, "$n-$o $op $n =~ $re" }
            else { unlike $n-$o, $re, "$n-$o $op $n !~ $re" }
        }
        if ($_op_matrix{$op}[1])
            {    like $n, $re, "$n $op $n =~ $re" }
        else { unlike $n, $re, "$n $op $n !~ $re" }
        for my $o (1,2,10) {
            if ($_op_matrix{$op}[2])
                {    like $n+$o, $re, "$n+$o $op $n =~ $re" }
            else { unlike $n+$o, $re, "$n+$o $op $n !~ $re" }
        }
    }
} or BAIL_OUT("failed to validate manual testcases");

subtest 'manual tests' => sub {
    my @TESTS = grep {ref} @{ $TESTCASES->{manual_tests} };
    plan tests => 0+@TESTS;
    for my $t (@TESTS)
        { is re_int_ineq(@$t[0..4]), $$t[5], $json->encode($t) }
} or BAIL_OUT("manual tests failed");

subtest 'extraction' => sub {
    my @TESTS = grep {ref} @{ $TESTCASES->{extraction} };
    plan tests => 0+@TESTS;
    for my $t (@TESTS) {
        my $re = re_int_ineq(@$t[0..4]);
        my @got = $$t[5]=~/$re/g;
        is_deeply \@got, [ @$t[6..$#$t] ], $json->encode($t)
            or diag explain [$t, $re, \@got];
    }
} or BAIL_OUT("extraction tests failed");

subtest 'aroundzero' => sub {
    my @TESTS = @{ $TESTCASES->{aroundzero} };
    plan tests => 3*@TESTS;  # assumes array is symmetric
    for my $t (@TESTS) {
        my ($op,$n,$mz) = @$t;
        if ( $n!~/^-/ ) {
            my $rn = re_int_ineq($op, $n);
            if ($mz) { like '0', qr/\A$rn\z/, "N $op$n: $rn should match 0" }
            else { unlike '0', qr/\A$rn\z/, "N $op$n: $rn shouldn't match 0" }
            unlike '-0', qr/\A$rn\z/, "N $op$n: $rn shouldn't match -0";
        }
        my $rz = re_int_ineq($op, $n, 1);
        if ($mz) {
            like    '0', qr/\A$rz\z/, "Z $op$n: $rz should match 0";
            like   '-0', qr/\A$rz\z/, "Z $op$n: $rz should match -0";
        } else {
            unlike  '0', qr/\A$rz\z/, "Z $op$n: $rz shouldn't match 0";
            unlike '-0', qr/\A$rz\z/, "Z $op$n: $rz shouldn't match -0";
        }
    }
} or BAIL_OUT("aroundzero tests failed");

subtest 'error cases' => sub {
    my @TESTS = grep {ref} @{ $TESTCASES->{errorcases} };
    plan tests => 0+@TESTS;
    for my $t (@TESTS)
        { ok exception { re_int_ineq(@$t) }, "error on args (@$t)" }
};

subtest 'named arguments' => sub {  ## no critic (RequireTestLabels)
    is re_int_ineq({op=>'<', n=>123}), re_int_ineq('<', 123);
    is re_int_ineq({op=>'<', n=>123}), re_int_ineq('<', 123, 0, 1, 0);
    is re_int_ineq({op=>'<=', n=>44, allint=>1}),
        re_int_ineq('<=', 44, 1);
    is re_int_ineq({op=>'<=', n=>44, anchor=>0}),
        re_int_ineq('<=', 44, 0, 0);
    is re_int_ineq({op=>'<=', n=>44, zeroes=>1}),
        re_int_ineq('<=', 44, 0, 1, 1);
    is re_int_ineq({op=>'<=', n=>44, anchor=>undef}),
        re_int_ineq('<=', 44, 0, 0, 0);
    is re_int_ineq({op=>'<=', n=>44, anchor=>undef}),
        re_int_ineq('<=', 44, undef, undef);
    is re_int_ineq({op=>'<=', n=>44, allint=>undef, anchor=>undef,
        zeroes=>undef}), re_int_ineq('<=', 44, 0, 0, 0);
    is re_int_ineq({op=>'<=', n=>44, allint=>0, anchor=>1, zeroes=>0}),
        re_int_ineq('<=', 44, 0, 1, 0);
    is re_int_ineq({op=>'<=', n=>44, allint=>1, anchor=>0, zeroes=>1}),
        re_int_ineq('<=', 44, 1, 0, 1);
    ok exception { re_int_ineq({}) };
    ok exception { re_int_ineq({op=>'>='}) };
    ok exception { re_int_ineq({n=>5}) };
    ok exception { re_int_ineq({op=>'>=', n=>5}, 6) };
    ok exception { re_int_ineq({op=>'>=', n=>5, zeros=>1}) };
};

subtest 'zeroes never match' => sub {
    my @TESTS = @{ $TESTCASES->{zeroes} };
    my @NM_NONNEG = map {(               "0$_","00$_")} @TESTS;
    my @NM_ALLINT = map {("-00$_","-0$_","0$_","00$_")} @TESTS;
    plan tests => 5*3*6*@TESTS**2;
    run_rangetests(0, 0, \@NM_NONNEG, \@TESTS);
    run_rangetests(1, 0, \@NM_ALLINT, [ map {($_,"-$_")} @TESTS ] );
};

diag "The final three test cases can take a few seconds...";

subtest 'zeroes' => sub {
    my @TESTS = @{ $TESTCASES->{zeroes} };
    my @NONNEG = map {(                     $_,"0$_","00$_")} @TESTS;
    my @ALLINT = map {("-00$_","-0$_","-$_",$_,"0$_","00$_")} @TESTS;
    plan tests => 2 + 6*@NONNEG**2 + 6*@ALLINT**2;
    is run_rangetests(0, 1, [], \@NONNEG), 0, 'seen_negzero as expected';
    is run_rangetests(1, 1, [], \@ALLINT), 3*(@ALLINT+1), 'seen_negzero as expected';
};

subtest 'non-negative integers (N)' => sub {
    my @TESTS = map {( $$_[0] .. ($$_[1]-1) )}
        @{ $TESTCASES->{nonneg_testranges} };
    plan tests => 1 + 6*@TESTS**2;
    is run_rangetests(0, 0, [], \@TESTS), 0, 'seen_negzero as expected';
};

subtest 'all integers (Z)' => sub {
    my @TESTS = map {($_,"-$_")} map {( $$_[0] .. ($$_[1]-1) )}
        @{ $TESTCASES->{allint_testranges} };
    plan tests => 1 + 6*@TESTS**2;
    is run_rangetests(1, 0, [], \@TESTS), 1+@TESTS, 'seen_negzero as expected';
};

sub run_rangetests {
    my ($ai, $ze, $nm, $tc) = @_;
    my $nz = $ai ? 'Z' : 'N';
    # double-check that Perl's string/number conversion didn't clobber "-0":
    my $seen_negzero = 0;
    for my $n (@$tc) {
        my ($lt, $le, $gt, $ge, $ne, $eq) =
            map {re_int_ineq($_,$n,$ai,1,$ze)} '<','<=','>','>=','!=','==';
        my ($rlt, $rle, $rgt, $rge, $rne, $req) =
            map {qr/\A$_\z/} $lt, $le, $gt, $ge, $ne, $eq;
        note "$nz n=$n lt=$lt le=$le gt=$gt ge=$ge";
        for my $i (@$tc) {
            if ( $i< $n ) { like $i, $rlt, "$nz $i is    <  $n and =~ $lt" }
            else        { unlike $i, $rlt, "$nz $i isn't <  $n and !~ $lt" }
            if ( $i<=$n ) { like $i, $rle, "$nz $i is    <= $n and =~ $le" }
            else        { unlike $i, $rle, "$nz $i isn't <= $n and !~ $le" }
            if ( $i> $n ) { like $i, $rgt, "$nz $i is    >  $n and =~ $gt" }
            else        { unlike $i, $rgt, "$nz $i isn't >  $n and !~ $gt" }
            if ( $i>=$n ) { like $i, $rge, "$nz $i is    >= $n and =~ $ge" }
            else        { unlike $i, $rge, "$nz $i isn't >= $n and !~ $ge" }
            if ( $i!=$n ) { like $i, $rne, "$nz $i is    != $n and =~ $ne" }
            else        { unlike $i, $rne, "$nz $i isn't != $n and !~ $ne" }
            if ( $i==$n ) { like $i, $req, "$nz $i is    == $n and =~ $eq" }
            else        { unlike $i, $req, "$nz $i isn't == $n and !~ $eq" }
            $seen_negzero++ if $i=~/\A-0+\z/;
        }
        for my $i (@$nm) {
            for my $re ($rlt, $rle, $rgt, $rge, $rne, $req)
                { unlike $i, $re, "$i never matches $re" } }
        $seen_negzero++ if $n=~/\A-0+\z/;
    }
    return $seen_negzero;
}

# This is a special test case needed for the Perl implementation.
subtest 'anchor argument' => sub { plan tests=>5;
    is re_int_ineq('<=', 0),       '(?<![0-9])0(?![0-9])', 'anchor implicit on 1';
    is re_int_ineq('<=', 0, 0),    '(?<![0-9])0(?![0-9])', 'anchor implicit on 2';
    is re_int_ineq('<=', 0, 0, 1), '(?<![0-9])0(?![0-9])', 'anchor explicit on';
    is re_int_ineq('<=', 0, 0, 0), '0',                    'anchor explicit off 1';
    is re_int_ineq('<=', 0, 0, undef), '0',                'anchor explicit off 2';
};

done_testing;
