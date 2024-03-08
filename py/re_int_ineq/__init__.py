"""
Regular Expression Integer Inequalities
=======================================

This module provides a single function, ``re_int_ineq``, which generates
regular expressions that match integers that fulfill a specified inequality
(greater than, less than, and so on). By default, only non-negative integers
are matched (minus signs are ignored), and optionally all integers can be
matched, including negative. Integers with leading zeros are never matched.

**Note:** Normally, this is not a task for regular expressions, instead it is
often preferable to use regular expressions or other methods to extract the
numbers from a string and then use normal numeric comparison operators.
However, there are cases where this module can be useful, for example when
embedding these regular expressions as part of a larger expression or
grammar, or when dealing with an API that only accepts regular expressions.

The generated regular expressions are valid in Perl, Python, and JavaScript
ES2018 or later, and probably in other languages that support lookaround
assertions with the same syntax.

See Also
--------

- **Perl version:** https://metacpan.org/pod/Regexp::IntInequality

- **JavaScript port:** https://www.npmjs.com/package/re-int-ineq

Author, Copyright, and License
------------------------------

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
along with this program. If not, see https://www.gnu.org/licenses/
"""
import argparse

# CODE COMMENTS: This file is lacking code comments because it is a port
# of the Perl version. Please see that for information on the code flow.

_RNG_GT  :tuple[str,...] = tuple( f"[{i}-9]" for i in range(1,8) ) + ( '[89]', '9', '(?!)' )
_RNG_LT0 :tuple[str,...] = ( '(?!)', '0', '[01]' ) + tuple( f"[0-{i}]" for i in range(2,9) )
_RNG_LT1 :tuple[str,...] = ( '(?!)', '(?!)', '1', '[12]' ) + tuple( f"[1-{i}]" for i in range(3,9) )

_ALLINT_ZN :set[str] = {'-0','0','-[1-9][0-9]*'}
_ALLINT_ZP :set[str] = {'-0','0','[1-9][0-9]*'}
_ALLINT_NN :set[str] = {'0','[1-9][0-9]*'}

_PREFIX_NN = '(?<![0-9])'
_PREFIX_AI = '(?<![-0-9])'
_SUFFIX = '(?![0-9])'

_ANY_ZP :set[str] = {  f"[0-{i}]" for i in range(2,10) } | { '[01]',  '[1-9]?[0-9]'}
_ANY_ZN :set[str] = { f"-[0-{i}]" for i in range(2,10) } | {'-[01]', '-[1-9]?[0-9]'}

