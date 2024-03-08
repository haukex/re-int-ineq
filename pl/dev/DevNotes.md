Development Notes
=================

Development Environment
-----------------------

- [ ] I strongly recommend Linux for development
- [ ] Perl 5.36+ e.g. via <https://perlbrew.pl/>
- [ ] `( cd xt && cpanm --installdeps . )` - for author tests
- [ ] Testing on all Perl versions locally:
  - [ ] requires Docker
  - [ ] `( cd dev/allver-test && cpanm --installdeps . )`

Testing
-------

- [ ] `prove -l` - normal tests
- [ ] `prove -l t xt` - with author tests (lint etc.)
- [ ] Coverage: See output of author tests for how to run it
- [ ] `dev/allver-test/run-allver.sh` - test on all Perl versions
- [ ] Run tests on Windows manually
- [ ] `find . -iname '*.sh' -exec shellcheck '{}' +`

Release Preparation
-------------------

- [ ] Check:
  - [ ] Task report from author tests
  - [ ] GitHub Issues
  - [ ] CPAN Testers failures
  - [ ] Git stash
  - [ ] Whether the Perl version list in `dev/allver-test/perlver.sh` and the
    Perl versions in the GitHub Action Workflows need updating
- [ ] Spellcheck Readme and POD (e.g. VSCode or `vim` `:setlocal spell`)
- [ ] `podchecker lib/Regexp/IntInequality.pm`
- [ ] `perldoc lib/Regexp/IntInequality.pm`
- [ ] `pod2html lib/Regexp/IntInequality.pm >reintineq.html ; rm pod2htmd.tmp`
- [ ] Bump version number everywhere: `lib`, `t`, `Makefile.PL`
- [ ] Update `Changes`
  - Also add commit hash for previous release
  - GitHub will highlight contributors if you @ them

Releasing
---------

- [ ] `git commit` and `git push` if needed
- [ ] `git tag vX.XX`
- [ ] `git push --tags`
- [ ] watch GitHub Actions
- [ ] `perl Makefile.PL` - inspect output for warnings/errors!
- [ ] `make && make test && make dist` - inspect output!
- [ ] Test installation of the `.tar.gz` release on a local Windows & Linux
  machine
- [ ] Upload the `.tar.gz` file to PAUSE
- [ ] New GitHub Release:
  Title "Regexp::IntInequality vX.XX", body from the changelog reformatted as
  Markdown, links to Metacpan release and CPAN download link; attach `.tar.gz`
  to release
- [ ] `make distclean`
- [ ] Add placeholder for next version to `Changes`

Other Notes
-----------

- For some other modules, I do the following, which are then things that need
  to be updated before and after each release:
  - Odd version numbers when in development
  - A note `B<This is a development version.>` in the POD
  - A GitHub milestone to track the next release
