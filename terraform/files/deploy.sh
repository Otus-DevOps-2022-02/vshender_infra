#!/bin/bash
set -e

APP_DIR=${1:-$HOME}

# in order to prevent "E: Could not get lock /var/lib/dpkg/lock-frontend"
while ps -ef | grep apt | grep -v grep > /dev/null; do sleep 1; done

sudo apt-get install -y git

git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit

cd $APP_DIR/reddit
bundle install

sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
