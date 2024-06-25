#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)

# enabling service
gcloud services enable dataplex.googleapis.com


# Task 1: Create a lake
echo "Creating lake: sensors"
gcloud alpha dataplex lakes create sensors \
 --location=$REGION \
 --labels=k1=v1,k2=v2,k3=v3 

# Task 2: Add a zone to the lake
echo "Adding zone: temperature-raw-data to lake: sensors"
gcloud alpha dataplex zones create temperature-raw-data \
            --location=$REGION --lake=sensors \
            --resource-location-type=SINGLE_REGION --type=RAW

# Task 3: Attach an asset to the zone
echo "Creating Cloud Storage bucket: $PROJECT_ID"
gsutil mb -l $REGION gs://$PROJECT_ID

gcloud dataplex assets create measurements --location=$REGION \
            --lake=sensors --zone=temperature-raw-data \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$PROJECT_ID/buckets/$PROJECT_ID

# Task 4: Ask for user permission to delete assets, zones, and lakes
read -p "Do you want to delete the assets, zones, and lakes? (y/n): " user_input

if [[ "$user_input" == "y" ]]; then
  gcloud dataplex assets delete measurements --zone=temperature-raw-data --lake=sensors --location=$REGION --quiet

  gcloud dataplex zones delete temperature-raw-data --lake=sensors --location=$REGION --quiet

  gcloud dataplex lakes delete sensors --location=$REGION --quiet


  echo "Assets, zones, and lakes have been deleted."
else
  echo "Skipping the deletion of assets, zones, and lakes."
fi


echo "All tasks have been completed."
