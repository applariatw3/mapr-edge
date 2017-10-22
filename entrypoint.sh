#!/bin/sh
#mapr client entrypoint script
echo "Output from build process"
cat /tmp/build.log
echo "End of build log"

echo "Starting MAPR Edge Node as ${POD_NAME} from /entrypoint.sh"

set -e
#set environment from inputs
MAPR_CLUSTER=${MAPR_CLUSTER:?Missing required MAPR cluster name}
MAPR_CLDB_HOSTS=${MAPR_CLDB_HOSTS:?Missing required MAPR CLDB hosts}

set +e

MAPR_MCS=${MAPR_MCS:-mapr-cldb}
MAPR_MCS_PORT=${MAPR_MCS_PORT:-8443}
MAPR_SECURITY=${MAPR_SECURITY:-disabled}
MAPR_MEMORY=${NODE_MEMORY:-0}
#Mapr Admin User
MAPR_ADMIN=${MAPR_ADMIN:-mapr}
MAPR_ADMIN_UID=${MAPR_ADMIN_UID:-5000}
MAPR_ADMIN_GROUP=${MAPR_ADMIN_GROUP:-mapr}
MAPR_ADMIN_GID=${MAPR_ADMIN_GID:-5000}
MAPR_ADMIN_PASSWORD=${MAPR_ADMIN_PASSWORD:-mapr522301}


#export path
export PATH=$JAVA_HOME/bin:$MAPR_HOME/bin:$PATH
export CLASSPATH=$CLASSPATH
#export MAPR_CLASSPATH=$MAPR_CLASSPATH

#internal environment
MAPR_CLUSTER_CONF="$MAPR_HOME/conf/mapr-clusters.conf"
MAPR_CONFIGURE_SCRIPT="$MAPR_HOME/server/configure.sh"
MAPR_FUSE_FILE="$MAPR_HOME/conf/fuse.conf"

#used for startup
MAPR_START_ENV=${MAPR_CONTAINER_DIR}/start-env.sh
MAPR_START=${MAPR_CONTAINER_DIR}/start-mapr.sh
CLUSTER_INFO_DIR=/user/mapr/$MAPR_CLUSTER

source $MAPR_START_ENV

#Configure default environment script
echo "#!/bin/bash" > $MAPR_ENV_FILE
echo "export JAVA_HOME=\"$JAVA_HOME\"" >> $MAPR_ENV_FILE
echo "export MAPR_CLUSTER=\"$MAPR_CLUSTER\"" >> $MAPR_ENV_FILE
echo "export MAPR_HOME=\"$MAPR_HOME\"" >> $MAPR_ENV_FILE
[ -f "$MAPR_HOME/bin/mapr" ] && echo "export MAPR_CLASSPATH=\"\$($MAPR_HOME/bin/mapr classpath)\"" >> $MAPR_ENV_FILE
[ -n "$MAPR_MOUNT_PATH" ] && echo "export MAPR_MOUNT_PATH=\"$MAPR_MOUNT_PATH\"" >> $MAPR_ENV_FILE
if [ -n "$MAPR_TICKETFILE_LOCATION" ]; then
	local ticket="export MAPR_TICKETFILE_LOCATION=$MAPR_TICKETFILE_LOCATION"

	echo "$ticket" >> /etc/environment
	echo "$ticket" >> $MAPR_ENV_FILE
	sed -i -e "s|MAPR_TICKETFILE_LOCATION=.*|MAPR_TICKETFILE_LOCATION=$MAPR_TICKETFILE_LOCATION|" \
		"$MAPR_HOME/initscripts/$MAPR_PACKAGE_POSIX"
fi
echo "export PATH=\"\$JAVA_HOME:\$PATH:\$MAPR_HOME/bin\"" >> $MAPR_ENV_FILE

#Create the mapr admin user
if id $MAPR_ADMIN >/dev/null 2>&1; then
	echo "Mapr admin user already exists"
