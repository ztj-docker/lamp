#!/bin/sh

rm -rf /var/run/apache2/httpd.pid
rm -rf /var/run/mysqld/mysqld.pid
rm -rf /var/run/sshd.pid

exec "$@"
