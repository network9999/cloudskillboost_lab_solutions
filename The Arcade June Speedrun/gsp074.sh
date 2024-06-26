#!/bin/bash

# Set the compute region
gcloud config set compute/region $REGION

# Create a new Cloud Storage bucket
gsutil mb gs://$DEVSHELL_PROJECT_ID

# Download the image
curl -o ada.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg

# Upload the image to the Cloud Storage bucket
gsutil cp ada.jpg gs://$DEVSHELL_PROJECT_ID

# Download the image back to the local machine
gsutil cp gs://$DEVSHELL_PROJECT_ID/ada.jpg .

# Copy the image to a folder within the Cloud Storage bucket
gsutil cp gs://$DEVSHELL_PROJECT_ID/ada.jpg gs://$DEVSHELL_PROJECT_ID/image-folder/

# Change the access control list to make the image publicly readable
gsutil acl ch -u AllUsers:R gs://$DEVSHELL_PROJECT_ID/ada.jpg
