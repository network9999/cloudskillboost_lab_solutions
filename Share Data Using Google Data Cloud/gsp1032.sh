#!/bin/bash

# Set variables
PROJECT_ID=$(gcloud config get-value project)
DATASET_ID="demo_dataset"

# Task 1: Grant permissions via IAM for data access
echo "Granting BigQuery User role to $CUSTOMER1 and $CUSTOMER2..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$CUSTOMER1" \
  --role="roles/bigquery.user"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$CUSTOMER2" \
  --role="roles/bigquery.user"

# Task 2: Create a new dataset within an existing project
echo "Creating a new dataset..."
bq --location=US mk -d --description "Demo Dataset" $PROJECT_ID:$DATASET_ID

# Task 3: Copy an existing table to newly created dataset
echo "Copying Google Trends table to new dataset..."
bq query --use_legacy_sql=false --destination_table=$PROJECT_ID:$DATASET_ID.trends "SELECT * FROM `bigquery-public-data.google_trends.full` LIMIT 1000"

# Task 4: Grant permission to the users to access the table
echo "Granting BigQuery Data Viewer role to $CUSTOMER1 and $CUSTOMER2 on the table..."
bq show --format=prettyjson $PROJECT_ID:$DATASET_ID.trends | jq '.access += [{"role":"READER","userByEmail":"'$CUSTOMER1'"},{"role":"READER","userByEmail":"'$CUSTOMER2'"}]' | bq update --source -

# Task 5: Authorize a dataset and grant permission to the users
echo "Authorizing dataset and granting permissions..."
bq show --format=prettyjson $PROJECT_ID:$DATASET_ID | jq '.access += [{"role":"roles/bigquery.user","userByEmail":"'$CUSTOMER1'"},{"role":"roles/bigquery.user","userByEmail":"'$CUSTOMER2'"}]' | bq update --source -

# Task 6: Verify dataset sharing for customer projects
echo "Verifying dataset sharing for $CUSTOMER1..."
gcloud auth login $CUSTOMER1
bq query --use_legacy_sql=false "SELECT * FROM \`$PROJECT_ID.$DATASET_ID.trends\`"

echo "Verifying dataset sharing for $CUSTOMER2..."
gcloud auth login $CUSTOMER2
bq query --use_legacy_sql=false "SELECT * FROM \`$PROJECT_ID.$DATASET_ID.trends\`"

echo "You have completed all the tasks."
