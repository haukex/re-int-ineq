Development Notes
=================

Development Environment
-----------------------

- [ ] I suggest development on Linux, although I think Windows should work too
- [ ] In order to run full tests locally, install multiple Python versions with `python3.X`
  aliases, e.g as per <https://github.com/haukex/toolshed/blob/main/notes/Python.md>,
  and use the lowest supported version for normal development to catch any backcompat issues
- [ ] `python3.9 -m venv .venv3.9` and `. .venv3.9/bin/activate`
- [ ] `make installdeps` - set up dev env
- [ ] Installing Pyright (if you don't have Node/Pyright already):
  - [ ] Install Node as per <https://github.com/haukex/toolshed/blob/main/notes/JavaScript.md>
  - [ ] `npm install -g pyright`
- [ ] `pip install build twine` - for making releases

Testing
-------

- [ ] `make` - tests incl. lint & coverage
- [ ] `dev/local-actions.sh` - tests on all Python versions
- [ ] Run tests on Windows manually (or Linux if developing on Windows)

Release Preparation
-------------------

- [ ] Check:
  - [ ] `make tasklist`
  - [ ] GitHub Issues
  - [ ] Git stash
  - [ ] Whether the Python versions in `dev/local-actions.sh` and the GitHub Actions Workflows need updating
- [ ] Spellcheck documentation in `re_int_ineq.py`
- [ ] `PYTHONPATH=. dev/mkreadme.py` - generate `README.rst`
- [ ] Bump version number in `pyproject.toml`
- [ ] Update `CHANGELOG.rst` (reference: <https://github.com/pypa/packaging/blob/main/CHANGELOG.rst>)

Releasing
---------

**These steps should be done on Linux!**

- [ ] `git commit` and `git push` if needed
- [ ] `git tag vX.X.X`
- [ ] `git push --tags`
- [ ] watch GitHub Actions
- [ ] `python3 -m build`  (TODO: test these steps starting here!)
- [ ] `tar tzvf dist/re_int_ineq-*.tar.gz` to inspect the package
- [ ] `dev/isolated-test.sh dist/re_int_ineq-*.tar.gz`
- [ ] `twine upload dist/re_int_ineq-*.tar.gz`
- [ ] New GitHub Release:
  Title "re-int-ineq vX.X.X", body from the changelog reformatted as Markdown,
  link to PyPI (specific version); attach `.tar.gz` to release
- [ ] `pip3 install --update re-int-ineq` and `re-int-ineq -n lt 3`
- [ ] `git clean -dxf dist *.egg-info`
- [ ] Add placeholder for next version to `CHANGELOG.rst`
