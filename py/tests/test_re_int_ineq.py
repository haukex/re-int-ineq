"""Tests for ``re_int_ineq``.

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
import re
import sys
import json
import doctest
import unittest
from io import StringIO
from pathlib import Path
from itertools import chain
from typing import Any, Union
from unittest.mock import patch
from contextlib import redirect_stdout
import re_int_ineq as uut
from re_int_ineq import re_int_ineq

def load_tests(_loader, tests, _ignore):
    tests.addTests(doctest.DocTestSuite(re_int_ineq.__module__))
    return tests

class RegexpIntInequalityTestCase(unittest.TestCase):

    testcases :dict[str, Any]

    @classmethod
    def setUpClass(cls):
        ver = re.sub('\\s+',' ',sys.version)
        print(f"# This is Python {ver} at {sys.executable} on {sys.platform}")
        with (Path(__file__).parent/'testcases.json').open('rb') as fh:
            cls.testcases = json.load(fh)

    def test_manual(self):
        for case in self.testcases['manual_tests']:
            if isinstance(case, str): continue
            assert isinstance(case, list)
            op :str
            n :Union[int,str]
            ai :bool
            anc :bool
            exp :str
            op,n,ai,anc,exp = case
            got = re_int_ineq(op, int(n), ai, anc)
            self.assertEqual(exp, got, f"{op=} {n=} {ai=} {anc=} {exp=} {got=}")

    def test_extraction(self):
        for case in self.testcases['extraction']:
            if isinstance(case, str): continue
            assert isinstance(case, list)
            op :str
            n :Union[int,str]
            ai :bool
            anc :bool
            string :str
            exp :list[str]
            op,n,ai,anc,string = case[:5]
            exp = case[5:]
            pat = re.compile(re_int_ineq(op, int(n), ai, anc))
            got = pat.findall(string)
            self.assertEqual(exp, got, f"{op=} {n=} {ai=} {anc=} {string=} {exp=} {got=}")

    def test_zeroes(self):
        nevermatch :list[str] = list(chain.from_iterable(
            [ f"0{c}",f"00{c}",f"-0{c}",f"-00{c}" ] for c in self.testcases['zeroes_nevermatch'] ))
        for case in self.testcases['zeroes']:
            op :str
            n :Union[int,str]
            mz :bool
            op,n,mz = case
            if not str(n).startswith('-'):
                rn = re.compile('\\A'+re_int_ineq(op, int(n))+'\\Z')
                if mz:   self.assertRegex('0', rn, f"N {op}{n}: {rn} should match 0")
                else: self.assertNotRegex('0', rn, f"N {op}{n}: {rn} shouldn't match 0")
                self.assertNotRegex('-0', rn, f"N {op}{n}: {rn} shouldn't match -0")
                for nm in nevermatch:
                    self.assertNotRegex(nm, rn, f"N {op}{n}: {rn} shouldn't match {nm!r}")
            rz = re.compile('\\A'+re_int_ineq(op, int(n), True)+'\\Z')
            if mz:
                self.assertRegex( '0', rz, f"N {op}{n}: {rz} should match 0")
                self.assertRegex('-0', rz, f"N {op}{n}: {rz} should match -0")
            else:
                self.assertNotRegex( '0', rz, f"N {op}{n}: {rz} shouldn't match 0")
                self.assertNotRegex('-0', rz, f"N {op}{n}: {rz} shouldn't match -0")
            for nm in nevermatch:
                self.assertNotRegex(nm, rz, f"N {op}{n}: {rz} shouldn't match {nm!r}")

    def test_errors(self):
        for case in self.testcases['errorcases']:
            if isinstance(case, str): continue
            assert isinstance(case, list)
            with self.assertRaises((TypeError, ValueError)):
                re_int_ineq(*case)

    def test_nonneg(self):
        cases :list[Union[int,str]] = []
        rng :list[int]
        for rng in self.testcases['nonneg_testranges']:
            cases.extend(range(*rng))
        self._run_rangetests(cases, False)

    def test_allint(self):
        cases :list[Union[int,str]] = []
        rng :list[int]
        for rng in self.testcases['allint_testranges']:
            cases.extend(range(*rng))
            cases.extend( f"-{i}" for i in range(*rng) )
        self._run_rangetests(cases, True)

    def _run_rangetests(self, cases :list[Union[int,str]], ai :bool):
        nz = 'Z' if ai else 'N'
        for i in cases:
            ii = int(i)
            rlt = re.compile('\\A'+re_int_ineq('<',  ii, ai)+'\\Z')
            rle = re.compile('\\A'+re_int_ineq('<=', ii, ai)+'\\Z')
            rgt = re.compile('\\A'+re_int_ineq('>',  ii, ai)+'\\Z')
            rge = re.compile('\\A'+re_int_ineq('>=', ii, ai)+'\\Z')
            rne = re.compile('\\A'+re_int_ineq('!=', ii, ai)+'\\Z')
            req = re.compile('\\A'+re_int_ineq('==', ii, ai)+'\\Z')
            for j in cases:
                jj = int(j)
                if jj < ii:  self.assertRegex(str(j), rlt, f"{nz} {j} is    <  {i} and =~ {rlt}")
                else:     self.assertNotRegex(str(j), rlt, f"{nz} {j} isn't <  {i} and !~ {rlt}")
                if jj <= ii: self.assertRegex(str(j), rle, f"{nz} {j} is    <= {i} and =~ {rle}")
                else:     self.assertNotRegex(str(j), rle, f"{nz} {j} isn't <= {i} and !~ {rle}")
                if jj > ii:  self.assertRegex(str(j), rgt, f"{nz} {j} is    >  {i} and =~ {rgt}")
                else:     self.assertNotRegex(str(j), rgt, f"{nz} {j} isn't >  {i} and !~ {rgt}")
                if jj >= ii: self.assertRegex(str(j), rge, f"{nz} {j} is    >= {i} and =~ {rge}")
                else:     self.assertNotRegex(str(j), rge, f"{nz} {j} isn't >= {i} and !~ {rge}")
                if jj != ii: self.assertRegex(str(j), rne, f"{nz} {j} is    != {i} and =~ {rne}")
                else:     self.assertNotRegex(str(j), rne, f"{nz} {j} isn't != {i} and !~ {rne}")
                if jj == ii: self.assertRegex(str(j), req, f"{nz} {j} is    == {i} and =~ {req}")
                else:     self.assertNotRegex(str(j), req, f"{nz} {j} isn't == {i} and !~ {req}")

    def test_cli(self):
        cli_cases = (
            (                       '<', '3', "(?<![0-9])[0-2](?![0-9])"),
            (               '-n',  '<',  '3', "(?:(?<![-0-9])[0-2]|-0|-[1-9][0-9]*)(?![0-9])"),
            (         '--allint', 'lt',  '3', "(?:(?<![-0-9])[0-2]|-0|-[1-9][0-9]*)(?![0-9])"),
            (               '-A', '!=', '42', "(?!42)(?:0|[1-9][0-9]*)"),
            ('--no-anchor', '-n', 'eq',  '0', "-?0"),
        )
        for case in cli_cases:
            sys.argv = ['re-int-ineq'] + list(case)
            exp = sys.argv.pop() + "\n"
            out = StringIO()
            with (redirect_stdout(out), patch('argparse.ArgumentParser.exit') as mock):
                uut.main()
            mock.assert_called_once_with(0)
            self.assertEqual(out.getvalue(), exp)
