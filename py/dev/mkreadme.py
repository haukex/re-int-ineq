#!/usr/bin/env python3
from pathlib import Path
from textwrap import dedent
import re_int_ineq

# README.rst is entirely generated from re_int_ineq docstrings.

def main():
    assert isinstance(re_int_ineq.__doc__, str) and isinstance(re_int_ineq.re_int_ineq.__doc__, str)
    mdoc = re_int_ineq.__doc__
    fdoc = dedent(re_int_ineq.re_int_ineq.__doc__)
    mdoc1, mdoc2, mdoc3 = mdoc.partition("Author, Copyright, and License\n")
    assert mdoc3
    with (Path(__file__).parent.parent/'README.rst').open('w', encoding='utf-8') as fh:
        print(mdoc1.removeprefix("\n"), file=fh, end='')
        print("``re_int_ineq``\n---------------", file=fh)
        print(fdoc, file=fh)
        print(mdoc2, file=fh, end='')
        print(mdoc3, file=fh, end='')

if __name__=='__main__':
    main()