def re_int_ineq(op :str, n: int, allint :bool = False, anchor :bool = True) -> str:  # pylint: disable=too-many-statements,too-many-return-statements,too-many-branches  # noqa: E501
    """
    Generates a regex that matches integers according to its parameters. ::

        >>> import re
        >>> from re_int_ineq import re_int_ineq
        >>> gt = re_int_ineq('>', 42)
        >>> s = "Do you know why 23, 74, and 47 are special? And what about 42?"
        >>> re.findall(gt, s)
        ['74', '47']
        >>> le = re.compile(r'\\A' + re_int_ineq('<=', 42, True) + r'\\Z')
        >>> for i in ("-123", "42", "47"):
        ...     if le.fullmatch(i):
        ...         print(i+" matches")
        ...     else:
        ...         print(i+" doesn't match")
        -123 matches
        42 matches
        47 doesn't match

    Note the regular expressions will grow significantly the more digits are in
    the integer. I suggest not to generate regular expressions from unbounded
    user input.

    :param str op: The operator the regex should implement, one of ``">"``,
        ``">="``, ``"<"``, ``"<="``, ``"!="``, or ``"=="`` (the latter is
        provided simply for completeness, despite the name of this module).

    :param int n: The integer against which the regex should compare.
        May only be negative when ``allint`` is true.

    :param bool allint: If ``False`` (the default), the generated regex will
        only cover positive integers and zero, and ``n`` may not be negative.
        **Note** that in this case, any minus signs before integers are not
        included in the regex. This means that when using the regex, for
        example, to extract integers greater than 10 from the string
        ``"3 5 15 -7 -12"``, it will match ``"15"`` **and** ``"12"``!

        If ``True``, the generated regex will cover all integers, including
        negative, and ``integer`` may also be any integer. Note that all
        generated regexes that match zero will also match ``"-0"`` and vice
        versa.

    :param bool anchor: This is ``True`` by default, meaning the regex will
        have zero-width assertions (a.k.a. anchors) surrounding the expression
        in order to prevent matches inside of integers. For example, when
        extracting integers less than 20 from the string ``"1199 32 5"``, the
        generated regex will by default not extract the ``"11"`` or ``"19"``
        from ``"1199"``, and will only match ``"5"``. On the other hand, any
        non-digit characters (including minus signs) are considered delimiters:
        extracting all integers less than 5 from the string ``"2x3-3-24y25"``
        with ``allint`` turned on will result in ``"2"``, ``"3"``, ``"-3"``,
        and ``"-24"``.

        This behavior is useful if you are extracting numbers from a longer
        string. If you want to validate that a string contains *only* an
        integer, then you will need to add additional anchors. For example,
        you might add ``\\A`` before the generated regex and ``\\Z`` after,
        and use ``re.fullmatch`` to validate that a string contains only that
        integer. However, this task is more commonly done by first checking
        that the string is a valid integer in general, such as via ``int()``,
        and then using normal numeric comparisons to check that it is in the
        range you expect.

        If on the other hand you want to turn off the default anchors described
        above, perhaps because you want to implement your own, then you can
        set this option to ``False``. Repeating the above example, extracting
        integers less than 20 from the string ``"1199 32 5"`` with this option
        off and no additional anchors results in ``"11"``, ``"9"``, ``"9"``,
        ``"3"``, ``"2"``, and ``"5"`` - so use this feature with caution and
        testing!

    :return: The regular expression. It is returned as a string rather than a
        precompiled regex so it can more easily be embedded in larger
        expressions.
    :rtype: str
    """
    if not isinstance(n, int):  # pyright: ignore [reportUnnecessaryIsInstance]
        raise TypeError("Bad integer")
    if not allint and n<0:
        raise ValueError("Can't pass an integer <0 unless allint is set")

    if op=='==':
        if not anchor:
            if not n and allint:
                return '-?0'
            return str(n)
        if not n and allint:
            return f"(?:{_PREFIX_AI}0|-0){_SUFFIX}"
        if n<0:
            return str(n)+_SUFFIX
        if allint:
            return _PREFIX_AI+str(n)+_SUFFIX
        return _PREFIX_NN+str(n)+_SUFFIX
    if op=='!=':
        if not anchor:
            if n:
                return f"(?!{n}){'-?' if allint else ''}(?:0|[1-9][0-9]*)"
            return f"{'-?' if allint else ''}[1-9][0-9]*"
        if allint:
            return f"(?!{n if n else '-?0'}{_SUFFIX})(?:{_PREFIX_AI}(?:0|[1-9][0-9]*)|-0|-[1-9][0-9]*){_SUFFIX}"
        return f"(?!{n}{_SUFFIX}){_PREFIX_NN}(?:0|[1-9][0-9]*){_SUFFIX}"

    def mkre(se :set[str]) -> str:
        assert se

        if se & _ANY_ZP:
            se.discard('0')
        if se & _ANY_ZN:
            se.discard('-0')

        pos :list[str] = []
        neg :list[str] = []
        for e in se:
            if e.startswith('-'):
                neg.append(e)
            else:
                pos.append(e)
        pos.sort()
        neg.sort()

        alle :list[str] = []

        if not anchor:
            alle.extend(pos)
        elif pos:
            pfx = _PREFIX_AI if allint else _PREFIX_NN
            if len(pos)>1:
                alle.append( f"{pfx}(?:{'|'.join(pos)})" )
            else:
                alle.append( pfx+pos[0] )

        if len(neg)<6:
            alle.extend(neg)
        else:
            alle.append( f"-(?:{'|'.join(n[1:] for n in neg)})" )

        assert alle
        suf = _SUFFIX if anchor else ''
        if len(alle)>1:
            return f"(?:{'|'.join(alle)}){suf}"
        return alle[0]+suf

    gt_not_lt :bool
    if op in ('>','>='):
        if op == '>=': n -= 1
        gt_not_lt = True
    elif op in ('<','<='):
        if op == '<=': n += 1
        gt_not_lt = False
    else:
        raise ValueError("Invalid operator")

    if not n and not gt_not_lt and not allint:
        return '(?!)'
    if n==-1 and gt_not_lt:
        return mkre( _ALLINT_ZP if allint else _ALLINT_NN )
    if not n:
        return mkre( {'[1-9][0-9]*'} if gt_not_lt else {'-[1-9][0-9]*'} )

    reflect = allint and n<0
    if reflect: gt_not_lt = not gt_not_lt
    an = str( -n if reflect else n )
    minus = '-' if reflect else ''
    assert int(an)>0

    subex :set[str] = set()

    if allint and not gt_not_lt:
        subex |= _ALLINT_NN if reflect else _ALLINT_ZN

    if gt_not_lt:
        if len(an)==1:
            subex.add( minus+'[1-9][0-9]+' )
        else:
            subex.add( f"{minus}[1-9][0-9]{{{len(an)},}}" )
    else:
        if len(an)>3:
            subex.add( minus+'0' )
            subex.add( f"{minus}[1-9][0-9]{{0,{len(an)-2}}}" )
        elif len(an)>2:
            subex.add( minus+'[1-9]?[0-9]' )
        elif len(an)>1:
            subex.add( minus+'[0-9]' )

    for i,d in enumerate(an):
        rest :str
        if (r := len(an)-i-1) > 1: rest = f"[0-9]{{{r}}}"
        elif r==1: rest = '[0-9]'
        else: rest = ''
        rng :str
        if gt_not_lt: rng = _RNG_GT[int(d)]
        elif len(an)==1 or i: rng = _RNG_LT0[int(d)]
        else: rng = _RNG_LT1[int(d)]
        if rng != '(?!)':
            subex.add( minus + an[:i] + rng + rest )

    return mkre(subex)

_OPMAP = { 'lt':'<', 'le':'<=', 'gt':'>', 'ge':'>=', 'ne':'!=', 'eq':'==' }

def main():
    parser = argparse.ArgumentParser(description='Regular Expression Integer Inequalities')
    parser.add_argument('-n', '--allint', action='store_true', help='match all integers, including negative')
    parser.add_argument('-A', '--no-anchor', action='store_true', help="don't add anchors to regex")
    parser.add_argument('op', choices=list(_OPMAP.keys())+list(_OPMAP.values()), help='the operator to implement')
    parser.add_argument('n', type=int, help='the integer to compare against')
    args = parser.parse_args()
    print(re_int_ineq(_OPMAP[args.op] if args.op in _OPMAP else args.op, args.n, args.allint, not args.no_anchor))
    parser.exit(0)
