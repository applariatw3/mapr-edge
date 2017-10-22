#!/bin/sh
#mapr edge node dynamic build script
#Log everything in /tmp/build.log
logfile=/tmp/build.log
exec > $logfile 2>&1
set -x

#set environment
SPRVD_CONF=/etc/supervisor/conf.d/maprsvc.conf
MAPR_START_ENV=${MAPR_CONTAINER_DIR}/start-env.sh

#MAPR JDBC
MAPRJDBC_HOME="/opt/mapr"
MAPRJDBC_VERSION="1.5.3.1006"
MAPRJDBC_DL_URL="http://package.mapr.com/tools/MapR-JDBC/MapR_Drill/MapRDrill_jdbc_v${MAPRJDBC_VERSION}/DrillJDBC41.zip"

#Drill
DRILL_HOME="/opt/drill"
DRILL_VERSION="1.10.0"
DRILL_DL_URL="http://www.apache.org/dyn/closer.lua?action=download&filename=drill/drill-${DRILL_VERSION}/apache-drill-${DRILL_VERSION}.tar.gz"

#Zeppelin
ZEPPELIN_HOME="/opt/zeppelin"
ZEP_VERSION="0.7.3"
ZEP_DL_URL="http://archive.apache.org/dist/zeppelin/zeppelin-${ZEP_VERSION}/zeppelin-${ZEP_VERSION}-bin-all.tgz"


#The following mapr packages are installed by default
# mapr-client mapr-posix-client-basic mapr-hbase mapr-asynchbase mapr-spark mapr-hive mapr-kafka mapr-librdkafka
# Install additional client packages as needed, cannot install packages that require mapr-core

#Install zeppelin
mkdir -p $ZEPPELIN_HOME
curl ${ZEP_DL_URL} | tar xvz -C ${ZEPPELIN_HOME}
mv ${ZEPPELIN_HOME}/zeppelin-${ZEP_VERSION}-bin-all/* ${ZEPPELIN_HOME}
rm -rf ${ZEPPELIN_HOME}/zeppelin-${VERSION}-bin-all
rm -rf *.tgz

exit 0



