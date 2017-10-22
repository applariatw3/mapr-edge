#!/bin/sh
#mapr edge node dynamic build script
#Log everything in /tmp/build.log
logfile=/tmp/build.log
exec > $logfile 2>&1
set -x

#set environment
ZEPPELIN_HOME="/opt/zeppelin"
VERSION=0.7.3
ZEP_DL_URL="http://www.apache.org/dyn/closer.cgi/zeppelin/zeppelin-${ZEPPELIN_VER}/zeppelin-${ZEPPELIN_VER}-bin-all.tgz"


#The following mapr packages are installed by default
# mapr-client mapr-posix-client-basic mapr-hbase mapr-asynchbase mapr-spark mapr-hive mapr-kafka mapr-librdkafka
# Install additional client packages as needed, cannot install packages that require mapr-core

#Install zeppelin
mkdir -p $ZEPPELIN_HOME
curl ${DIST_MIRROR}/zeppelin-${VERSION}/zeppelin-${VERSION}-bin-all.tgz | tar xvz -C ${ZEPPELIN_HOME}
mv ${ZEPPELIN_HOME}/zeppelin-${VERSION}-bin-all/* ${ZEPPELIN_HOME}
rm -rf ${ZEPPELIN_HOME}/zeppelin-${VERSION}-bin-all


exit 0



