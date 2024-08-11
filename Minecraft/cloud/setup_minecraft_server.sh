#!/bin/bash

# Update and install necessary packages
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk wget screen

# install azcopy
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1
chmod +x azcopy
sudo mv azcopy /usr/local/bin/

# # Create a directory for the Minecraft server
# mkdir -p ~/minecraft
# cd ~/minecraft

# Download the backup file from Azure Storage
wget "https://anidatastore.blob.core.windows.net/databackup/minecraft_backup_09_08.tar.gz?sp=r&st=2024-08-10T08:34:06Z&se=2024-08-10T16:34:06Z&spr=htps&sv=2022-11-02&sr=b&sig=GSF2%2FU" -O minecraft_backup.tar.gz

# Extract the backup file
tar -xzf minecraft_backup.tar.gz -C ~/

# # Navigate to the server directory (assuming the backup contains the full server directory)
# cd ~/minecraft

# # Check if paper.jar exists, otherwise download the latest PaperMC server .jar file
# if [ ! -f paper.jar ]; then
#   PAPERMC_URL="https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/latest/downloads/paper-1.20.4-latest.jar"
#   wget $PAPERMC_URL -O paper.jar
# fi

# # Accept the EULA if not already accepted
# if ! grep -q "eula=true" eula.txt; then
#   echo "eula=true" > eula.txt
# fi

# Create a script to start the server using screen
echo "#!/bin/bash
cd ~/minecraft
screen -S minecraft -dm java -Xmx1024M -Xms1024M -jar paper.jar nogui" > start_minecraft_server.sh

# Make the start script executable
chmod +x start_minecraft_server.sh

# Start the Minecraft server
./start_minecraft_server.sh

echo "Minecraft server setup complete. You can reattach to the screen session using 'screen -r minecraft'."
