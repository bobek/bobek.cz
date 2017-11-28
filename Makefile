build: clear
	bundle exec middleman build -e production

clear:
	rm -rf build

deploy:
	rsync -av --progress --delete -e 'ssh -l root' build/ srv1.trusted.cz:/var/www/www.bobek.cz/
