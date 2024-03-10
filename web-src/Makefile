
# Run `npm start` for the dev server

.PHONY: deploy
deploy: dist/index.html
	cp dist/index.html ../docs/

dist/index.html: src/index.html src/main.ts test package.json package-lock.json tsconfig.json .parcelrc
	npm run build

.PHONY: test
test:
	npm test

.PHONY: clean
clean:
	git clean -dxf dist

.PHONY: installdeps
installdeps:
	npm ci
