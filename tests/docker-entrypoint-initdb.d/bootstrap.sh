#!/bin/bash
set -e

echo 'start init' >> /tmp/init.log
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
alter system set ssl=n;
create user postgres_js_test;
alter system set password_encryption='scram-sha-256';
select pg_reload_conf();
select pg_reload_conf();
create user postgres_js_test_md5 with password 'postgres_js_test_md5';
alter system set password_encryption='md5';
select pg_reload_conf();
select pg_reload_conf();
create user postgres_js_test_scram with password 'postgres_js_test_scram';

drop database if exists postgres_js_test;
create database postgres_js_test;
grant all on database postgres_js_test to postgres_js_test;
alter database postgres_js_test owner to postgres_js_test;
EOSQL

echo 'psql init done' >> /tmp/init.log

cp `dirname $0`/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
cat /var/lib/postgresql/data/pg_hba.conf
echo 'wal_level = logical' >> /var/lib/postgresql/data/postgresql.conf
echo 'max_prepared_transactions = 64' >> /var/lib/postgresql/data/postgresql.conf
echo 'log_min_messages = debug1' >> /var/lib/postgresql/data/postgresql.conf
echo 'ssl = on' >> /var/lib/postgresql/data/postgresql.conf
echo "ssl_cert_file = '/var/lib/postgresql/server.crt'" >> /var/lib/postgresql/data/postgresql.conf
echo "ssl_key_file = '/var/lib/postgresql/server.key'" >> /var/lib/postgresql/data/postgresql.conf

cat /var/lib/postgresql/data/postgresql.conf

mkdir -p /tmp/init
pushd /tmp/init > /dev/null
openssl req -new -text -passout pass:abcd -subj /CN=localhost -out server.req -keyout privkey.pem
openssl rsa -in privkey.pem -passin pass:abcd -out server.key
openssl req -x509 -in server.req -text -key server.key -out server.crt
chmod 600 server.key
cp server.key /var/lib/postgresql/
cp server.crt /var/lib/postgresql/
popd > /dev/null

echo 'end init' >> /tmp/init.log