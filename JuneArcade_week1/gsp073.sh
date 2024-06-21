export PROJECT_ID=$(gcloud config get-value project)

gsutil mb -l $REGION -c Standard gs://$PROJECT_ID

curl -O https://github.com/network9999/cloudskillboost_lab_solutions/blob/main/JuneArcade_week1/kitten.png

gsutil cp kitten.png gs://$PROJECT_ID/kitten.png

gsutil iam ch allUsers:objectViewer gs://$PROJECT_ID
