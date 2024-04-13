#!perl
package Regexp::IntInequality;
use warnings;
use strict;
use Exporter 'import';
use Carp;

our $VERSION = '0.90';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our @EXPORT_OK = qw/ re_int_ineq /;

=head1 Name

Regexp::IntInequality - generate regular expressions to match integers
                        greater than / less than / etc. a value

=head1 Synopsis

 use Regexp::IntInequality 're_int_ineq';
 
 # regex to match non-negative integers > 42 (ignores minus signs!):
 my $gt = re_int_ineq('>', 42);
 my $str = "Do you know why 23, 74, and 47 are special? And what about 42?";
 while ( $str =~ /($gt)/g ) {
     print "Match: $1\n";  # prints "Match: 74" and "Match: 47"
 }
 
 # regex to match any integer <= 42:
 # (the "map" is a trick to get a qr// regex in one line)
 my ($le) = map {qr/^$_$/} re_int_ineq('<=', 42, 1);
 for my $i (-123, 42, 47) {  # the first two match, third doesn't
     print $i=~$le ? "$i matches\n" : "$i doesn't match\n";
 }

=head1 Description

This module provides a single function, C<re_int_ineq>, which generates
regular expressions that match integers that fulfill a specified inequality
(greater than, less than, and so on). By default, only non-negative integers
are matched (minus signs are ignored), and optionally all integers can be
matched, including negative. Integers with leading zeros are never matched.

B<Note:> Normally, this is not a task for regular expressions, instead it is
often preferable to use regular expressions or other methods to extract the
numbers from a string and then use normal numeric comparison operators.
However, there are cases where this module can be useful, for example when
embedding these regular expressions as part of a larger expression or grammar,
or when dealing with an API that only accepts regular expressions.

The generated regular expressions are valid in Perl, Python, and JavaScript
ES2018 or later, and probably in other languages that support
L<lookaround assertions|perlre/"Lookaround Assertions"> with the same syntax.
L<See also|/See Also>.

=head2 C<re_int_ineq I<$op>, I<$n>, I<$allint>, I<$anchor>, I<$zeroes>>

Generates a regex that matches integers according to the following parameters.
It is returned as a string rather than a precompiled regex so it can more
easily be embedded in larger expressions.

Note the regular expressions will grow significantly the more digits are in
the integer. I suggest not to generate regular expressions from unbounded
user input.

=head3 C<$op>

The operator the regex should implement, one of C<< ">" >>, C<< ">=" >>,
C<< "<" >>, C<< "<=" >>, C<"!=">, or C<"=="> (the latter is provided simply
for completeness, despite the name of this module.)

=head3 C<$n>

The integer against which the regex should compare. It may not have leading
zeroes and may only be negative when L<C<$allint>|/$allint> is a true value.

=head3 C<$allint>

If C<$allint> is B<missing or a false value>, then the generated regex will
only cover positive integers and zero, and C<$n> may not be negative.
B<Note> that in this case, any minus signs before integers are not
included in the regex. This means that when using the regex, for example, to
extract integers greater than 10 from the string C<"3 5 15 -7 -12">, it will
match C<"15"> B<and> C<"12">!

If C<$allint> is B<a true value>, then the generated regex will cover all
integers, including negative, and C<$n> may also be any integer. Note
that all generated regexes that match zero will also match C<"-0"> and vice
versa.

=head3 C<$anchor> and Anchoring

B<Note:> This option defaults to being on I<only> when the function is called
with less than four arguments, otherwise the option is turned on by any true
value and turned off by any false value, I<including> C<undef>.

When this option is on (see explanation above), the regex will have zero-width
assertions (a.k.a. anchors) surrounding the expression in order to prevent
matches inside of integers. For example, when extracting integers less than 20
from the string C<"1199 32 5">, the generated regex will by default I<not>
extract the C<"11"> or C<"19"> from C<"1199">, and will only match C<"5">. On
the other hand, any non-digit characters (including minus signs) are
considered delimiters: extracting all integers less than 5 from the string
C<"2x3-3-24y25"> with L<C<$allint>|/$allint> turned on will result in C<"2">,
C<"3">, C<"-3">, and C<"-24">.

