.PHONY: install

# check for basic deps
HAVE_WGET := $(shell which wget)
HAVE_PKGCONFIG := $(shell which pkg-config)
HAVE_AUTOMAKE := $(shell which automake)
HAVE_AUTOCONF := $(shell which autoconf)
HAVE_REDIS := $(shell which redis-server)

# how it could start if we want to think about a daemon service for osx
ifeq ($(shell uname -s), Darwin)
  flags=-j 8 MALLOC=jemalloc
else
  flags=-j 4
  HAVE_TCL := $(shell dpkg -l tcl | grep tcl)
ifndef HAVE_TCL
$(error tcl is missing)
endif
endif

ifndef HAVE_WGET
$(error wget is missing)
endif
ifndef HAVE_PKGCONFIG
$(error pkgconfig is missing)
endif
ifndef HAVE_AUTOMAKE
$(error automake is missing)
endif
ifndef HAVE_AUTOCONF
$(error autoconf is missing)
endif

eq = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))

ALL:
	$(if $(call eq, $(shell whoami), root), @echo installing, \
	$(error make as root. perhaps try sudo make))
	$(if $(HAVE_REDIS), $(error redis already installed. do sudo make install), \
	@echo installing redis)
	if [ ! -d "/opt/sbin/" ]; then mkdir -p /opt/sbin/; fi
	wget https://github.com/antirez/redis/archive/unstable.tar.gz
	tar xzf unstable.tar.gz && rm unstable.tar.gz
	cd redis-unstable && make $(flags) && make check
	rm -rf /opt/redis && mv redis-unstable /opt/redis
	ln -s /opt/redis/src/redis-server /usr/local/bin/redis-server
	ln -s /opt/redis/src/redis-server /opt/sbin/redis-server
	ln -s /opt/redis/src/redis-cli /opt/sbin/redis-cli
	ln -s /opt/redis/src/redis-cli /usr/local/bin/redis-cli

install:
	$(if $(call eq, $(shell whoami), root), @echo installing, \
	$(error install as root. perhaps try sudo make install))
	if [ ! -d "/data/redis/" ]; then mkdir -p /data/redis; fi
	if [ ! -d "/etc/redis/" ]; then mkdir /etc/redis; fi
	if [ -f "/etc/redis/redis.conf" ]; then rm /etc/redis/redis.conf; fi
	if [ -f "/etc/init.d/redis" ]; then /etc/init.d/redis stop && rm /etc/init.d/redis; fi
	cp redis.conf /etc/redis/redis.conf
	cp redis /etc/init.d/redis
	chmod a+x /etc/init.d/redis
	update-rc.d redis defaults
	@echo init.d service installed
	/etc/init.d/redis start
	@echo please reboot now
