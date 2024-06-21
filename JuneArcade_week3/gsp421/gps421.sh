#!/bin/bash

gsutil mb gs://$DEVSHELL_PROJECT_ID

gsutil mb gs://$DEVSHELL_PROJECT_ID-2


curl -LO raw.https://github.com/network9999/cloudskillboost_lab_solutions/blob/main/JuneArcade_week3/gsp421/demo-image1.png

curl -LO https://github.com/network9999/cloudskillboost_lab_solutions/blob/main/JuneArcade_week3/gsp421/demo-image2.png

curl -LO https://github.com/network9999/cloudskillboost_lab_solutions/blob/main/JuneArcade_week3/gsp421/demo-image1-copy.png


gsutil cp demo-image1.png gs://$DEVSHELL_PROJECT_ID/demo-image1.png

gsutil cp demo-image2.png gs://$DEVSHELL_PROJECT_ID/demo-image2.png

gsutil cp demo-image1-copy.png gs://$DEVSHELL_PROJECT_ID-2/demo-image1-copy.png