This behavior is useful if you are extracting numbers from a longer string.
If you want to validate that a string contains I<only> an integer, then you
will need to add additional anchors. For example, assuming you've stored the
output of C<re_int_ineq> in C<$re>, then you could say C<$str =~ /\A$re\z/> to
validate that C<$str> contains only that integer.
However, this task is more commonly done by first checking that C<$str> is a
valid integer in general, such as via the expressions provided by
L<Regexp::Common|Regexp::Common>, and then using normal numeric comparisons to
check that it is in the range you expect.

If on the other hand you want to turn off the default anchors described above,
perhaps because you want to implement your own, then you can pass a false
value for the C<$anchor> option. Repeating the above example, extracting
integers less than 20 from the string C<"1199 32 5"> with this option on and
no additional anchors results in C<"11">, C<"9">, C<"9">, C<"3">, C<"2">,
and C<"5"> - so use this feature with caution and testing!

=head3 C<$zeroes>

TODO: Update documentation for "zeroes" (zeros).

=begin comment

 1. <   2  -inf <--------------0- 1
 2. <=  2  -inf <--------------0---- 2
 3. =>  2                      0     2 ------> +inf
 4.  >  2                      0        3 ---> +inf
              --+--+--+--+--+--0--+--+--+--+--+--
               -5 -4 -3 -2 -1  0  1  2  3  4  5
 5. <  -2  -inf <--- -3        0
 6. <= -2  -inf <------ -2     0
 7. => -2               -2 ----0-------------> +inf
 8.  > -2                  -1 -0-------------> +inf

1. positive ints up to the value, plus all negative ints

2. gets converted to (1)

3. gets converted to (4)

4. positive ints starting at the value

5. gets reflected, handled like (4), and reflected back

6. gets converted to (5)

7. gets converted to (8)

8. gets reflected, handled like (1), and reflected back

=end comment

=cut

# Regex character ranges for single digits
# ($_RNG_GT[0] is "all digits > 0" and so on; @_RNG_LT1 doesn't include 0)
my @_RNG_GT  = ( map({"[$_-9]"} 1..7), '[89]', '9', '(?!)' );
my @_RNG_LT0 = ( '(?!)', '0', '[01]', map({"[0-$_]"} 2..8) );
my @_RNG_LT1 = ( '(?!)', '(?!)', '1', '[12]', map({"[1-$_]"} 3..8) );

