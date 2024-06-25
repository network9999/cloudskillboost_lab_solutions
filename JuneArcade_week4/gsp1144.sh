#!/bin/bash

gcloud services enable dataplex.googleapis.com

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/region $REGION

gcloud dataplex lakes create ecommerce \
   --location=$REGION \
   --display-name="Ecommerce" \
   --description="Ecommerce Domain"

gcloud dataplex zones create orders-curated-zone \
    --location=$REGION \
    --lake=ecommerce \
    --display-name="Orders Curated Zone" \
    --resource-location-type=SINGLE_REGION \
    --type=CURATED \
    --discovery-enabled \
    --discovery-schedule="0 * * * *"
    
bq mk --location=$REGION --dataset orders 

gcloud dataplex assets create orders-curated-dataset \
--location=$REGION \
--lake=ecommerce \
--zone=orders-curated-zone \
--display-name="Orders Curated Dataset" \
--resource-type=BIGQUERY_DATASET \
--resource-name=projects/$PROJECT_ID/datasets/orders \
--discovery-enabled 

# Task 4: Ask for user permission to delete assets, zones, and lakes
read -p "Do you want to delete the assets, zones, and lakes? (y/n): " user_input

if [[ "$user_input" == "y" ]]; then
  gcloud dataplex assets delete orders-curated-dataset --location=$REGION --zone=orders-curated-zone --lake=ecommerce --quiet

  gcloud dataplex zones delete orders-curated-zone --location=$REGION --lake=ecommerce --quiet

  gcloud dataplex lakes delete ecommerce --location=$REGION --quiet


  echo "Assets, zones, and lakes have been deleted."
else
  echo "Skipping the deletion of assets, zones, and lakes."
fi

echo "All tasks have been completed completed."