else
	$MAPR_CONTAINER_DIR/mapr-create-user.sh $MAPR_ADMIN $MAPR_ADMIN_UID $MAPR_ADMIN_GROUP $MAPR_ADMIN_GID $MAPR_ADMIN_PASSWORD
fi

#configure sshd
if [ ! -d /var/run/sshd ]; then
	mkdir /var/run/sshd
	echo "root:$MAPR_ADMIN_PASSWORD" | chpasswd

	rm -f /run/nologin
	if [ -f /etc/ssh/sshd_config ]; then
		sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
		sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
		sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
		sed -i 's/^ChallengeResponseAuthentication no$/ChallengeResponseAuthentication yes/g' \
			/etc/ssh/sshd_config || echo "Could not enable ChallengeResponseAuthentication"
		echo "ChallengeResponseAuthentication enabled"
	fi

	# SSH login fix. Otherwise user is kicked off after login
	sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
fi

#set memory for container
if [ "$MAPR_ORCHESTRATOR" = "k8s" -a $MAPR_MEMORY -ne 0 ]; then
	mem_file="$MAPR_HOME/conf/container_meminfo"
	mem_char=$(echo "$MAPR_MEMORY" | grep -o -E '[kmgKMG]')
	mem_number=$(echo "$MAPR_MEMORY" | grep -o -E '[0-9]+')

	echo "Seting MapR container memory limits..."
	[ ${#mem_number} -eq 0 ] && echo "Empty memory allocation, using default 2G" && mem_number=2
	[ ${#mem_char} -gt 1 ] && echo "Invalid memory allocation: using default 2G" && mem_char=G
	[ $mem_number == "0" ] && echo "Can't use zero, using default 2gG && mem_number=2" && mem_number=2

	case "$mem_char" in
		g|G) mem_total=$(($mem_number * 1024 * 1024)) ;;
		m|M) mem_total=$(($mem_number * 1024)) ;;
		k|K) mem_total=$(($mem_number)) ;;
	esac
	cp -f -v /proc/meminfo $mem_file
	chown $MAPR_CLIENT_USER:$MAPR_GROUP $mem_file
	chmod 644 $mem_file
	sed -i "s!/proc/meminfo!${mem_file}!" "$MAPR_HOME/server/initscripts-common.sh" || \
		echo "Could not edit initscripts-common.sh"
	sed -i "/^MemTotal/ s/^.*$/MemTotal:     $mem_total kB/" "$mem_file" || \
		echo "Could not edit meminfo MemTotal"
	sed -i "/^MemFree/ s/^.*$/MemFree:     $mem_total kB/" "$mem_file" || \
		echo "Could not edit meminfo MemFree"
	sed -i "/^MemAvailable/ s/^.*$/MemAvailable:     $mem_total kB/" "$mem_file" || \
		echo "Could not edit meminfo MemAvailable"
fi
	

#Set variables MAPR_HOME, JAVA_HOME, [ MAPR_SUBNETS (if set)] in conf/env.sh
env_file="$MAPR_HOME/conf/env.sh"
sed -i "s:^#export JAVA_HOME.*:export JAVA_HOME=${JAVA_HOME}:" "$env_file" || \
	echo "Could not edit JAVA_HOME in $env_file"
sed -i "s:^#export MAPR_HOME.*:export MAPR_HOME=${MAPR_HOME}:" "$env_file" || \
	echo "Could not edit MAPR_HOME in $env_file"
if [ -n "$MAPR_SUBNETS" ]; then
	sed -i "s:^#export MAPR_SUBNETS.*:export MAPR_SUBNETS=${MAPR_SUBNETS}:" "$env_file" || \
		echo "Could not edit MAPR_SUBNETS in $env_file"
fi

#Confirm cluster services are ready
cycles=0
check_cldb=1
until $(curl --output /dev/null -Iskf https://${MAPR_MCS}:${MAPR_MCS_PORT}); do
	echo "Waiting for MCS to start..."
	if [ $cycles -le 10 ]; then
		sleep 60
	else
		echo "Cluster not responding after 10 minutes...continuing"
		check_cldb=0
		break
	fi
	let cycles+=1
done

find_cldb="curl -sSk -u mapr:$MAPR_ADMIN_PASSWORD https://${MAPR_MCS}:${MAPR_MCS_PORT}/rest/node/cldbmaster"
if [ $check_cldb -eq 1 ]; then
	until [ "$($find_cldb | jq -r '.status')" = "OK" ]; do
		echo "Waiting for cldb host validation..."
	done
	
	echo "Ready to configure client for $MAPR_CLUSTER with $MAPR_CLDB_HOSTS"
fi

#configure mapr services
if [ -f "$MAPR_CLUSTER_CONF" ]; then
	args=-R
	args="$args -v"
	echo "Re-configuring MapR client ($args)..."
	$MAPR_CONFIGURE_SCRIPT $args
else
	. $MAPR_HOME/conf/env.sh
	args="$args -c -on-prompt-cont y -N $MAPR_CLUSTER -C $MAPR_CLDB_HOSTS"
	[ -n "$MAPR_TICKETFILE_LOCATION" ] && args="$args -secure"
	[ -n "$MAPR_RM_HOSTS" ] && args="$args -RM $MAPR_RM_HOSTS"
	[ -n "$MAPR_HS_HOST" ] && args="$args -HS $MAPR_HS_HOST"
	[ -n "$MAPR_OT_HOSTS" ] && args="$args -OT $MAPR_OT_HOSTS"
	[ -n "$MAPR_ES_HOSTS" ] && args="$args -ES $MAPR_ES_HOSTS"
	args="$args -v"
	echo "Configuring MapR client ($args)..."
	$MAPR_CONFIGURE_SCRIPT $args
fi

#Before starting the services, make sure some file permissions are set correctly
chown -R $MAPR_ADMIN:$MAPR_ADMIN_GROUP "$MAPR_HOME"
chown -fR root:root "$MAPR_HOME/conf/proxy"

#Configure Hive
if [ -d ${MAPR_HOME}/hive ]; then
	echo "export HIVE_HOME=\"${MAPR_HOME}/hive/hive-${ver}\"" >> $MAPR_ENV_FILE
	echo "export PATH=\"\$PATH:\$HIVE_HOME/bin\"" >> $MAPR_ENV_FILE
fi

#Start Services
#Starting Fuse
#if [ -n "$MAPR_MOUNT_PATH" -a -f "$MAPR_FUSE_FILE" ]; then
#	if $(hadoop fs -test -d $MAPR_MOUNT_PATH); then
#		echo "$MAPR_MOUNT_PATH directory exists in MAPR-FS"
#	else
#		echo "Creating $MAPR_MOUNT_PATH on MAPR-FS"
#		hadoop fs -mkdir $MAPR_MOUNT_PATH
#		hadoop fs -chmod 777 $MAPR_MOUNT_PATH
#	fi
#	echo "Starting Fuse Client with $MAPR_MOUNT_PATH"
#	sed -i "s|^fuse.mount.point.*$|fuse.mount.point=$MAPR_MOUNT_PATH|g" \
#		$MAPR_FUSE_FILE || echo "Could not set FUSE mount path"
#	mkdir -p -m 755 "$MAPR_MOUNT_PATH"
#	service mapr-posix-client-basic start
#fi

#create log directories for supervisor
mkdir -p /var/log/supervisor
chmod 777 /var/log/supervisor

if [ $# -eq 0 ]; then
	exec /usr/sbin/sshd -D
elif [ "$1" = "/usr/sbin/sshd" ]; then
	exec "$@"
else
	echo "Starting edge node with command: $@"
	exec "$@"
fi