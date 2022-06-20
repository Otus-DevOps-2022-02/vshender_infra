#!/usr/bin/env sh

apt update

# in order to prevent "E: Could not get lock /var/lib/dpkg/lock-frontend"
while ps -ef | grep apt | grep -v grep > /dev/null; do sleep 1; done

apt install -y ruby-full ruby-bundler build-essential
