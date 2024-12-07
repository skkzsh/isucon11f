SHELL := /bin/bash

NOW := $(shell date +%m%d-%H%M%S)
DATE ?= $(NOW)

ISSUE := 1


PROG := go
GIT_DIR   := ~/webapp
APP_NAME  := isucholar
BUILD_CMD := make
BENCH_DIR := ~/benchmarker
BENCH_CMD := ./bin/benchmarker -target localhost:443 -tls
ID_PATTERN := [0-9A-Z]+
ALP_MATCH  := ''
# '^/api/announcements/[0-9A-Z]+$$','^/api/courses/[0-9A-Z]+$$','^/api/courses/[0-9A-Z]+/status$$','^/api/courses/[0-9A-Z]+/classes$$','^/api/courses/[0-9A-Z]+/classes/[0-9A-Z]+/assignments$$','^/api/courses/[0-9A-Z]+/classes/[0-9A-Z]+/assignments/export$$','^/api/courses/[0-9A-Z]+/classes/[0-9A-Z]+/assignments/scores$$'
# TODO: ALP_MATCHはAPIの実装やnginxのlogから決める

APP_DIR      := $(GIT_DIR)/$(PROG)
SERVICE_NAME := $(APP_NAME).$(PROG)

ALP_OPTS ?= -q # --qs-ignore-values --limit 10000

NGINX_ACCESS_LOG  := /var/log/nginx/access
NGINX_ERROR_LOG   := /var/log/nginx/error
NGINX_CONF        := /etc/nginx/nginx.conf
NGINX_SITES_AVAIL := /etc/nginx/sites-available

DB_MIDDLE ?= mysql
SLOW_QUERY_LOG  := /var/log/mysql/$(DB_MIDDLE)-slow
MYSQL_ERROR_LOG := /var/log/mysql/error
MYSQLD_CONF     := /etc/mysql/mysql.conf.d/mysqld.cnf

.PHONY: conf/backup conf/nginx/deploy conf/mysql/deploy rotate truncate build restart prepare bench/before bench bench/after alp slp issue

all: bench bench/after
bench/after: tune issue
# TODO: alp slp
bench/before: prepare truncate build restart

conf/backup:
	mkdir -p $(GIT_DIR)/etc/{nginx/sites-available,mysql/$(DB_MIDDLE).conf.d}
	cp {,$(GIT_DIR)}$(NGINX_CONF)
	cp $(NGINX_SITES_AVAIL)/*.conf $(GIT_DIR)$(NGINX_SITES_AVAIL)/
	cp {,$(GIT_DIR)}$(MYSQLD_CONF)

conf/nginx/deploy:
	sudo cp $(NGINX_CONF){,.$(DATE)}
	sudo cp {$(GIT_DIR),}$(NGINX_CONF)
	sudo cp $(NGINX_SITES_AVAIL)/$(APP_NAME).conf{,.$(DATE)}
	# sudo cp -r $(NGINX_SITES_AVAIL){,.$(DATE)}
	sudo cp $(GIT_DIR)$(NGINX_SITES_AVAIL)/*.conf $(NGINX_SITES_AVAIL)/

conf/mysql/deploy:
	sudo cp $(MYSQLD_CONF){,.$(DATE)}
	sudo cp {$(GIT_DIR),}$(MYSQLD_CONF)

rotate:
	sudo mv $(NGINX_ACCESS_LOG){,-$(DATE)}.log
	sudo mv $(NGINX_ERROR_LOG){,-$(DATE)}.log
	sudo mv $(SLOW_QUERY_LOG){,-$(DATE)}.log
	sudo mv $(MYSQL_ERROR_LOG){,-$(DATE)}.log

truncate:
	sudo truncate -s0 -c $(NGINX_ACCESS_LOG).log $(NGINX_ERROR_LOG).log $(SLOW_QUERY_LOG).log $(MYSQL_ERROR_LOG).log
    # mysqladmin flush-logs

build:
	cd $(APP_DIR) && $(BUILD_CMD)
	sudo systemctl restart $(SERVICE_NAME)
# while ! nc -z localhost 3000; do echo "Waiting for port..."; sleep 1; done

# clear:
    # redis-cli FLUSHALL
    # sudo rm -rf /var/cache/nginx

restart:
	sudo systemctl restart $(DB_MIDDLE)
	sudo systemctl restart nginx
    # sudo systemctl restart datadog-agent
    # sudo systemctl restart memcached
    # sudo systemctl restart redis

prepare:
	mkdir -p ~/results

bench: bench/before
	cd $(BENCH_DIR); \
	$(BENCH_CMD) \
	> >(tee ~/results/bench-$(DATE).log) \
	2> >(tee ~/results/bench-error-$(DATE).log >&2)

alp: prepare # avg, sum
	sudo alp json --file $(NGINX_ACCESS_LOG).log \
	$(ALP_OPTS) --sort avg -r \
	-m $(ALP_MATCH)\
	| tee ~/results/alp-$(DATE).log

slp: prepare
	sudo pt-query-digest $(SLOW_QUERY_LOG).log \
	| tee ~/results/pt-query-digest-$(DATE).log

tune: prepare
	sudo mysqltuner --user isucon --pass isucon \
	| tee ~/results/mysqltuner-$(DATE).log

issue:
	(cd $(APP_DIR); git rev-parse HEAD; \
	echo "\`\`\`"; grep -i score ~/results/bench-$(DATE).log; echo "\`\`\`"; \
	echo "<details><summary>Bench</summary>"; echo -e "\n\`\`\`"; cat ~/results/bench-$(DATE).log; echo "\`\`\`"; echo "</details>"; \
	echo "<details><summary>Bench error</summary>"; echo -e "\n\`\`\`"; cat ~/results/bench-error-$(DATE).log; echo "\`\`\`"; echo "</details>"; \
	echo "<details><summary>MySQL tuner</summary>"; echo -e "\n\`\`\`"; cat ~/results/mysqltuner-$(DATE).log; echo "\`\`\`";  echo "</details>"; \
	echo "<details><summary>NGINX error</summary>"; echo -e "\n\`\`\`"; sudo cat $(NGINX_ERROR_LOG).log; echo "\`\`\`"; echo "</details>"; \
	echo "<details><summary>MySQL error</summary>"; echo -e "\n\`\`\`"; sudo cat $(MYSQL_ERROR_LOG).log; echo "\`\`\`";  echo "</details>"; \
	echo "<details><summary>App error</summary>"; echo -e "\n\`\`\`"; sudo journalctl -u $(SERVICE_NAME) --since "$$(systemctl show $(SERVICE_NAME) -p ActiveEnterTimestamp | cut -d= -f2)" --no-pager -o json | jq -r .MESSAGE | jq -R 'fromjson? | select(.error != "")'; echo "\`\`\`"; echo "</details>"; \
	) | \
	gh issue comment $(ISSUE) -F-
    # echo "<details><summary>App error</summary>"; echo -e "\n\`\`\`"; sudo journalctl -u $(SERVICE_NAME) --since "$$(systemctl show $(SERVICE_NAME) -p ActiveEnterTimestamp | cut -d= -f2)" --no-pager -p err ; echo "\`\`\`"; echo "</details>"; \

    # TODO: alp
	# echo "<details><summary>alp</summary>"; echo -e "\n\`\`\`"; cat ~/results/alp-$(DATE).log; echo "\`\`\`";  echo "</details>"; \
    # TODO: slow query
	# echo "<details><summary>Slow query</summary>"; echo -e "\n\`\`\`"; cat ~/results/pt-query-digest-$(DATE).log; echo "\`\`\`";  echo "</details>"; \
