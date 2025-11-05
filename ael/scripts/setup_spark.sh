#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

# Get the tarballs directory from the argument
TARBALLS_DIR=$1

# Define the Spark version and installation directory
SPARK_VERSION=${SPARK_VERSION:-3.5.4}
SPARK_INSTALL_DIR=/usr/local/spark

# Download Spark
if [ ! -f $TARBALLS_DIR/spark-$SPARK_VERSION-bin-hadoop3.tgz ]; then
    wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.tgz -O $TARBALLS_DIR/spark-$SPARK_VERSION-bin-hadoop3.tgz
fi

# Extract Spark and Move to /usr/local
if [ ! -d $SPARK_INSTALL_DIR ]; then
    tar -xzvf $TARBALLS_DIR/spark-$SPARK_VERSION-bin-hadoop3.tgz
    sudo mv spark-$SPARK_VERSION-bin-hadoop3 $SPARK_INSTALL_DIR
    sudo chown -R $(whoami):$(whoami) $SPARK_INSTALL_DIR
fi

# Remove any guava jar files from the Spark jars directory
if ls $SPARK_INSTALL_DIR/jars/guava-*.jar 1> /dev/null 2>&1; then
    rm -f $SPARK_INSTALL_DIR/jars/guava-*.jar
fi

sed -i '/^## BEGIN AEL_SPARK_ENV/,/^## END AEL_SPARK_ENV/d' ~/.bashrc || true
sed -i '/^## BEGIN AEL_SPARK_ENV/,/^## END AEL_SPARK_ENV/d' ~/.profile || true
cat <<EOS >> ~/.bashrc
## BEGIN AEL_SPARK_ENV
export SPARK_HOME=$SPARK_INSTALL_DIR
export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin
## END AEL_SPARK_ENV
EOS
cat <<EOSP >> ~/.profile
## BEGIN AEL_SPARK_ENV
export SPARK_HOME=$SPARK_INSTALL_DIR
export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin
## END AEL_SPARK_ENV
EOSP

# Export for current shell (non-interactive run)
export SPARK_HOME=$SPARK_INSTALL_DIR
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Configure Spark History Server
SPARK_DEFAULTS_FILE=$SPARK_HOME/conf/spark-defaults.conf
if ! grep -q "spark.eventLog.enabled" $SPARK_DEFAULTS_FILE; then
    mkdir -p /tmp/spark-events
    cat <<EOL >> $SPARK_DEFAULTS_FILE
spark.eventLog.enabled true
spark.eventLog.dir hdfs://localhost:9000/spark-events
spark.history.fs.logDirectory hdfs://localhost:9000/spark-events
EOL
fi

# Start Spark History Server only if not already running
if ! jps | grep -q HistoryServer; then
    $SPARK_HOME/sbin/start-history-server.sh || true
fi

echo "Spark installation and setup complete."
echo "You can 'source ~/.bashrc' to ensure PATH contains Spark bins for new shells."
