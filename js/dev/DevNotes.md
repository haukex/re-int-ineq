Development Notes
=================

- Note `ts-jest` version should match version of other `jest` packages: <https://stackoverflow.com/q/70262724>

Development Environment
-----------------------

- [ ] I recommend development on Linux, although I think Windows might work too
- [ ] Latest Node.js as per <https://github.com/haukex/toolshed/blob/main/notes/JavaScript.md>
- [ ] `npm install` (or `npm clean-install` if starting fresh)

Testing
-------

- [ ] `npm test` - tests including lint & coverage
- [ ] `find . \( -path ./node_modules -prune \) -o \( -iname '*.sh' -exec shellcheck '{}' + \)`

Release Preparation
-------------------

- [ ] Check:
  - [ ] `grep -Eri 'to.?do'`
  - [ ] GitHub Issues
  - [ ] Git stash
  - [ ] Whether the Node.js version in the GitHub Action Workflow needs updating
- [ ] Spellcheck documentation in `src/re-int-ineq.ts`
- [ ] `dev/mkreadme.sh` - generate `README.md`
- [ ] Bump version number in `package.json`
- [ ] Update `CHANGELOG.md`
- [ ] `npm run prepublish` - compile TS
- [ ] `npm pack` - generate the `.tar.gz` that would be uploaded to NPM
  - [ ] `tar tzvf re-int-ineq-*.tgz` - inspect the package for completeness
  - [ ] `rm -v re-int-ineq-*.tgz`
- [ ] `dev/npm-link-test.sh`

Releasing
---------

- [ ] `git commit` and `git push` if needed
- [ ] `git tag vX.X.X`
- [ ] `git push --tags`
- [ ] watch GitHub Actions
- [ ] `npm publish` TODO: untested
- [ ] Add placeholder for next version to `CHANGELOG.md`
