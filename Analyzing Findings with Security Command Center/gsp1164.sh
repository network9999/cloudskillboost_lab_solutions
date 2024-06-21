#!/bin/bash

# Ensure REGION environment variable is set
if [ -z "$REGION" ]; then
  echo "Please set the REGION environment variable."
  exit 1
fi

# Set variables
PROJECT_ID=$(gcloud config get-value project)
TOPIC_ID="export-findings-pubsub-topic"
SUBSCRIPTION_ID="export-findings-pubsub-topic-sub"
DATASET_ID="continuous_export_dataset"
BUCKET_NAME="scc-export-bucket-$PROJECT_ID"
EXPORT_FILE="findings.jsonl"

# Task 1: Create a continuous export pipeline to Pub/Sub

# Create Pub/Sub topic
echo "Creating Pub/Sub topic..."
gcloud pubsub topics create $TOPIC_ID

# Create Pub/Sub subscription
echo "Creating Pub/Sub subscription..."
gcloud pubsub subscriptions create $SUBSCRIPTION_ID --topic=$TOPIC_ID

# Enable Security Command Center API
echo "Enabling Security Command Center API..."
gcloud services enable securitycenter.googleapis.com

# Ensure SCC is properly set up for the project
echo "Setting up Security Command Center..."
gcloud scc settings set-organization-settings --project=$PROJECT_ID

# Create continuous export to Pub/Sub
echo "Creating continuous export to Pub/Sub..."
gcloud scc notifications create export-findings-pubsub \
  --description="Continuous exports of Findings to Pub/Sub" \
  --pubsub-topic=projects/$PROJECT_ID/topics/$TOPIC_ID \
  --filter='state="ACTIVE" AND NOT mute="MUTED"' \
  --project=$PROJECT_ID

# Create a virtual machine to generate findings
echo "Creating a virtual machine to generate findings..."
gcloud compute instances create instance-1 --zone=$REGION-a --machine-type=e2-micro --scopes=https://www.googleapis.com/auth/cloud-platform

# Simulate fetching messages from Pub/Sub subscription
echo "Fetching messages from Pub/Sub subscription..."
gcloud pubsub subscriptions pull $SUBSCRIPTION_ID --auto-ack --limit=3

# Task 2: Export and Analyze SCC findings with BigQuery

# Create a BigQuery dataset
echo "Creating BigQuery dataset..."
bq --location=$REGION --apilog=/dev/null mk --dataset $PROJECT_ID:$DATASET_ID

# Create continuous export to BigQuery
echo "Creating continuous export to BigQuery..."
gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/$DATASET_ID \
  --project=$PROJECT_ID

# Create service accounts and keys to generate new findings
echo "Creating service accounts and keys..."
for i in {0..2}; do
  gcloud iam service-accounts create sccp-test-sa-$i
  gcloud iam service-accounts keys create /tmp/sa-key-$i.json --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com
done

# Query findings from BigQuery
echo "Querying findings from BigQuery..."
bq query --apilog=/dev/null --use_legacy_sql=false "SELECT finding_id,event_time,finding.category FROM $DATASET_ID.findings"

# Create a GCS bucket for exporting existing findings
echo "Creating GCS bucket..."
gsutil mb -l $REGION gs://$BUCKET_NAME

echo "Script execution completed!"
