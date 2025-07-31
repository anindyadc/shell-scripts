#!/bin/bash

set -e

echo "➡️ Installing Java 16 from official OpenJDK archive..."

# Download URL and target paths
JDK_TAR_URL="https://download.java.net/java/GA/jdk16/7863447f0ab643c585b9bdebf67c69db/36/GPL/openjdk-16_linux-x64_bin.tar.gz"
JDK_TAR_NAME="openjdk-16_linux-x64_bin.tar.gz"
JVM_DIR="/usr/lib/jvm"
JDK_DIR="${JVM_DIR}/jdk-16"

# Download JDK tarball
if [ ! -f "$JDK_TAR_NAME" ]; then
    echo "📦 Downloading OpenJDK 16..."
    wget "$JDK_TAR_URL"
else
    echo "✔️ JDK tarball already downloaded."
fi

# Create JVM directory and extract
echo "📂 Installing to $JVM_DIR..."
sudo mkdir -p "$JVM_DIR"
sudo tar -xzf "$JDK_TAR_NAME" -C "$JVM_DIR"

# Set up alternatives
echo "🔧 Configuring alternatives..."
sudo update-alternatives --install /usr/bin/java java "${JDK_DIR}/bin/java" 1
sudo update-alternatives --install /usr/bin/javac javac "${JDK_DIR}/bin/javac" 1

# Prompt to select Java version
echo "⚙️ You may now select the default Java version:"
sudo update-alternatives --config java

# Confirm
echo "✅ Java version installed:"
java -version
