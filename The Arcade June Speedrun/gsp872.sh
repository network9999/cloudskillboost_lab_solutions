#!/bin/bash

# Ensure authentication is in place
gcloud auth list

# Set project and region
export PROJECT_ID=$(gcloud config get-value project)

# Set compute region
gcloud config set compute/region $REGION

# Enable necessary services
gcloud services enable apigateway.googleapis.com --project $PROJECT_ID
gcloud services enable dataplex.googleapis.com

# Wait for services to be enabled
sleep 15

# Get project number
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Add IAM policy bindings
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/artifactregistry.reader"

# Clone sample repository
git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git

cd nodejs-docs-samples/functions/helloworld/helloworldGet

# Deploy the Cloud Function
deploy_function() {
  gcloud functions deploy helloGET --runtime nodejs14 --trigger-http --allow-unauthenticated --region $REGION
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully."
    deploy_success=true
  else
    echo "Retrying, please subscribe to techcps (https://www.youtube.com/@techcps)..."
    sleep 30
  fi
done

# Describe the deployed function
gcloud functions describe helloGET --region $REGION

# Test the function
curl -v https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET

cd ~

# Create OpenAPI specification file
cat > openapi2-functions.yaml <<EOF_CP
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      responses:
       '200':
          description: A successful response
          schema:
            type: string
EOF_CP

# Generate a unique API ID
export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"
sed -i "s/API_ID/${API_ID}/g" openapi2-functions.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions.yaml

echo $API_ID

# Create API Gateway resources
gcloud api-gateway apis create $API_ID --project=$PROJECT_ID
gcloud api-gateway api-configs create hello-world-config --project=$PROJECT_ID --api=$API_ID --openapi-spec=openapi2-functions.yaml --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
gcloud api-gateway gateways create hello-gateway --location=$REGION --project=$PROJECT_ID --api=$API_ID --api-config=hello-world-config

# Create API Key
gcloud alpha services api-keys create --display-name="techcps"  
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=techcps") 
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)") 
echo $API_KEY

# Enable the managed service
MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r .[0].managedService | cut -d'/' -f6)
echo $MANAGED_SERVICE
gcloud services enable $MANAGED_SERVICE

# Create updated OpenAPI specification file
cat > openapi2-functions2.yaml <<EOF_CP
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      security:
        - api_key: []
      responses:
       '200':
          description: A successful response
          schema:
            type: string
securityDefinitions:
  api_key:
    type: "apiKey"
    name: "key"
    in: "query"
EOF_CP

# Update the new OpenAPI spec with the API ID and Project ID
sed -i "s/API_ID/${API_ID}/g" openapi2-functions2.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions2.yaml

# Create new API config and update the gateway
gcloud api-gateway api-configs create hello-config --project=$PROJECT_ID --display-name="Hello Config" --api=$API_ID --openapi-spec=openapi2-functions2.yaml --backend-auth-service-account=$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com	
gcloud api-gateway gateways update hello-gateway --location=$REGION --project=$PROJECT_ID --api=$API_ID --api-config=hello-config

# Add IAM policy bindings for the updated service account
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"

# Enable the managed service again
MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r --arg api_id "$API_ID" '.[] | select(.name | endswith($api_id)) | .managedService' | cut -d'/' -f6)
echo $MANAGED_SERVICE
gcloud services enable $MANAGED_SERVICE

# Retrieve the gateway URL and test the deployed API
export GATEWAY_URL=$(gcloud api-gateway gateways describe hello-gateway --location $REGION --format json | jq -r .defaultHostname)
curl -sL $GATEWAY_URL/hello
curl -sL -w "\n" $GATEWAY_URL/hello?key=$API_KEY
