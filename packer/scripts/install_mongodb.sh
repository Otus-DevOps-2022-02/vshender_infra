#!/usr/bin/env sh

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list

# in order to prevent "E: Could not get lock /var/lib/dpkg/lock-frontend"
while ps -ef | grep apt | grep -v grep > /dev/null; do sleep 1; done

apt install -y apt-transport-https ca-certificates

apt update
apt install -y mongodb-org

systemctl start mongod
systemctl enable mongod
