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
MAPRJDBC_HOME="/opt/mapr/lib/jdbc"
MAPRJDBC_VERSION="1.5.6.1012"
MAPRJDBC_DL_URL="http://package.mapr.com/tools/MapR-JDBC/MapR_Drill/MapRDrill_jdbc_v${MAPRJDBC_VERSION}/DrillJDBC41.zip"

#Drill
DRILL_HOME="/opt/drill"
DRILL_VERSION="1.11.0"
DRILL_DL_URL="http://archive.apache.org/dist/drill/drill-${DRILL_VERSION}/apache-drill-${DRILL_VERSION}.tar.gz"

#Zeppelin
ZEPPELIN_HOME="/opt/zeppelin"
ZEP_VERSION="0.7.3"
ZEP_DL_URL="http://archive.apache.org/dist/zeppelin/zeppelin-${ZEP_VERSION}/zeppelin-${ZEP_VERSION}-bin-all.tgz"


#The following mapr packages are installed by default
# mapr-client mapr-posix-client-basic mapr-hbase mapr-asynchbase mapr-spark mapr-hive mapr-kafka mapr-librdkafka
# Install additional client packages as needed, cannot install packages that require mapr-core
#cd /tmp
cd /code

#Install MAPR JDBC
echo "Installing MAPR JDBC"
mkdir -p $MAPRJDBC_HOME
#wget -q $MAPRJDBC_DL_URL
unzip DrillJDBC41.zip -d $MAPRJDBC_HOME
rm -f DrillJDBC41.zip

#Install Drill
#echo "Installing Drill JDBC"
mkdir -p $DRILL_HOME/jars/jdbc-driver
mv /code/drill-jdbc-all-1.10.0.jar $DRILL_HOME/jars/jdbc-driver
#curl -sS ${DRILL_DL_URL} | tar xvz -C ${DRILL_HOME}
#mv ${DRILL_HOME}/apache-drill-${DRILL_VERSION}/* ${DRILL_HOME}
#rm -rf ${DRILL_HOME}/apache-drill-${DRILL_VERSION}
#rm -rf *.tgz

#Install zeppelin
echo "Installing Zeppelin"
mkdir -p $ZEPPELIN_HOME
curl -sS ${ZEP_DL_URL} | tar xvz -C ${ZEPPELIN_HOME}
mv ${ZEPPELIN_HOME}/zeppelin-${ZEP_VERSION}-bin-all/* ${ZEPPELIN_HOME}
rm -rf ${ZEPPELIN_HOME}/zeppelin-${ZEP_VERSION}-bin-all
rm -rf *.tgz

mv /code/zeppelin-jdbc-0.7.3.jar ${ZEPPELIN_HOME}/interpreter/jdbc/
cp $MAPRJDBC_HOME/* ${ZEPPELIN_HOME}/interpreter/jdbc/
cp $DRILL_HOME/jars/jdbc-driver/*.jar ${ZEPPELIN_HOME}/interpreter/jdbc/

cp ${ZEPPELIN_HOME}/conf/zeppelin-site.xml.template ${ZEPPELIN_HOME}/conf/zeppelin-site.xml

echo "Adding Zeppelin to start list"

cat $SPRVD_CONF

#if [ -f ${ZEPPELIN_HOME}/bin/zepplin.sh ]; then
cat >> $SPRVD_CONF << EOC

[program:zeppelin]
command=${ZEPPELIN_HOME}/bin/zeppelin.sh
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
EOC

echo "Added Zeppelin to start list"
#fi

cat $SPRVD_CONF

exit 0



