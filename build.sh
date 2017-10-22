#!/bin/sh
#mapr edge node dynamic build script
#Log everything in /tmp/build.log
logfile=/tmp/build.log
exec > $logfile 2>&1
set -x

#set environment
ZEPPELIN_HOME="/opt/zeppelin"
ZEPPELIN_VER=0.7.3
ZEP_DL_URL="http://www.apache.org/dyn/closer.cgi/zeppelin/zeppelin-${ZEPPELIN_VER}/zeppelin-${ZEPPELIN_VER}-bin-all.tgz"


#The following mapr packages are installed by default
# mapr-client mapr-posix-client-basic mapr-hbase mapr-asynchbase mapr-spark mapr-hive mapr-kafka mapr-librdkafka
# Install additional packages as needed
yum -y --nogpgcheck install mapr-drill

#Install zeppelin
mkdir -p $ZEPPELIN_HOME
wget -q $ZEP_DL_URL -P /tmp
tar xzf /tmp/zeppelin-${ZEPPELIN_VER}-bin-all.tgz -C $ZEPPELIN_HOME
chown -R mapr:mapr $ZEPPELIN_HOME


exit 0



