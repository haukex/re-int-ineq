
# Run `npm start` for the dev server

dist/index.html: src/index.html src/main.ts test package.json package-lock.json tsconfig.json .parcelrc
	npm run build

.PHONY: test
test:
	npm test

.PHONY: clean
clean:
	git clean -dxf dist .parcel-cache

.PHONY: installdeps
installdeps:
	npm ci
