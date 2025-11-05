#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
DEPLOYMENT_DIR=~/ael_deployment

ARG1=$1
ARG2=$2
ARG3=$3
YARN_MODE=${4:-0}

# Artifactory repo and paths
ARTIFACTORY_URL="https://one.hitachivantara.com/artifactory"
PDI_EE_CLIENT_PATH="pntprv-maven-snapshot-custom7/com/pentaho/di/pdi-ee-client/11.0.0.0-SNAPSHOT"
SPARK_EXEC_ADDON_PATH="pntprv-maven-snapshot-custom7/com/pentaho/di/engine/spark/pdi-ee-client-spark-execution-addon/11.0.0.0-SNAPSHOT"

# Function to generate application.properties files
generate_app_properties() {
    local APPLICATION_PROPERTIES_FILE="$1"
    local YARN_MODE="$2"
    local SCRIPT_DIR="$3"

    HADOOP_CONF_DIR=$(realpath $HADOOP_HOME/etc/hadoop)
    SPARK_HOME_DIR=$(realpath $SPARK_HOME)
    SPARK_APP_DIR=$(realpath $AEL_HOME/data-integration/)

    cp "$APPLICATION_PROPERTIES_FILE" "$APPLICATION_PROPERTIES_FILE.local"

    sed -i "s|^hadoopConfDir=.*|hadoopConfDir=$HADOOP_CONF_DIR|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^hadoopUser=.*|hadoopUser=devuser|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^hbaseConfDir=.*|hbaseConfDir=$HADOOP_CONF_DIR|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^sparkHome=.*|sparkHome=$SPARK_HOME_DIR|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^sparkMaster=.*|sparkMaster=local[2]|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^sparkApp=.*|sparkApp=$SPARK_APP_DIR|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^assemblyZip=.*|assemblyZip=hdfs:/user/devuser/pdi-spark-executor.zip|" "$APPLICATION_PROPERTIES_FILE.local"
    sed -i "s|^logging.level.org=.*|logging.level.org=DEBUG|" "$APPLICATION_PROPERTIES_FILE.local"
    if ! grep -q "^sparkEventLogDir=" "$APPLICATION_PROPERTIES_FILE.local"; then
        echo "sparkEventLogDir=hdfs:///spark-events" >> "$APPLICATION_PROPERTIES_FILE.local"
    else
        sed -i "s|^sparkEventLogDir=.*|sparkEventLogDir=hdfs:///spark-events|" "$APPLICATION_PROPERTIES_FILE.local"
    fi

    # Always create YARN variant as well for easy switching
    cp "$APPLICATION_PROPERTIES_FILE.local" "$APPLICATION_PROPERTIES_FILE.yarn"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"
    HADOOP_SITE_DIR="$PROJECT_ROOT/siteFiles/hadoop"
    HBASE_SITE_DIR="$PROJECT_ROOT/siteFiles/hbase"
    sed -i "s|^websocketURL=.*|websocketURL=ws://$IP_ADDR:\${ael.unencrypted.port}|" "$APPLICATION_PROPERTIES_FILE.yarn"
    sed -i "s|^sparkMaster=.*|sparkMaster=yarn|" "$APPLICATION_PROPERTIES_FILE.yarn"
    sed -i "s|^sparkDeployMode=.*|sparkDeployMode=client|" "$APPLICATION_PROPERTIES_FILE.yarn"
    sed -i "s|^hadoopConfDir=.*|hadoopConfDir=$HADOOP_SITE_DIR|" "$APPLICATION_PROPERTIES_FILE.yarn"
    sed -i "s|^hbaseConfDir=.*|hbaseConfDir=$HBASE_SITE_DIR|" "$APPLICATION_PROPERTIES_FILE.yarn"
    sed -i "s|^assemblyZip=.*|assemblyZip=|" "$APPLICATION_PROPERTIES_FILE.yarn"

    # Copy the selected mode to active configuration
    if [[ "$YARN_MODE" == "1" ]]; then
        cp "$APPLICATION_PROPERTIES_FILE.yarn" "$APPLICATION_PROPERTIES_FILE"
        echo "Active config set to YARN mode (backup configs: .local and .yarn)"
    else
        cp "$APPLICATION_PROPERTIES_FILE.local" "$APPLICATION_PROPERTIES_FILE"
        echo "Active config set to LOCAL mode (backup configs: .local and .yarn)"
    fi
}

