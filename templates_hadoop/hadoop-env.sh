export JAVA_HOME=/usr/lib/jvm/java-8-oracle

export COMMON_BIN_DIR="/edx/bin"
export HADOOP_COMMON_HOME=/edx/app/hadoop/hadoop
export HADOOP_MAPRED_HOME=/edx/app/hadoop/hadoop
export HADOOP_HDFS_HOME=/edx/app/hadoop/hadoop
export YARN_HOME=/edx/app/hadoop/hadoop
export HADOOP_CONF_DIR=/edx/app/hadoop/hadoop/etc/hadoop
export HADOOP_COMMON_TOOL_HEAP_MAX="128"
export HADOOP_COMMON_SERVICE_HEAP_MAX="256"
export YARN_HEAPSIZE="$HADOOP_COMMON_SERVICE_HEAP_MAX"


export PATH=$PATH:$HADOOP_COMMON_HOME/bin:$HADOOP_COMMON_HOME/sbin:$COMMON_BIN_DIR

# Extra Java CLASSPATH elements.  Automatically insert capacity-scheduler.
for f in $HADOOP_HOME/contrib/capacity-scheduler/*.jar; do
  if [ "$HADOOP_CLASSPATH" ]; then
    export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$f
  else
    export HADOOP_CLASSPATH=$f
  fi
done

# Extra Java runtime options.  Empty by default.
export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"

# Command specific options appended to HADOOP_OPTS when specified
export HADOOP_NAMENODE_OPTS="-Xmx${HADOOP_COMMON_SERVICE_HEAP_MAX}m -Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_NAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Xmx${HADOOP_COMMON_SERVICE_HEAP_MAX}m -Dhadoop.security.logger=ERROR,RFAS $HADOOP_DATANODE_OPTS"

export HADOOP_SECONDARYNAMENODE_OPTS="-Xmx${HADOOP_COMMON_SERVICE_HEAP_MAX}m -Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_SECONDARYNAMENODE_OPTS"

# The following applies to multiple commands (fs, dfs, fsck, distcp etc)
export HADOOP_CLIENT_OPTS="-Xmx${HADOOP_COMMON_TOOL_HEAP_MAX}m $HADOOP_CLIENT_OPTS"

# The directory where pid files are stored. /tmp by default.
# NOTE: this should be set to a directory that can only be written to by
#       the user that will run the hadoop daemons.  Otherwise there is the
#       potential for a symlink attack.
export HADOOP_PID_DIR=${HADOOP_PID_DIR}

# A string representing this instance of hadoop. $USER by default.
export HADOOP_IDENT_STRING=$USER