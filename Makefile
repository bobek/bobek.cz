all: clear build deploy

build: build_site static

build_site: clear
	bundle exec middleman build -e production

clear:
	rm -rf build

static: funeralni kvetiny
	cp -vr static/* build/static/

funeralni:
	mkdir -p build/static/funeralni_symbolika/
	cp -vr ../funeralni_symbolika/out/* build/static/funeralni_symbolika/

kvetiny:
	mkdir -p build/static/kvetiny/
	cp -vr ../kvetiny/out/* build/static/kvetiny/

deploy:
	rsync -av --progress --delete -e 'ssh -l root' build/ srv1.trusted.cz:/var/www/www.bobek.cz/
