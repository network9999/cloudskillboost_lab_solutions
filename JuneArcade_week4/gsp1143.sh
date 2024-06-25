#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
LAKE_NAME="sensors"
ZONE_NAME="temperature-raw-data"
ASSET_NAME="measurements"
BUCKET_NAME="$PROJECT_ID"

# Function to check the progress of lake/zone creation
check_progress() {
  local resource_type=$1
  local resource_name=$2
  local status

  echo "Checking progress for $resource_type: $resource_name..."
  while true; do
    status=$(gcloud dataplex $resource_type describe --project $PROJECT_ID --location $REGION --$resource_type $resource_name --format="value(state)")
    if [[ "$status" == "ACTIVE" ]]; then
      echo "$resource_type $resource_name is active."
      break
    else
      echo "Waiting for $resource_type $resource_name to become active..."
      sleep 30
    fi
  done
}

# Task 1: Create a lake
echo "Creating lake: $LAKE_NAME..."
gcloud dataplex lakes create $LAKE_NAME --project=$PROJECT_ID --location=$REGION --display-name="sensors"
check_progress "lakes" $LAKE_NAME

# Task 2: Add a zone to the lake
echo "Adding zone: $ZONE_NAME to lake: $LAKE_NAME..."
gcloud dataplex zones create $ZONE_NAME --project=$PROJECT_ID --location=$REGION --lake=$LAKE_NAME --type=RAW --display-name="temperature raw data"
check_progress "zones" $ZONE_NAME

# Task 3: Attach an asset to the zone
echo "Creating Cloud Storage bucket: $BUCKET_NAME..."
gsutil mb -l $REGION gs://$BUCKET_NAME

echo "Attaching asset: $ASSET_NAME to zone: $ZONE_NAME..."
gcloud dataplex assets create $ASSET_NAME --project=$PROJECT_ID --location=$REGION --lake=$LAKE_NAME --zone=$ZONE_NAME --display-name="measurements" --resource-spec="name=projects/$PROJECT_ID/buckets/$BUCKET_NAME"

# Task 4: Delete assets, zones, and lakes
# Detach asset
echo "Detaching asset: $ASSET_NAME from zone: $ZONE_NAME..."
gcloud dataplex assets delete $ASSET_NAME --project=$PROJECT_ID --location=$REGION --lake=$LAKE_NAME --zone=$ZONE_NAME --quiet

# Delete zone
echo "Deleting zone: $ZONE_NAME..."
gcloud dataplex zones delete $ZONE_NAME --project=$PROJECT_ID --location=$REGION --lake=$LAKE_NAME --quiet

# Delete lake
echo "Deleting lake: $LAKE_NAME..."
gcloud dataplex lakes delete $LAKE_NAME --project=$PROJECT_ID --location=$REGION --quiet

echo "All tasks have been completed"
