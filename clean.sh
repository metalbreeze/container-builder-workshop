#!/bin/bash -xe
export PROJECT=$(gcloud info --format='value(config.project)')
export ZONE=us-central1-b
export CLUSTER=gke-deploy-cluster

git remote remove gcp
git remote remove google
gcloud container clusters  delete gke-deploy-cluster

# jq 
#curl   \
#   https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
#    -H "Content-Type: application/json" \
#    -H "Authorization: Bearer $(gcloud config config-helper #--format='value(credential.access_token)')"

