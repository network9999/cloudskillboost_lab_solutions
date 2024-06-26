export BUCKET="$(gcloud config get-value project)"         

gsutil mb -p $BUCKET gs://$BUCKET-bucket

curl -LO https://github.com/network9999/cloudskillboost_lab_solutions/blob/main/The%20Arcade%20June%20Speedrun/demo-image.jpg

gsutil cp demo-image.jpg gs://$BUCKET-bucket/demo-image.jpg

gsutil acl ch -u allUsers:R gs://$BUCKET-bucket/demo-image.jpg

echo "All tasks have been compeleted"
