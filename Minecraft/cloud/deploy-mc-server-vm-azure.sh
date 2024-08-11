#!/bin/bash

# show default subs
# az account show --output table
# show subs list
# az account list --output table
# set default sub
# az account set --subscription cdd7b3de

# cat /path/to/your/install_moodle.sh | ssh azureuser@<VM-IP> 'cat > /home/azureuser/script.sh'
# scp /path/to/your/install_moodle.sh azureuser@<VM-IP>:/home/azureuser/script.sh


# Function to show a progress bar
function show_progress {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    local temp
    echo -n "Creating VM... "
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

# fetch data
# curl -X GET "https://api.cloudflare.com/client/v4/zones" -H "Authorization: Bearer $cloudflare_api_token" -H "Content-Type: application/json"
# curl -X GET "https://api.cloudflare.com/client/v4/zones/e06fd089e448326acfe03f85d06c58c1/dns_records" \                                                                                          
# -H "Authorization: Bearer $cloudflare_api_token" -H "Content-Type: application/json" | \
# jq -r --arg name "adhritsmp" '.result[] | select(.name == $name) | .id'


# Cloudflare variables
cloudflare_zone_id="e06fd089e448326acfe03f85d06c58c1"
cloudflare_record_id="5b608355d2ff93cfbe2590967f86c2a4"
cloudflare_dns_name="adhritsmp.dizikloud.top"

rg_name="mc-server"
# Check if resource group exists
if az group show --name $rg_name &> /dev/null; then
    echo "Resource group $rg_name exists. Proceeding with deletion..."

    # Delete resource group with --no-wait
    az group delete --name $rg_name --yes --no-wait

    # Wait for deletion to complete
    echo "Waiting for deletion to complete..."
    az group wait --name $rg_name --deleted
    echo "Resource group $rg_name deleted successfully."
else
    echo "Resource group $rg_name does not exist."
fi

# # Wait for the deletion to complete with a timeout
# echo "Waiting for the resource group to be deleted..."
# end=$((SECONDS+300)) # 5 minutes timeout
# while [ $SECONDS -lt $end ]; do
#     rg_exists=$(az group exists --name "$rg_name")
#     if [ "$rg_exists" = "false" ]; then
#         echo "Resource group '"$rg_name"' successfully deleted."
#         break
#     else
#         echo "Resource group '"$rg_name"' still exists. Waiting for deletion to complete..."
#         sleep 10
#     fi
# done

if [ "$rg_exists" = "true" ]; then
    echo "Failed to delete the resource group $rg_name within the timeout period."
    exit 1
fi

# Create resource group
az group create --name "$rg_name" --location eastus

# Create network security group
az network nsg create --resource-group "$rg_name" --name myNetworkSecurityGroup

# Create NSG rules
az network nsg rule create --resource-group "$rg_name" --nsg-name myNetworkSecurityGroup --name allow-ssh --priority 1000 --protocol Tcp --destination-port-range 22 --access Allow
az network nsg rule create --resource-group "$rg_name" --nsg-name myNetworkSecurityGroup --name allow-http --priority 1010 --protocol Tcp --destination-port-range 25565 --access Allow

# Create virtual network and subnet
az network vnet create --resource-group "$rg_name" --name myVnet --subnet-name mySubnet

# Ensure the virtual network and subnet are fully created
sleep 30

# Create public IP address
az network public-ip create --resource-group "$rg_name" --name myPublicIP

# Create network interface and associate NSG
az network nic create --resource-group "$rg_name" --name myNic --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup --public-ip-address myPublicIP

# Ensure the NIC is fully created
sleep 30

# pick an image from ['CentOS85Gen2', 'Debian11', 'FlatcarLinuxFreeGen2', 'OpenSuseLeap154Gen2', 'RHELRaw8LVMGen2', 'SuseSles15SP3', 'Ubuntu2204', 'Win2022Datacenter', 'Win2022AzureEditionCore', 'Win2019Datacenter', 'Win2016Datacenter', 'Win2012R2Datacenter', 'Win2012Datacenter', 'Win2008R2SP1'].

# Create VM and show progress bar
az vm create \
  --resource-group "$rg_name" \
  --name "$rg_name"-vm \
  --nics myNic \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --size Standard_DS1_v2 \
  --availability-set "" \
  --location eastus \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --custom-data setup_mc_srv.sh &

# [Coming breaking change] In the coming release, the default behavior will be changed as follows when sku is Standard and zone is not provided: 
# For zonal regions, you will get a zone-redundant IP indicated by zones:["1","2","3"]; For non-zonal regions, you will get a non zone-redundant IP indicated by zones:null

# Get the PID of the az vm create command
pid=$!

# Show progress while the command is running
##show_progress $pid

# Get the public IP address of the VM
# public_ip=$(az vm show \
#   --resource-group "$rg_name" \
#   --name jitsi-meet-vm \
#   --show-details \
#   --query [publicIps] \
#   --output tsv)

# Wait for VM creation to complete
echo "Waiting for VM creation to complete..."
az vm wait --created --resource-group "$rg_name" --name "$rg_name-vm"

# Get the public IP address of the VM
public_ip=$(az vm list-ip-addresses --resource-group "$rg_name" --name "$rg_name"-vm --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)

# Verifying the VM creation
echo "VM creation complete. You can now SSH into the VM using your existing public key."
echo "Public IP address of the VM is: $public_ip"

# Update Cloudflare DNS record
echo "Updating Cloudflare DNS record..."
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records/$cloudflare_record_id" \
     -H "Authorization: Bearer $cloudflare_api_token" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"$cloudflare_dns_name"'","content":"'"$public_ip"'","ttl":120}'

echo "Cloudflare DNS record updated successfully."

#scp /Users/anindyadc/Downloads/deploy_id_rsa /Users/anindyadc/Downloads/deploy_id_rsa.pub azureuser@$public_ip:~/.ssh/ && ssh azureuser@$public_ip 'chmod 600 ~/.ssh/deploy_id_rsa && chmod 644 ~/.ssh/deploy_id_rsa.pub && mv ~/.ssh/deploy_id_rsa ~/.ssh/id_rsa'