sub re_int_ineq {  ## no critic (ProhibitExcessComplexity)
    # operator, integer, "all integers" (negative), anchors, zeroes
    my ($op, $n, $ai, $anchor, $zeroes) = @_;

    # Handle arguments
    $anchor=1 if @_<4;
    croak "invalid arguments to re_int_ineq"
        if !defined $op || !defined $n || @_>5;
    my $VALID = $ai
        ? ( $zeroes ? qr/-?[0-9]+/ : qr/-?(?:0|[1-9][0-9]*)/ )
        : ( $zeroes ?   qr/[0-9]+/ :   qr/(?:0|[1-9][0-9]*)/ );
    croak "invalid int" unless $n =~ /\A$VALID\z/;
    $n =~ s/\A(-?)0+([0-9]+)\z/$1$2/ if $zeroes;
    my $pfx = !$anchor ? '' : $ai ? '(?<![-0-9])' : '(?<![0-9])';
    my $sfx = $anchor ? '(?![0-9])' : '';

    # Handle easier operators first
    if ($op eq '==') {
        if ($n==0) {
            return '(?:'.$pfx.( $zeroes ? '0+|-0+' : '0|-0' ).')'.$sfx
                if $anchor && $ai;
            return $pfx.( $ai ? '-?' : '' ).( $zeroes ? '0+' : '0' ).$sfx;
        }
        my $ns = $n;
        $ns =~ s/\A(-?)/${1}0*/ if $zeroes;
        return $n=~/\A-/ ? $ns.$sfx : $pfx.$ns.$sfx;
    }
    elsif ($op eq '!=') {
        my $zp = $zeroes ? '0*' : '';
        (my $ns = $n) =~ s/\A(-?)/${1}0*/;
        if (!$anchor) {
            my $aip = $ai ? '-?' : '';
            return "$aip${zp}[1-9][0-9]*" if $n==0;
            return "(?!$ns)${aip}[0-9]+" if $zeroes;
            return "(?!$zp$n)$aip(?:0|[1-9][0-9]*)";
        }
        if ($ai) {
            return "(?:$pfx${zp}[1-9]|-${zp}[1-9])[0-9]*$sfx" if $n==0;
            return "(?!$ns$sfx)(?:${pfx}[0-9]+|-[0-9]+)$sfx" if $zeroes;
            return "(?!$n$sfx)(?:$pfx(?:0|[1-9][0-9]*)|-0|-[1-9][0-9]*)$sfx";
        }
        return "$pfx${zp}[1-9][0-9]*$sfx" if $n==0;
        return "(?!$ns$sfx)${pfx}[0-9]+$sfx" if $zeroes;
        return "(?!$n$sfx)$pfx(?:0|[1-9][0-9]*)$sfx";
    }

    my $mkre = sub {
        my %se = map {$_=>1} @_;
        confess "assertion failed: no re" unless %se;  # uncoverable branch true

        # A bit of optimization
        delete $se{'0'}
            if $se{'[1-9]?[0-9]'} || grep {/\A\[0-?\d\]\z/} keys %se;
        delete $se{'-0'}
            if $se{'-[1-9]?[0-9]'} || grep {/\A-\[0-?\d\]\z/} keys %se;

        # Separate positive and negative terms
        my (@pos, @neg);
        for (keys %se) { if (/\A-/) { push @neg,$_ } else { push @pos,$_ } }
        #@pos = sort { length($a)<=>length($b) or $a cmp $b } @pos;
        #@neg = sort { length($a)<=>length($b) or $a cmp $b } @neg;
        # simple sorting seems to work well enough:
        @pos = sort @pos;
        @neg = sort @neg;

        my @all;
        # Handle positive values - need prefix
        if ($zeroes) {
            if ( @pos==1 && $pos[0] eq '0' )  ## no critic (ProhibitCascadingIfElse)
                { push @all, $pfx.'0+' }  # "<1"/"<=0"  TODO: can this be covered in the special cases below?
            elsif ( @pos==1 && $pos[0] eq '[0-9]+' )
                { push @all, $pfx.'[0-9]+' }
            elsif ( !$anchor && @neg && @pos<3 )
                { push @all, map {"0*$_"} @pos }
            elsif (@pos)
                { push @all, $pfx.'0*'.( @pos>1 ? '(?:'.join('|', @pos).')'
                    : $pos[0] ) }
        }
        elsif (!$anchor) { push @all, @pos }
        elsif (@pos) { push @all, $pfx.( @pos>1 ? '(?:'.join('|',@pos).')'
            : $pos[0] ) }

        # Handle negative values
        if ($zeroes) {
            if ( @neg==1 && $neg[0] eq '-0' )  # ">-1"/">=0"  TODO: can this be covered in the special cases below?
                { push @all, '-0+' }
            elsif ( @pos && @neg<3 || !@pos && @neg<2 )
                { push @all, map { $_ eq '-[0-9]+' ? $_ : '-0*'.substr($_,1) } @neg }
            else
                { push @all, '-0*(?:'.join('|', map {substr $_,1} @neg ).')' }
        }
        # The @neg>5 case is just for a small length reduction:
        # 4: "-a|-b|-c|-d"=11       "-(?:a|b|c|d)"=12     +1
        # 5: "-a|-b|-c|-d|-e"=14    "-(?:a|b|c|d|e)"=14    0
        # 6: "-a|-b|-c|-d|-e|-f"=17 "-(?:a|b|c|d|e|f)"=16 -1
        elsif ( @neg<2 || @pos && @neg<6 ) { push @all, @neg }
        else { push @all, '-(?:'.join('|', map {substr $_,1} @neg ).')' }

        # Done
        confess "assertion failed: no re" unless @all;  # uncoverable branch true
        return +( @all>1 ? '(?:'.join('|',@all).')' : $all[0] ).$sfx;
    };

    # Inspect operator and adjust $n accordingly
    my $gt_not_lt;  # Note: may be modified by $reflect below!
    if ($op eq '>' || $op eq '>=') {
        $n-- if $op eq '>=';  # turn >= into >
        $gt_not_lt = 1;
    }
    elsif ($op eq '<' || $op eq '<=') {
        $n++ if $op eq '<=';  # turn <= into <
        $gt_not_lt = 0;
    }
    else { croak "unknown operator" }

    # Handle some special cases the code below doesn't handle
    if ( $n==-1 && $gt_not_lt ) {  # ">-1"/">=0"
        if ($zeroes) {
            return $mkre->('-0','[0-9]+') if $ai;
            return $mkre->(     '[0-9]+') }
        if ($ai) {
            return '(?:[1-9][0-9]*|-?0)' if !$anchor;
            return $mkre->('-0','0','[1-9][0-9]*') }
        return     $mkre->(     '0','[1-9][0-9]*');
    }
    if ( $n==1 && !$gt_not_lt ) {  # "<1"/"<=0"
        return $mkre->('-[0-9]+','0') if $zeroes && $ai;
        return '(?:-?0|-[1-9][0-9]*)' if !$anchor && $ai;
    }
    if ( $n==0 ) {
        return $mkre->('[1-9][0-9]*') if $gt_not_lt;  # ">0"/">=1"
        return '(?!)' unless $ai;  # "<0" for non-neg
        return $mkre->('-[1-9][0-9]*');  # "<0"/"<=-1"
    }
    if ( $ai && !$anchor && !$zeroes ) {
        # just a minor length optimization:
        #      '(?:[01]|-0|-[1-9][0-9]*)'
        return '(?:1|-?0|-[1-9][0-9]*)' if !$gt_not_lt && $n==2;
        #      '(?:0|[1-9][0-9]*|-[01])'
        return '(?:[1-9][0-9]*|-?0|-1)' if $gt_not_lt && $n==-2;
    }

    # Prepare some variables
    my $reflect = $ai && $n<0;             # reflect the number line over zero
    $gt_not_lt = !$gt_not_lt if $reflect;  # invert operator
    my $an = $reflect ? -$n : $n;          # invert input - abs($n)
    my $minus = $reflect ? '-' : '';       # invert output
    confess "assertion failed: an=$an" unless $an=~/\A[1-9][0-9]*\z/;  # uncoverable branch true

    my %subex;

    # Add the other half of the number line
    if ($ai && !$gt_not_lt) {
        #TODO optimize the following and check if one or two of these can be merged with the special cases above
        if ($reflect) {
            if ($zeroes) { $subex{$_}++ for ('[0-9]+')  }
            else { $subex{$_}++ for ('0','[1-9][0-9]*') }
        }
        elsif ($zeroes) { $subex{$_}++ for ('0','-[0-9]+') }
        else { $subex{$_}++ for ('-0','0','-[1-9][0-9]*') }
    }

    # Add expressions for all ints with a different number of digits
    if ($gt_not_lt) {  # ">": all ints with more digits should match
        if (length($an)==1)  # len 1  => 2+ digits
            { $subex{$minus.'[1-9][0-9]+'}++ }
        else                 # len 2+ => 3+ digits
            { $subex{$minus.'[1-9][0-9]{'.length($an).',}'}++ }
    }
    else {  # "<": all ints with less digits should match
        if (length($an)>3) {    # len 4+ => one to len-1 digits
            $subex{$minus.'0'}++;
            $subex{$minus.'[1-9][0-9]{0,'.(length($an)-2).'}'}++;
        }
        elsif (length($an)>2)  # len 3 => one or two digits
            { $subex{$minus.'[1-9]?[0-9]'}++ }
        elsif (length($an)>1)  # len 2 => one digit
            { $subex{$minus.'[0-9]'}++ }
    }

    # Add expressions for ints with the same number of digits
    my @dig = split //, $an;
    for my $i (0..$#dig) {
        my $rest = $#dig-$i;
        my $rng = $gt_not_lt ? \@_RNG_GT
            : !$#dig||$i ? \@_RNG_LT0 : \@_RNG_LT1;
        $subex{ $minus . substr($an,0,$i) . $rng->[$dig[$i]]
            . ( !$rest ? '' : $rest==1 ? '[0-9]' : "[0-9]{$rest}" ) }++
            # filter these out right away, since they won't match:
            unless $rng->[$dig[$i]] eq '(?!)';
    }

    return $mkre->( keys %subex );
}

1;
__END__

=head1 See Also

=over

=item Python port

L<https://pypi.org/project/re-int-ineq/>
(includes a command-line interface)

=item JavaScript port

L<https://www.npmjs.com/package/re-int-ineq>

=item Web interface

L<https://haukex.github.io/re-int-ineq/>

=back

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
