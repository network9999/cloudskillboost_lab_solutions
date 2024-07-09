#!/bin/bash

# Enable necessary services
gcloud services enable run.googleapis.com

sleep 10

# Create a new directory and navigate into it
mkdir -p Awesome && cd Awesome

# Create index.js file with the function code
cat > index.js <<EOF
/**
 * Responds to any HTTP request.
 *
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 */
exports.GCFunction = (req, res) => {
    let message = req.query.message || req.body.message || 'Hey There !';
    res.status(200).send(message);
};
EOF

# Create package.json file
cat > package.json <<EOF
{
    "name": "sample-http",
    "version": "0.0.1"
}
EOF

# Create a Cloud Storage bucket
gsutil mb -p $DEVSHELL_PROJECT_ID gs://$DEVSHELL_PROJECT_ID

# Get the project number
PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="value(projectNumber)")

sleep 30

# Set the service account email
SERVICE_ACCOUNT="service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com"

# Get the current IAM policy
IAM_POLICY=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format=json)

# Check and add IAM binding if it does not exist
if ! echo "$IAM_POLICY" | grep -q "$SERVICE_ACCOUNT" || ! echo "$IAM_POLICY" | grep -q "roles/artifactregistry.reader"; then
  echo "Creating IAM binding for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
  gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/artifactregistry.reader
else
  echo "IAM binding already exists for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
fi

# Deploy the Cloud Function
gcloud functions deploy GCFunction \
  --region=$REGION \
  --gen2 \
  --trigger-http \
  --runtime=nodejs20 \
  --allow-unauthenticated \
  --max-instances=5

# Call the function with a test message
DATA=$(echo 'Nice to Meet You !' | base64) && gcloud functions call GCFunction --region=$REGION --data '{"data":"'$DATA'"}'

sleep 90

# Check and add IAM binding again (just to ensure consistency)
if ! echo "$IAM_POLICY" | grep -q "$SERVICE_ACCOUNT" || ! echo "$IAM_POLICY" | grep -q "roles/artifactregistry.reader"; then
  echo "Creating IAM binding for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
  gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/artifactregistry.reader
else
  echo "IAM binding already exists for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
fi

# Re-deploy the Cloud Function
gcloud functions deploy GCFunction \
  --region=$REGION \
  --gen2 \
  --trigger-http \
  --runtime=nodejs20 \
  --allow-unauthenticated \
  --max-instances=5

# Call the function with another test message
DATA=$(echo 'Stay Cool' | base64) && gcloud functions call GCFunction --region=$REGION --data '{"data":"'$DATA'"}'

echo "You have completed all the tasks."
