#!/bin/bash
# switch-java.sh
# Usage: ./switch-java.sh <version>
# Example: ./switch-java.sh 17
# This script switches both java and javac to the specified version (8, 17, or 21)

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 17"
  exit 1
fi

VERSION=$1

case $VERSION in
  8)
    JAVA_PATH="/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"
    JAVAC_PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin/javac"
    ;;
  17)
    JAVA_PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
    JAVAC_PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin/javac"
    ;;
  21)
    JAVA_PATH="/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
    JAVAC_PATH="/usr/lib/jvm/java-21-openjdk-amd64/bin/javac"
    ;;
  *)
    echo "Unsupported version: $VERSION"
    echo "Supported versions: 8, 17, 21"
    exit 1
    ;;
esac

echo "Switching java to $JAVA_PATH"
sudo update-alternatives --set java "$JAVA_PATH"
echo "Switching javac to $JAVAC_PATH"
sudo update-alternatives --set javac "$JAVAC_PATH"
echo "Java and javac are now set to version $VERSION."
