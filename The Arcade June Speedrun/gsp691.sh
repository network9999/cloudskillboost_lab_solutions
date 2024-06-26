#!/bin/bash

# Enable the required services
gcloud services enable notebooks.googleapis.com
gcloud services enable aiplatform.googleapis.com

# Set variables for the notebook instance
export NOTEBOOK_NAME="awesome-jupyter"
export MACHINE_TYPE="e2-standard-2"

# Create a new AI Platform Notebooks instance
gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-2-11-cu113-notebooks \
  --machine-type=$MACHINE_TYPE

# Optional: Wait for the instance to be fully created
echo "Waiting for the notebook instance to be ready..."
sleep 60

# Print the instance details
gcloud notebooks instances describe $NOTEBOOK_NAME --location=$ZONE

echo "You have completed all the tasks."
