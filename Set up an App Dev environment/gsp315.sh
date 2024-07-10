# Authenticate and set the project
gcloud auth list

export REGION="${ZONE%-*}"

gcloud config set project $DEVSHELL_PROJECT_ID

# Enable necessary services
gcloud services enable artifactregistry.googleapis.com logging.googleapis.com pubsub.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com eventarc.googleapis.com run.googleapis.com --project=$DEVSHELL_PROJECT_ID

sleep 60

# Create a bucket
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID-bucket

# Create a Pub/Sub topic
gcloud pubsub topics create $TOPIC_NAME

# Get project number and service account
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

# Add IAM policy binding for the service account
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

# Create a directory and navigate into it
mkdir techcps && cd techcps

# Create the index.js file
cat > index.js <<'EOF_CP'
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('memories-thumbnail-generator', cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${event}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "topic-memories-290";
  const pubsub = new PubSub();
  if ( fileName.search("64x64_thumbnail") == -1 ){
    // doesn't have a thumbnail, get the filename extension
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);
      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();
      let resize = imagemagick().resize(size).quality(90);
      srcStream.pipe(resize).pipe(dstStream);
      return new Promise((resolve, reject) => {
        dstStream
          .on("error", (err) => {
            console.log(`Error: ${err}`);
            reject(err);
          })
          .on("finish", () => {
            console.log(`Success: ${fileName} → ${newFilename}`);
              // set the content-type
              gcsNewObject.setMetadata(
              {
                contentType: 'image/'+ filename_ext.toLowerCase()
              }, function(err, apiResponse) {});
              pubsub
                .topic(topicName)
                .publisher()
                .publish(Buffer.from(newFilename))
                .then(messageId => {
                  console.log(`Message ${messageId} published.`);
                })
                .catch(err => {
                  console.error('ERROR:', err);
                });
          });
      });
    }
    else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  }
  else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
EOF_CP

# Update the function name and topic name in the index.js file
sed -i "8c\functions.cloudEvent('$FUNCTION_NAME', cloudEvent => { " index.js
sed -i "18c\  const topicName = '$TOPIC_NAME';" index.js

# Create the package.json file
cat > package.json <<EOF_CP
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
      "start": "node index.js"
    },
    "dependencies": {
      "@google-cloud/functions-framework": "^3.0.0",
      "@google-cloud/pubsub": "^2.0.0",
      "@google-cloud/storage": "^5.0.0",
      "fast-crc32c": "1.0.4",
      "imagemagick-stream": "4.1.1"
    },
    "devDependencies": {},
    "engines": {
      "node": ">=4.3.2"
    }
}
EOF_CP

# Function to deploy the cloud function
deploy_function() {
    gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime nodejs20 \
    --trigger-resource $DEVSHELL_PROJECT_ID-bucket \
    --trigger-event google.storage.object.finalize \
    --region=$REGION \
    --entry-point $FUNCTION_NAME \
    --source . \
    --quiet
}

# Try deploying the function until successful
deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully (https://www.youtube.com/@techcps).."
    deploy_success=true
  else
    echo "please subscribe to techcps (https://www.youtube.com/@techcps)."
    sleep 10
  fi
done

# Download and upload a sample image to the bucket
wget map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg
gsutil cp map.jpg gs://$DEVSHELL_PROJECT_ID-bucket/map.jpg

# Remove previous cloud engineer's access
PREVIOUS_ENGINEER="student-03-7614ea627ad0@qwiklabs.net"
gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="user:$PREVIOUS_ENGINEER" \
  --role="roles/viewer"

# Confirm the action
echo "Removed $PREVIOUS_ENGINEER with role roles/viewer from the project $DEVSHELL_PROJECT_ID"
