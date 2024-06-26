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

echo "You have completed all the tasks."
