all: clean build watch

clean:
	rm -rf public

build:
	statik

watch:
	statik --watch
