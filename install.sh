#!/bin/bash

ASTERISK_VER=18
URL=https://downloads.asterisk.org/pub/telephony/asterisk
GZ_FILE=asterisk.tar.gz

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

apt-get update && apt-get upgrade -y
apt-get clean

cd /tmp/

curl -o ${GZ_FILE} ${URL}/asterisk-${ASTERISK_VER}-current.tar.gz
tar xf ${GZ_FILE}

dirname=$(ls /tmp/ | grep "asterisk-${ASTERISK_VER}\.")
cd "/tmp/${dirname}"

echo 'libvpb1 libvpb1/countrycode string 972' | sudo debconf-set-selections -v
contrib/scripts/install_prereq install

contrib/scripts/get_mp3_source.sh
./configure

make menuselect.makeopts

menuselect/menuselect \
    --enable format_mp3 --enable MOH-OPSOUND-ULAW --disable CORE-SOUNDS-EN-GSM \
    --enable CORE-SOUNDS-EN-ULAW --enable codec_opus \
    menuselect.makeopts

make
make install

adduser --system --group --home /var/lib/asterisk \
    --no-create-home --gecos "Asterisk PBX" asterisk

usermod -a -G dialout,audio asterisk

chown -R asterisk: /etc/asterisk \
    /var/{lib,log,spool}/asterisk \
    /usr/lib/asterisk

chmod -R 750 /var/{lib,log,run,spool}/asterisk \
    /usr/lib/asterisk \
    /etc/asterisk

make config

sed -i 's/#AST_USER="asterisk"/AST_USER="asterisk/' /etc/default/asterisk
sed -i 's/#AST_GROUP="asterisk"/AST_GROUP="asterisk/' /etc/default/asterisk

rm -rf /tmp/*
