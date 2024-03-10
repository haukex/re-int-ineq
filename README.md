Regular Expression Integer Inequalities
=======================================

This repository contains a library for generating regular expressions that
match integers that fulfill a specified inequality (greater than, less than,
and so on).

For example, `re_int_ineq(">=", 42)` produces the regular expression
`(?<![0-9])(?:4[2-9]|[1-9][0-9]{2,}|[5-9][0-9])(?![0-9])`, which matches
all integers greater than or equal to 42.

The library was originally written in Perl, and ported to Python and
JavaScript (ES2018 or newer required). The source code for these libraries
is in the `pl`, `py`, and `js` directories, respectively.

Readme files:

- [Perl](pl/README.md)
- [Python](py/README.rst)
- [JavaScript](js/README.md)

The modules are published at:

- **Perl version:** <https://metacpan.org/pod/Regexp::IntInequality>

- **Python port:** <https://pypi.org/project/re-int-ineq/>
  (includes a command-line interface)

- **JavaScript port:** <https://www.npmjs.com/package/re-int-ineq>

- **Web interface:** <https://haukex.github.io/re-int-ineq/>
