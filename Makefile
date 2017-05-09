all: clean build

clean:
	rm -rf public

build:
	statik

watch:
	statik --watch