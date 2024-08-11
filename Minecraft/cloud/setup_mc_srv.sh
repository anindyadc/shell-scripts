#!/bin/bash

# Update and install necessary packages
apt update -y
apt upgrade -y
apt install -y openjdk-17-jdk wget screen

# Install azcopy
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux
tar -xf azcopy_v10.tar.gz --strip-components=1
chmod +x azcopy
mv azcopy /usr/local/bin/

# Create a directory for the Minecraft server
mkdir -p /home/ubuntu/minecraft
chown ubuntu:ubuntu /home/ubuntu/minecraft

# Download the backup file from Azure Storage
wget "https://anidatastore.blob.core.windows.net/databackup/minecraft_backup_10_08.tar.gz?sp=r&st=2024-08-11T19:21:01Z&se=2024-08-12T03:21:01Z&spr=https&sv=2022-11-02&sr=b&sig=bF4pZBsbgYEv4VJzXPh6r830UwRr%2BDr59TWGA" -O /home/ubuntu/minecraft_backup.tar.gz

# Extract the backup file
tar -xzf /home/ubuntu/minecraft_backup.tar.gz -C /home/ubuntu
chown -R ubuntu:ubuntu /home/ubuntu/minecraft

# Switch to the ubuntu user to complete the setup
sudo -u ubuntu bash <<EOF
# # Check if paper.jar exists, otherwise download the latest PaperMC server .jar file
# if [ ! -f /home/ubuntu/minecraft/paper.jar ]; then
#   PAPERMC_URL="https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/latest/downloads/paper-1.20.4-latest.jar"
#   wget \$PAPERMC_URL -O /home/ubuntu/minecraft/paper.jar
# fi

# # Accept the EULA if not already accepted
# if ! grep -q "eula=true" /home/ubuntu/minecraft/eula.txt; then
#   echo "eula=true" > /home/ubuntu/minecraft/eula.txt
# fi

# Create a script to start the server using screen
echo "#!/bin/bash
cd /home/ubuntu/minecraft
screen -S minecraft -dm java -Xmx1024M -Xms1024M -jar paper.jar nogui" > /home/ubuntu/minecraft/start_minecraft_server.sh

# Make the start script executable
chmod +x /home/ubuntu/minecraft/start_minecraft_server.sh

# Start the Minecraft server
/home/ubuntu/minecraft/start_minecraft_server.sh
EOF

echo "Minecraft server setup complete. You can reattach to the screen session using 'screen -r minecraft'."
