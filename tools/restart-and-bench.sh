#!/bin/bash
set -euvx

sudo truncate -s 0 -c /var/log/nginx/access.log
# sudo truncate -s 0 -c /var/log/nginx/error.log
sudo truncate -s 0 -c /var/log/mysql/mysql-slow.log
# sudo truncate -s 0 -c /var/log/mysql/error.log
# mysqladmin flush-logs

cd /home/isucon/webapp/go
make
sudo systemctl restart isucholar.go

sudo systemctl restart mysql
sudo systemctl restart nginx

cd ~/benchmarker
./bin/benchmarker -target localhost:443 -tls | tee ~/log/bench-$(date +%Y%m%d-%H%M%S).log

sudo cat /var/log/nginx/access.log |
alp json --sort avg -r -m '^/api/announcements/[0-9A-Z]+$','^/api/courses/[0-9A-Z]+$','^/api/courses/[0-9A-Z]+/status$','^/api/courses/[0-9A-Z]+/classes$','^/api/courses/[0-9A-Z]+/classes/[0-9A-Z]+/assignments$','^/api/courses/[0-9A-Z]+/classes/[0-9A-Z]+/assignments/export$','^/api/courses/[0-9A-Z]+/classes/[0-9A-Z]+/assignments/scores$' |
tee ~/log/alp-$(date +%Y%m%d-%H%M%S).log
# -q --qs-ignore-values

# sudo mysqldumpslow /var/log/mysql/mysql-slow.log | tee ~/log/slow-$(date +%Y%m%d-%H%M%S).log
# sudo pt-query-digest /var/log/mysql/mysql-slow.log | tee ~/log/pt-query-digest-$(date +%Y%m%d-%H%M%S).log

# go tool pprof -http=:10060 http://localhost:6060/debug/pprof/profile

