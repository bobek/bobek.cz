CURRENT_LONG_READ = source/long-reads/$(shell date +%Y)/$(shell date +%Y-%V).html.md
LONG_READ_TEMPLATE = source/long-reads/.template.html.md
BANNERS_SRC = $(wildcard source/long-reads/**/*.md)
BANNERS = $(patsubst %.html.md,%.png,$(BANNERS_SRC)) $(patsubst %.html.md,%-og.png,$(BANNERS_SRC))

VENV_DIR      = build/venv
VENV_ACTIVATE = ${VENV_DIR}/bin/activate
PYTHON        = ${VENV_DIR}/bin/python3

.PHONY: all
all: $(CURRENT_LONG_READ) $(BANNERS)

.PHONY: venv
venv: $(VENV_DIR)/bin/activate

requirements.txt:
	touch requirements.txt

$(VENV_DIR)/bin/activate: requirements.txt
	test -d $(VENV_DIR) || virtualenv -p python3 $(VENV_DIR)
	${PYTHON} -m pip install -U pip
	${PYTHON} -m pip install -Ur requirements.txt
	touch $(VENV_DIR)/bin/activate

.PHONY: send
send: venv
	. $(VENV_ACTIVATE) ; MC_DEST=$(shell gpg --decrypt -qd .mc_destination) bin/prepare_mdmail.rb $(CURRENT_LONG_READ) | mdmail

.PRECIOUS: source/long-reads/%.png
source/long-reads/%.png:
	bin/generate_banner.rb "$@"

source/long-reads/%.html.md: source/long-reads/%.png
	test -f $@ || sed -e "s#WEEK_SLASH#$(shell date +%Y/%V)#" $(LONG_READ_TEMPLATE) |\
		sed -e "s#WEEK_DASH#$(shell date +%Y-%V)#" |\
		sed -e "s/PUBLISH_DATE/$(shell date -dfriday +%Y-%m-%d)/" > $@

build: $(BANNERS) build_site static

build_site: clear
	bundle exec middleman build -e production

clear:
	rm -rf build

static: funeralni kvetiny medicinske
	cp -vr static/* build/static/

funeralni:
	mkdir -p build/static/funeralni_symbolika/
	cp -vr ../funeralni_symbolika/out/* build/static/funeralni_symbolika/

kvetiny:
	mkdir -p build/static/kvetiny/
	cp -vr ../kvetiny/out/* build/static/kvetiny/

medicinske:
	mkdir -p build/static/medicinske_symboly/
	cp -vr ../medicinske_symboly/out/* build/static/medicinske_symboly/

publish: build
	rsync -av --progress --delete -e 'ssh -l root' build/ srv1.trusted.cz:/var/www/www.bobek.cz/
