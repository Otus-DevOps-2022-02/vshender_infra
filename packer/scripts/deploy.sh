#!/usr/bin/env sh

sudo apt update
sudo apt install -y git

cd /home/appuser

git clone -b monolith https://github.com/express42/reddit.git

cd reddit
bundle install
