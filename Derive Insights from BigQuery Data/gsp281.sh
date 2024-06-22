#!/bin/bash

# Set project and region variables
PROJECT_ID=$(gcloud config get-value project)

# Enable required APIs
echo "Enabling necessary APIs..."
gcloud services enable bigquery.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com

# Create a BigQuery dataset
DATASET_ID=cycle_hire_dataset
echo "Creating BigQuery dataset..."
bq --location=$REGION mk --dataset $PROJECT_ID:$DATASET_ID

# Load public data
echo "Starring public data project..."
bq query --use_legacy_sql=false "SELECT * FROM \`bigquery-public-data.london_bicycles.cycle_hire\` LIMIT 1"

# Create GCS bucket
BUCKET_NAME="${PROJECT_ID}-cycle-hire-bucket"
echo "Creating GCS bucket..."
gsutil mb -l $REGION gs://$BUCKET_NAME

# Run BigQuery queries and save results as CSV
echo "Running BigQuery queries and saving results as CSV..."
bq query --nouse_legacy_sql --format=csv \
    "SELECT start_station_name, COUNT(*) AS num FROM \`bigquery-public-data.london_bicycles.cycle_hire\` GROUP BY start_station_name ORDER BY num DESC" > start_station_data.csv

bq query --nouse_legacy_sql --format=csv \
    "SELECT end_station_name, COUNT(*) AS num FROM \`bigquery-public-data.london_bicycles.cycle_hire\` GROUP BY end_station_name ORDER BY num DESC" > end_station_data.csv

# Upload CSV files to GCS
echo "Uploading CSV files to GCS..."
gsutil cp start_station_data.csv gs://$BUCKET_NAME/start_station_data.csv
gsutil cp end_station_data.csv gs://$BUCKET_NAME/end_station_data.csv

# Create Cloud SQL instance
INSTANCE_ID=my-demo
echo "Creating Cloud SQL instance..."
gcloud sql instances create $INSTANCE_ID \
    --database-version=MYSQL_8_0 \
    --cpu=4 \
    --memory=16GB \
    --region=$REGION \
    --root-password=my-secure-password

# Wait for the instance to be created
echo "Waiting for Cloud SQL instance to be created..."
sleep 300  # Wait for 5 minutes

# Create database in Cloud SQL
echo "Creating database in Cloud SQL..."
gcloud sql connect $INSTANCE_ID --user=root <<EOF
CREATE DATABASE bike;
EOF

# Export queries as CSV files
echo "Exporting queries as CSV files..."
bq query --nouse_legacy_sql --format=csv \
    "SELECT end_station_name, COUNT(*) AS num FROM \`bigquery-public-data.london_bicycles.cycle_hire\` GROUP BY end_station_name ORDER BY num DESC" > end_station_data.csv

echo "Uploading end station data CSV to GCS..."
gsutil cp end_station_data.csv gs://$BUCKET_NAME/end_station_data.csv

# Final messages
echo "Script execution completed!"
echo "You can find the exported data in the GCS bucket: gs://$BUCKET_NAME"
echo "Cloud SQL instance created with the ID: $INSTANCE_ID"

