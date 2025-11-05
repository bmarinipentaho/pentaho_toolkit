#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

# Get the tarballs directory from the argument
TARBALLS_DIR=$1

# Define the Hadoop version and installation directory
HADOOP_VERSION=${HADOOP_VERSION:-3.4.1}
HADOOP_INSTALL_DIR=/usr/local/hadoop

# Download Hadoop
if [ ! -f $TARBALLS_DIR/hadoop-$HADOOP_VERSION.tar.gz ]; then
    wget https://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz -O $TARBALLS_DIR/hadoop-$HADOOP_VERSION.tar.gz
fi

# Extract Hadoop and Move to /usr/local
if [ ! -d $HADOOP_INSTALL_DIR ]; then
    tar -xzvf $TARBALLS_DIR/hadoop-$HADOOP_VERSION.tar.gz
    sudo mv hadoop-$HADOOP_VERSION $HADOOP_INSTALL_DIR
    sudo chown -R $(whoami):$(whoami) $HADOOP_INSTALL_DIR
fi

JAVA_HOME_DETECTED=$(readlink -f /usr/bin/java | sed "s:bin/java::")
HDFS_CMD="hadoop fs"

if [ -n "$HADOOP_INSTALL_DIR" ]; then
    # Remove any existing blocks
    sed -i '/^## BEGIN AEL_HADOOP_ENV/,/^## END AEL_HADOOP_ENV/d' ~/.bashrc || true
    sed -i '/^## BEGIN AEL_HADOOP_ENV/,/^## END AEL_HADOOP_ENV/d' ~/.profile || true
    # Append to .bashrc
    cat <<EOB >> ~/.bashrc
## BEGIN AEL_HADOOP_ENV
export JAVA_HOME=$JAVA_HOME_DETECTED
export HADOOP_HOME=$HADOOP_INSTALL_DIR
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
## END AEL_HADOOP_ENV
EOB
    # Append to .profile for login shells
    cat <<EOP >> ~/.profile
## BEGIN AEL_HADOOP_ENV
export JAVA_HOME=$JAVA_HOME_DETECTED
export HADOOP_HOME=$HADOOP_INSTALL_DIR
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
## END AEL_HADOOP_ENV
EOP
fi

# Export into current (non-interactive) shell explicitly (sourcing .bashrc may early-return)
export JAVA_HOME=$JAVA_HOME_DETECTED
export HADOOP_HOME=$HADOOP_INSTALL_DIR
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin

# Configure Hadoop
HADOOP_ENV_FILE=$HADOOP_HOME/etc/hadoop/hadoop-env.sh
if ! grep -q "^export JAVA_HOME=" $HADOOP_ENV_FILE; then
    sed -i "s|^#export JAVA_HOME=.*|export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')|" $HADOOP_ENV_FILE
    echo "export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')" >> $HADOOP_ENV_FILE
fi

# Configure core-site.xml
CORE_SITE_FILE=$HADOOP_HOME/etc/hadoop/core-site.xml
if ! grep -q "<name>fs.defaultFS</name>" $CORE_SITE_FILE; then
    cat <<EOL > $CORE_SITE_FILE
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOL
fi

# Configure hdfs-site.xml
HDFS_SITE_FILE=$HADOOP_HOME/etc/hadoop/hdfs-site.xml
if ! grep -q "<name>dfs.replication</name>" $HDFS_SITE_FILE; then
    cat <<EOL > $HDFS_SITE_FILE
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOL
fi

 # Format the Hadoop filesystem (only first time)
if [ ! -d /tmp/hadoop-$(whoami)/dfs/name ]; then
    hdfs namenode -format -force || hdfs namenode -format
fi

# Stop Hadoop services if running
stop-dfs.sh

# Check for running Hadoop services and kill them if necessary
for service in NameNode DataNode SecondaryNameNode ResourceManager NodeManager; do
    pid=$(jps | grep $service | awk '{print $1}')
    if [ -n "$pid" ]; then
        echo "Stopping $service with PID $pid"
        kill -9 $pid
    fi
done

# Start Hadoop services (DFS + YARN)
start-dfs.sh
start-yarn.sh

# Create spark-events directory in HDFS (generic FS call)
$HDFS_CMD -mkdir -p /spark-events || true

echo "Hadoop installation and setup complete."
echo "Source ~/.bashrc or start a login shell to load HADOOP env."