REGEN_ONLY=0
for arg in "$@"; do
    if [[ "$arg" == "--regen-app-props" ]]; then
        REGEN_ONLY=1
        break
    fi
done

if [[ "$REGEN_ONLY" == "1" ]]; then
    # Only regenerate application.properties files, skip artifact handling
    if [[ -z "$AEL_HOME" ]]; then
        echo "AEL_HOME is not set. Please set it or run the full setup at least once."
        exit 1
    fi
    APPLICATION_PROPERTIES_FILE=$AEL_HOME/data-integration/spark-execution-daemon/config/application.properties
    generate_app_properties "$APPLICATION_PROPERTIES_FILE" "1" "$SCRIPT_DIR"
    echo "application.properties files regenerated. set .yarn version as default."
    exit 0
fi

# Clear out the deployment directory if it exists
if [ -d $DEPLOYMENT_DIR ]; then
    rm -rf $DEPLOYMENT_DIR
fi
mkdir -p $DEPLOYMENT_DIR
cd $DEPLOYMENT_DIR

if [[ -n "$ARG1" && -n "$ARG2" && -n "$ARG3" ]]; then
    # 3 args: two zip URLs + API key
    PDI_EE_CLIENT_ZIP_URL="$ARG1"
    SPARK_EXECUTION_ADDON_ZIP_URL="$ARG2"
    API_KEY="$ARG3"
    wget --header="X-JFrog-Art-Api: $API_KEY" "$PDI_EE_CLIENT_ZIP_URL" -O pdi-client-ee.zip
    wget --header="X-JFrog-Art-Api: $API_KEY" "$SPARK_EXECUTION_ADDON_ZIP_URL" -O spark-execution-addon.zip
    ARCHIVE_NAME="ael_combined"
    EXTRACTED_DIR="$DEPLOYMENT_DIR/$ARCHIVE_NAME"
    mkdir -p "$EXTRACTED_DIR"
    unzip pdi-client-ee.zip -d "$EXTRACTED_DIR"
    unzip -o spark-execution-addon.zip -d "$EXTRACTED_DIR"
elif [[ -n "$ARG1" && -n "$ARG2" && -z "$ARG3" ]]; then
    # 2 args: two local zip files
    LOCAL_ZIP1="$ARG1"
    LOCAL_ZIP2="$ARG2"
    ARCHIVE_NAME="ael_combined"
    EXTRACTED_DIR="$DEPLOYMENT_DIR/$ARCHIVE_NAME"
    mkdir -p "$EXTRACTED_DIR"
    cp "$LOCAL_ZIP1" pdi-client-ee.zip
    cp "$LOCAL_ZIP2" spark-execution-addon.zip
    unzip pdi-client-ee.zip -d "$EXTRACTED_DIR"
    unzip -o spark-execution-addon.zip -d "$EXTRACTED_DIR"
elif [[ -n "$ARG1" && -z "$ARG2" && -z "$ARG3" ]]; then
    # 1 arg: could be local, unpacked folder or API key
    INPUT="$ARG1"
    if [[ -d "$INPUT" ]]; then
        ARCHIVE_NAME=$(basename "$INPUT")
        EXTRACTED_DIR="$DEPLOYMENT_DIR/$ARCHIVE_NAME"
        cp -r "$INPUT" "$EXTRACTED_DIR"
    else
        # Try API key flow by pinging Artifactory
        API_KEY="$INPUT"
        if curl -sf -H "X-JFrog-Art-Api: $API_KEY" "$ARTIFACTORY_URL/api/system/ping" >/dev/null; then
            ARCHIVE_NAME="ael_combined"
            EXTRACTED_DIR="$DEPLOYMENT_DIR/$ARCHIVE_NAME"
            mkdir -p "$EXTRACTED_DIR"

            # Get latest PDI EE Client zip
            PDI_EE_CLIENT_JSON=$(curl -s -H "X-JFrog-Art-Api: $API_KEY" "$ARTIFACTORY_URL/api/storage/$PDI_EE_CLIENT_PATH")
            PDI_EE_CLIENT_ZIP=$(echo "$PDI_EE_CLIENT_JSON" | grep -oP 'pdi-ee-client-11\.0\.0\.0-[^"]+\.zip' | sort | tail -n 1)
            PDI_EE_CLIENT_ZIP_URL="$ARTIFACTORY_URL/$PDI_EE_CLIENT_PATH/$PDI_EE_CLIENT_ZIP"

            # Get latest Spark Execution Addon zip
            SPARK_EXEC_ADDON_JSON=$(curl -s -H "X-JFrog-Art-Api: $API_KEY" "$ARTIFACTORY_URL/api/storage/$SPARK_EXEC_ADDON_PATH")
            SPARK_EXEC_ADDON_ZIP=$(echo "$SPARK_EXEC_ADDON_JSON" | grep -oP 'pdi-ee-client-spark-execution-addon-11\.0\.0\.0-[^"]+\.zip' | sort | tail -n 1)
            SPARK_EXEC_ADDON_ZIP_URL="$ARTIFACTORY_URL/$SPARK_EXEC_ADDON_PATH/$SPARK_EXEC_ADDON_ZIP"

            # Download both artifacts
            wget --header="X-JFrog-Art-Api: $API_KEY" "$PDI_EE_CLIENT_ZIP_URL" -O pdi-client-ee.zip
            wget --header="X-JFrog-Art-Api: $API_KEY" "$SPARK_EXEC_ADDON_ZIP_URL" -O spark-execution-addon.zip

            # Unzip both into the same folder
            unzip pdi-client-ee.zip -d "$EXTRACTED_DIR"
            unzip -o spark-execution-addon.zip -d "$EXTRACTED_DIR"
        else
            echo "Error: Argument is not a directory and does not appear to be a valid JFrog API key."
            exit 1
        fi
    fi
