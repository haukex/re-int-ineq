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

``re_int_ineq``
---------------

Generates a regex that matches integers according to its parameters. ::

    >>> import re
    >>> from re_int_ineq import re_int_ineq
    >>> gt = re_int_ineq('>', 42)
    >>> s = "Do you know why 23, 74, and 47 are special? And what about 42?"
    >>> re.findall(gt, s)
    ['74', '47']
    >>> le = re.compile(r'\A' + re_int_ineq('<=', 42, True) + r'\Z')
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
    you might add ``\A`` before the generated regex and ``\Z`` after,
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
