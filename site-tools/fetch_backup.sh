#!/bin/bash

# SSH host details
SSH_USER="ubuntu"
SSH_HOST="ovhcloud"
SSH_PORT="22"
REMOTE_FOLDER="/home/ubuntu/docker-cloud/passbolt/backup"

# Local backup folder
LOCAL_BACKUP_FOLDER="/home/anindyadc/backup"

# Get current date
CURRENT_DATE=$(date +"%Y%m%d")

# Timestamp
#TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Remote file names
REMOTE_FILES=(
    "backup_$CURRENT_DATE.sql"
    "serverkey.asc"
    "serverkey_private.asc"
)

# Loop through remote files and download them
for REMOTE_FILE in "${REMOTE_FILES[@]}"
do
    # Construct remote file path
    REMOTE_PATH="$REMOTE_FOLDER/$REMOTE_FILE"
    
    # Construct local file path
    LOCAL_PATH="$LOCAL_BACKUP_FOLDER/$REMOTE_FILE"
    
    # Download file via SSH
#    ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "cat $REMOTE_PATH" > $LOCAL_PATH
    scp $SSH_USER@$SSH_HOST:$REMOTE_FOLDER/$REMOTE_FILE $LOCAL_BACKUP_FOLDER     
    
    # Check if download was successful
    if [ $? -eq 0 ]; then
        echo "Downloaded $REMOTE_FILE successfully."
    else
        echo "Failed to download $REMOTE_FILE."
    fi
done
