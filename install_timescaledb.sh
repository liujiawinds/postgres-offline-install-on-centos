#!/usr/bin/env bash
#===============================================================================================
#   System Required:  CentOS 7.x(64bit)
#   Description:  A tool to install timescaleDB on Linux
#   Author: LiuJia
#===============================================================================================
POSTGRES_PASSWORD="postgres.com"

COLOR_RED='\E[1;31m'
COLOR_YELLOW='\E[1;33m'
COLOR_GREEN='\E[1;42m'
COLOR_END='\E[0m'

# use a do function to exit while execution failed
function do_ {
    "$@" || { echo -e "${COLOR_RED}exec failed: ""$@ ${COLOR_END}"; exit -1; }
}

tar -zxf timescale.tar.gz
# install postgres
yum install timescale/*.rpm

echo -e "${COLOR_GREEN} Initial database before start. ${COLOR_END}"
do_ /usr/pgsql-11/bin/postgresql-11-setup initdb
do_ echo "listen_addresses = '0.0.0.0'" >> /var/lib/pgsql/11/data/postgresql.conf
do_ echo "export PATH=\$PATH:/usr/pgsql-11/bin" >> ~/.bash_profile

source ~/.bash_profile

systemctl enable postgresql-11.service
systemctl start postgresql-11.service

echo -e "${COLOR_GREEN} Tune postgres parameters to fit timescaleDB... ${COLOR_END}"
timescaledb-tune --pg-config=/usr/pgsql-11/bin/pg_config

do_ systemctl restart postgresql-11.service

do_ su - postgres<<EOF
    psql
    \c postgres
    CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
    ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';
EOF
echo -e "${COLOR_GREEN} Change postgres user: postgres, password: ${POSTGRES_PASSWORD} ${COLOR_END}"

# switch client authentication methods to md5
do_ sed -i 's/    ident/    md5/g' /var/lib/pgsql/11/data/pg_hba.conf
do_ echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/pgsql/11/data/pg_hba.conf

do_ systemctl restart postgresql-11.service

echo -e "${COLOR_GREEN}Install complete !!!${COLOR_END}"