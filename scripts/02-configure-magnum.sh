#!/bin/bash
# 02-configure-magnum.sh
# This script configures OpenStack Magnum to be ready for Kubernetes cluster creation.
# It is executed on the 'controller' node after OpenStack is installed.

# --- Preamble ---
set -ex # Exit on error, print commands
LOG_FILE="/tmp/configure-magnum.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "Starting Magnum Configuration..."

# --- Source OpenStack Credentials ---
# The DevStack installation creates a file with the necessary environment
# variables to use the OpenStack command-line clients as the 'admin' user.[34]
source /opt/devstack/openrc admin admin

# Wait for services to be fully available.
sleep 30

# --- Dynamically Find a Suitable Image ---
echo "Searching for a suitable Fedora CoreOS image in Glance..."
# List all images, get only the 'Name' column, find one with 'fedora-coreos', and take the first one.
K8S_IMAGE_NAME=$(openstack image list -f value -c Name | grep 'fedora-coreos' | head -n 1)

# Check if an image was found. If not, exit with an error.
if [[ -z "$K8S_IMAGE_NAME" ]]; then
    echo "ERROR: No 'fedora-coreos' image was found in Glance."
    echo "The script cannot create a Kubernetes cluster template without a suitable image."
    echo "Please modify the '01-install-openstack.sh' script to download and upload one."
    exit 1
fi

echo "Found image: '$K8S_IMAGE_NAME'. This will be used for the cluster template."

# --- Create Magnum Cluster Template ---

# --- Create Magnum Cluster Template ---
# A Cluster Template defines the parameters for creating a Kubernetes cluster.[29]
# This allows for consistent cluster deployments.
echo "Creating Magnum Cluster Template for Kubernetes..."
openstack coe cluster template create k8s-gitea-template \
    --image "$K8S_IMAGE_NAME" \
    --keypair mykey \
    --external-network public \
    --dns-nameserver 8.8.8.8 \
    --master-flavor m1.medium \
    --flavor m1.small \
    --docker-volume-size 150 \
    --network-driver calico \
    --coe kubernetes

# --- Verification ---
# List the created cluster templates to confirm success.
echo "Verifying Cluster Template creation..."
openstack coe cluster template list

echo "Magnum Configuration Complete. The platform is ready to create Kubernetes clusters."
