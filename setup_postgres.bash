#!/bin/bash
sed -i 's/de_DE/en_US/' /etc/postgresql/9.4/main/postgresql.conf
sed -ri 's/(local\s+all\s+postgres\s+)peer/\1trust/' /etc/postgresql/9.4/main/pg_hba.conf

service postgresql start

mkdir -p /usr/local/var/postgres
chown postgres:postgres /usr/local/var/postgres
sudo -u postgres /usr/lib/postgresql/9.4/bin/initdb /usr/local/var/postgres -E utf8
# sudo -u postgres createuser -d -w -s postgres # role already exists
sudo -u postgres createdb ontohub_development
sudo -u postgres createdb ontohub_test
sudo -u postgres createdb ontohub

service postgresql stop
