#!/bin/bash

# Enable the required services
gcloud services enable servicedirectory.googleapis.com

# Wait for services to be enabled
sleep 15

# Create a namespace in Service Directory
gcloud service-directory namespaces create example-namespace \
   --location $REGION

# Create a service within the namespace
gcloud service-directory services create example-service \
   --namespace example-namespace \
   --location $REGION

# Create an endpoint for the service
gcloud service-directory endpoints create example-endpoint \
   --address 0.0.0.0 \
   --port 80 \
   --service example-service \
   --namespace example-namespace \
   --location $REGION

# Create a private managed DNS zone with Service Directory integration
gcloud dns managed-zones create example-zone-name \
   --dns-name myzone.example.com \
   --description quickgcplab \
   --visibility private \
   --networks https://www.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/networks/default \
   --service-directory-namespace https://servicedirectory.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/$REGION/namespaces/example-namespace

# Copy files from the specified Cloud Storage bucket
gsutil -m cp -r gs://spls/gsp067/python-docs-samples .

# Navigate to the hello_world sample directory
cd python-docs-samples/appengine/standard_python3/hello_world

# Update the app.yaml file to use Python 3.9
sed -i "s/python37/python39/g" app.yaml

# Create an App Engine application
gcloud app create --region=$REGION

# Deploy the application
yes | gcloud app deploy

echo "You have completed all the tasks."
