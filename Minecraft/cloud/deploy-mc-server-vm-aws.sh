#!/bin/bash

# key import
# aws ec2 import-key-pair --key-name "macAnindyaKey" --public-key-material fileb://~/.ssh/id_rsa.pub

# delete
# aws ec2 describe-instances  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'  --output table
# aws ec2 terminate-instances --instance-ids i-0dcfe4f2320de6db


# Function to show a progress bar
function show_progress {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    local temp
    echo -n "Creating EC2 instance... "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo "Done!"
}
# Source the .env file
if [ -f .env ]; then
    source .env
else
    echo ".env file not found!"
    exit 1
fi

echo $cloudflare_api_token 

# Variables
key_name=""macAnindyaKey""  # Name of the key pair you created/uploaded
key_file="/path/to/your/private-key.pem"  # Path to your private key file (for SSH access)
instance_type="t3.small"
ami_id="ami-0a0e5d9c7acc336f1"  # ( Ubuntu 22.04 AMI ID : Canonical, Ubuntu, 22.04 LTS)
security_group_name="mc-ServerSG"
instance_name="mc-Server"  # Name tag for the instance

# fetch data
# curl -X GET "https://api.cloudflare.com/client/v4/zones" -H "Authorization: Bearer $cloudflare_api_token" -H "Content-Type: application/json"
# curl -X GET "https://api.cloudflare.com/client/v4/zones/e06fd089e448326acfe03f85d06c58c1/dns_records" \                                                                                          
# -H "Authorization: Bearer $cloudflare_api_token" -H "Content-Type: application/json" | \
# jq -r --arg name "adhritsmp" '.result[] | select(.name == $name) | .id'


# Cloudflare variables
cloudflare_zone_id="e06fd089e448326acfe03f85d06c58c1"
cloudflare_record_id="5b608355d2ff93cfbe2590967f86c2a4"
cloudflare_dns_name="adhritsmp.dizikloud.top"

# Delete existing security group if exists
security_group_id=$(aws ec2 describe-security-groups --filters Name=group-name,Values=mc-ServerSG --query 'SecurityGroups[0].GroupId' --output text)
if [ "$security_group_id" != "None" ]; then
    echo "Security group mc-ServerSG exists. Proceeding with deletion..."
    aws ec2 delete-security-group --group-id "$security_group_id"
    echo "Security group mc-ServerSG deleted successfully."
else
    echo "Security group mc-ServerSG does not exist."
fi

# Create new security group
security_group_id=$(aws ec2 create-security-group --group-name mc-ServerSG --description "Security group for my VM" --output text)

# Create security group rules
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 25565 --cidr 0.0.0.0/0

# Launch an EC2 instance using the imported key
instance_id=$(aws ec2 run-instances \
  --image-id "$ami_id" \
  --count 1 \
  --instance-type "$instance_type" \
  --key-name "$key_name" \
  --security-group-ids "$security_group_id" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
  --query 'Instances[0].InstanceId' \
  --user-data file://setup_mc_srv.sh \
  --output text)

## Show progress bar
#pid=$!
#show_progress $pid

# Wait for the instance to be running
echo "Waiting for EC2 instance to be running..."
aws ec2 wait instance-running --instance-ids "$instance_id"

# Get the public IP address of the instance
public_ip=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Verifying the instance creation
echo "EC2 instance creation complete. You can now SSH into the instance using your private key."
echo "Public IP address of the instance is: $public_ip"

# Update Cloudflare DNS record
echo "Updating Cloudflare DNS record..."
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records/$cloudflare_record_id" \
     -H "Authorization: Bearer $cloudflare_api_token" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"$cloudflare_dns_name"'","content":"'"$public_ip"'","ttl":120}'

echo "Cloudflare DNS record updated successfully."


# Example SCP command to transfer files (adjust paths as needed)
# scp -i "$key_file" /path/to/your/install_moodle.sh ec2-user@$public_ip:/home/ec2-user/script.sh

# Example SSH command to execute commands on the instance
# ssh -i "$key_file" ec2-user@$public_ip 'chmod +x /home/ec2-user/script.sh && /home/ec2-user/script.sh'
