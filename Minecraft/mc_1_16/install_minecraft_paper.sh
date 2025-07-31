#!/bin/bash

# === Variables ===
MINECRAFT_DIR="/opt/minecraft"
PAPER_VERSION="1.16.5"
PAPER_BUILD="794"
PAPER_JAR="paper-${PAPER_VERSION}-${PAPER_BUILD}.jar"
PAPER_DL="https://fill-data.papermc.io/v1/objects/e67da4851d08cde378ab2b89be58849238c303351ed2482181a99c2c2b489276/${PAPER_JAR}"

# === Create Minecraft directory ===
sudo mkdir -p "$MINECRAFT_DIR"
sudo chown "$USER":"$USER" "$MINECRAFT_DIR"
cd "$MINECRAFT_DIR" || exit 1

# === Download Paper JAR ===
if [ ! -f "$PAPER_JAR" ]; then
    echo "Downloading PaperMC $PAPER_VERSION build $PAPER_BUILD..."
    wget "$PAPER_DL" -O "$PAPER_JAR"
else
    echo "$PAPER_JAR already exists, skipping download."
fi

# === Accept EULA ===
echo "eula=true" > eula.txt

# === Create systemd service ===
SERVICE_FILE="/etc/systemd/system/minecraft.service"

echo "Creating systemd service file..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Minecraft Server (Paper $PAPER_VERSION)
After=network.target

[Service]
WorkingDirectory=$MINECRAFT_DIR
ExecStart=/usr/bin/screen -DmS minecraft /usr/bin/java -Xmx2G -Xms1G -jar $MINECRAFT_DIR/$PAPER_JAR nogui
ExecStop=/usr/bin/screen -S minecraft -X stuff "stop$(printf \\r)"
User=$USER
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# === Reload systemd and enable the service ===
echo "Reloading systemd daemon and enabling service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable minecraft

# === Instructions ===
echo ""
echo "✅ Minecraft Paper $PAPER_VERSION server installed."
echo "➡️  To start the server:   sudo systemctl start minecraft"
echo "➡️  To check status:       sudo systemctl status minecraft"
echo "➡️  To view console:       screen -r minecraft"
echo "➡️  To detach from screen: Ctrl + A, then D"