else
    echo "Usage:"
    echo "  $0 --regen-app-props"
    echo "  $0 <jfrog-api-key>"
    echo "  $0 <unpacked-folder>"
    echo "  $0 <local-zip1> <local-zip2>"
    echo "  $0 <zip-url1> <zip-url2> <api-key>"
    exit 1
fi

# Ensure all scripts in the deployment directory are executable
find "$EXTRACTED_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Change to the data-integration directory and run spark-app-builder.sh
cd "$EXTRACTED_DIR/data-integration"
./spark-app-builder.sh

# Copy pdi-spark-driver.zip to the AEL folder in the deployment directory
mkdir -p $DEPLOYMENT_DIR/AEL
cp pdi-spark-driver.zip $DEPLOYMENT_DIR/AEL/

# Set the AEL_HOME environment variable
export AEL_HOME=$DEPLOYMENT_DIR/AEL

# Update .bashrc with the AEL_HOME variable
if grep -q "export AEL_HOME=" ~/.bashrc; then
    sed -i "s|^export AEL_HOME=.*|export AEL_HOME=$AEL_HOME|" ~/.bashrc
else
    echo "export AEL_HOME=$AEL_HOME" >> ~/.bashrc
fi

# Source the updated .bashrc
source ~/.bashrc

# Verify the AEL_HOME environment variable
echo "AEL_HOME: $AEL_HOME"

# Change to AEL_HOME and extract pdi-spark-driver.zip
cd $AEL_HOME
unzip pdi-spark-driver.zip

# Make an HDFS folder at /user/devuser if it does not exist
hdfs dfs -mkdir -p /user/devuser

# Overwrite pdi-spark-executor.zip in HDFS
hdfs dfs -put -f pdi-spark-executor.zip /user/devuser/

# Set the application.properties file path and generate it
APPLICATION_PROPERTIES_FILE=$AEL_HOME/data-integration/spark-execution-daemon/config/application.properties
generate_app_properties "$APPLICATION_PROPERTIES_FILE" "$YARN_MODE" "$SCRIPT_DIR"

# Change to the adaptive-execution directory
cd $AEL_HOME/data-integration/spark-execution-daemon

echo "AEL installation and setup complete."

if [[ "$YARN_MODE" == "1" ]]; then
    echo ""
    echo "IMPORTANT REMINDER:"
    echo "application.properties has been set for the hoth team YARN cluster."
    echo "You must upload the generated pdi-spark-executor.zip to the YARN cluster's HDFS instance."
    echo "Then set the 'assemblyZip' property in:"
    echo "  $APPLICATION_PROPERTIES_FILE"
    echo "to the correct HDFS path for your uploaded pdi-spark-executor.zip."
    echo ""
    echo "Example command:"
    echo "  sed -i 's|^assemblyZip=.*|assemblyZip=hdfs://<namenode-host>:<port>/path/to/pdi-spark-executor.zip|' $APPLICATION_PROPERTIES_FILE"
    echo ""
    echo "The generated pdi-spark-executor.zip is located at: $AEL_HOME/pdi-spark-executor.zip"
    echo ""
else
    echo "Starting daemon..."
    ./daemon.sh start
fi
