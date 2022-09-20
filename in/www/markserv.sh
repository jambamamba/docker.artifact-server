#!/bin/bash -xe
set -xe

wwwroot="/tmp/www"
if [ -d /datadisk/nextgen ]; then
   wwwroot="/datadisk/nextgen/www"
   mkdir -p $wwwroot
   pushd $wwwroot
   ln -sf ../out .
   popd
   cp -rf /tmp/www/* $wwwroot/
fi

pushd $wwwroot
ip=$(/sbin/ifconfig eth0| grep inet | awk '{ print $2 }')
markserv -a $ip .
popd

