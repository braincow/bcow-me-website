all: clean build publish

clean:
	rm -rf public

build:
	statik

publish:
	scp -r public/* bcow@lakka.kapsi.fi:~/sites/bcow.me/www/

watch:
	statik --watch