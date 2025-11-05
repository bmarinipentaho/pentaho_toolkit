#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

# Define the paths to the scripts
INSTALL_JAVA_SCRIPT="./scripts/setup_java_and_ssh.sh"
INSTALL_HADOOP_SCRIPT="./scripts/setup_hadoop.sh"
INSTALL_SPARK_SCRIPT="./scripts/setup_spark.sh"
INSTALL_LIBWEBKIT_SCRIPT="./scripts/setup_libwebkit.sh"
DEPLOY_AEL_SCRIPT="./scripts/setup_ael.sh"

# Create a folder for tarballs
TARBALLS_DIR="./tarballs"
mkdir -p $TARBALLS_DIR

# Default versions
HADOOP_VERSION=3.4.1
SPARK_VERSION=4.0.0
# Default modes
YARN_MODE=0
INSTALL_LIBWEBKIT=0

# Parse flags for versions and yarn mode
while [[ "$1" == --* ]]; do
    case "$1" in
        --hadoop-version)
            HADOOP_VERSION="$2"
            shift 2
            ;;
        --spark-version)
            SPARK_VERSION="$2"
            shift 2
            ;;
        --yarn-mode)
            YARN_MODE=1
            shift
            ;;
        --install-libwebkit)
            INSTALL_LIBWEBKIT=1
            shift
            ;;
        -h|--help)
            echo "Usage:"
            echo "  $0 [--hadoop-version <ver>] [--spark-version <ver>] [--yarn-mode] [--install-libwebkit] <jfrog-api-key>"
            echo "      Deploy using a JFrog API key (downloads latest artifacts automatically)."
            echo "  $0 [--hadoop-version <ver>] [--spark-version <ver>] [--yarn-mode] [--install-libwebkit] <unpacked-folder>"
            echo "      Deploy from a local, unpacked AEL folder."
            echo "  $0 [--hadoop-version <ver>] [--spark-version <ver>] [--yarn-mode] [--install-libwebkit] <local-zip1> <local-zip2>"
            echo "      Deploy from two local zip files (unzipped into the same folder)."
            echo "  $0 [--hadoop-version <ver>] [--spark-version <ver>] [--yarn-mode] [--install-libwebkit] <zip-url1> <zip-url2> <api-key>"
            echo "      Deploy from two zip URLs (downloaded with API key and unzipped into the same folder)."
            echo ""
            echo "Flags:"
            echo "  --install-libwebkit  Install libwebkit packages required for PDI client compatibility"
            exit 0
            ;;
        *)
            echo "Unknown flag: $1"
            exit 1
            ;;
    esac
done

# Accept PDI_EE_CLIENT_ZIP_URL, SPARK_EXECUTION_ADDON_ZIP, and API_KEY parameters from the command line
PDI_EE_CLIENT_ZIP_URL=$1
SPARK_EXECUTION_ADDON_ZIP=$2
API_KEY=$3

# Check if the Java install script exists
if [ ! -f $INSTALL_JAVA_SCRIPT ]; then
    echo "Error: Java install script not found at $INSTALL_JAVA_SCRIPT"
    exit 1
fi

# Check if the Hadoop install script exists
if [ ! -f $INSTALL_HADOOP_SCRIPT ]; then
    echo "Error: Hadoop install script not found at $INSTALL_HADOOP_SCRIPT"
    exit 1
fi

# Check if the Spark install script exists
if [ ! -f $INSTALL_SPARK_SCRIPT ]; then
    echo "Error: Spark install script not found at $INSTALL_SPARK_SCRIPT"
    exit 1
fi

# Check if the AEL deployment script exists
if [ ! -f $DEPLOY_AEL_SCRIPT ]; then
    echo "Error: AEL deployment script not found at $DEPLOY_AEL_SCRIPT"
    exit 1
fi

# Execute the Java install script
echo "Verifying/Installing Java (script handles JDK 21)..."
bash $INSTALL_JAVA_SCRIPT

# Optionally install libwebkit packages for PDI client compatibility
if [[ "$INSTALL_LIBWEBKIT" == "1" ]]; then
    echo "Installing libwebkit packages for PDI compatibility..."
    if [ -f $INSTALL_LIBWEBKIT_SCRIPT ]; then
        bash $INSTALL_LIBWEBKIT_SCRIPT
    else
        echo "Warning: libwebkit install script not found at $INSTALL_LIBWEBKIT_SCRIPT"
        echo "Skipping libwebkit installation."
    fi
fi

echo "Executing Hadoop install script..."
HADOOP_VERSION="$HADOOP_VERSION" bash $INSTALL_HADOOP_SCRIPT $TARBALLS_DIR

echo "Executing Spark install script..."
SPARK_VERSION="$SPARK_VERSION" bash $INSTALL_SPARK_SCRIPT $TARBALLS_DIR

# Source ~/.bashrc to pull in the newly added env blocks (in case subsequent scripts rely on them)
if [ -f ~/.bashrc ]; then
    set +x
    source ~/.bashrc
    set -x
fi

# Ensure Hadoop and Spark binaries available in current shell (non-interactive shells may not source profiles)
# Defensive exports (if source didn't work for non-interactive shell)
if [ -d /usr/local/hadoop ] && ! echo "$PATH" | grep -q "/usr/local/hadoop/bin"; then
    export HADOOP_HOME=/usr/local/hadoop
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
fi
if [ -d /usr/local/spark ] && ! echo "$PATH" | grep -q "/usr/local/spark/bin"; then
    export SPARK_HOME=/usr/local/spark
    export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
fi

# Execute the AEL deployment script with the parameters and yarn mode
echo "Executing AEL deployment script..."
bash $DEPLOY_AEL_SCRIPT "$PDI_EE_CLIENT_ZIP_URL" "$SPARK_EXECUTION_ADDON_ZIP" "$API_KEY" $YARN_MODE

echo "All scripts executed successfully."
