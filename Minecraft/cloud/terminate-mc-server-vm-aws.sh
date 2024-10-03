#!/bin/bash

# Variables
instance_name="mc-Server"  # Name tag of the EC2 instance
security_group_name="mc-ServerSG"

# Get the instance ID based on the name tag
instance_id=$(aws ec2 describe-instances \
  --filters Name=tag:Name,Values="$instance_name" --query 'Reservations[*].Instances[*].InstanceId' --output text)

if [ -z "$instance_id" ]; then
    echo "No EC2 instance found with the name tag: $instance_name."
    exit 1
fi

# Terminate the EC2 instance
echo "Terminating EC2 instance with ID: $instance_id..."
aws ec2 terminate-instances --instance-ids "$instance_id"
echo "Waiting for EC2 instance to be terminated..."
aws ec2 wait instance-terminated --instance-ids "$instance_id"
echo "EC2 instance terminated successfully."

# Get the security group ID
security_group_id=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$security_group_name" --query 'SecurityGroups[0].GroupId' --output text)

if [ "$security_group_id" = "None" ]; then
    echo "No security group found with the name $security_group_name."
    exit 1
fi

# Check and delete network interfaces associated with the security group
echo "Checking for network interfaces associated with the security group..."
network_interfaces=$(aws ec2 describe-network-interfaces --filters Name=group-id,Values="$security_group_id" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)

if [ -n "$network_interfaces" ]; then
    echo "Network interfaces associated with the security group:"
    echo "$network_interfaces"
    for ni_id in $network_interfaces; do
        echo "Checking network interface: $ni_id"
        # Describe the network interface to get attachment information
        attachment_info=$(aws ec2 describe-network-interfaces --network-interface-ids "$ni_id" --query 'NetworkInterfaces[*].Attachment' --output text)
        if [ -n "$attachment_info" ]; then
            attachment_id=$(echo "$attachment_info" | awk '{print $2}')
            echo "Detaching network interface: $ni_id"
            aws ec2 detach-network-interface --attachment-id "$attachment_id"
            echo "Waiting for network interface to be detached..."
            aws ec2 wait network-interface-available --network-interface-ids "$ni_id"
        fi
        echo "Deleting network interface: $ni_id"
        aws ec2 delete-network-interface --network-interface-id "$ni_id"
    done
fi

# Attempt to delete the security group
echo "Deleting security group with ID: $security_group_id..."
aws ec2 delete-security-group --group-id "$security_group_id"
echo "Security group deleted successfully."

# Optionally delete the key pair if needed
# Uncomment the lines below if you also want to delete the key pair
# key_name="macAnindyaKey"
# echo "Deleting key pair with name: $key_name..."
# aws ec2 delete-key-pair --key-name "$key_name"
# echo "Key pair deleted successfully."

echo "Cleanup completed."

