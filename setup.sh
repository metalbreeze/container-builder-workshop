#!/bin/bash -xe
export PROJECT=$(gcloud info --format='value(config.project)')
export ZONE=us-central1-b
export CLUSTER=gke-deploy-cluster

gcloud config set project $PROJECT
gcloud config set compute/zone $ZONE

gcloud config list project
gcloud config list compute/zone

gcloud services enable container.googleapis.com --async
gcloud services enable containerregistry.googleapis.com --async
gcloud services enable cloudbuild.googleapis.com --async
gcloud services enable sourcerepo.googleapis.com --async

cd container-builder-workshop
gcloud container clusters create ${CLUSTER} \
  --project=${PROJECT} \
  --zone=${ZONE} \
  --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"


export PROJECT_NUMBER="$(gcloud projects describe \
  $(gcloud config get-value core/project -q) --format='get(projectNumber)')"

gcloud projects add-iam-policy-binding ${PROJECT} \
  --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role=roles/container.developer

kubectl create ns production

kubectl apply -f kubernetes/deployments/prod -n production
kubectl apply -f kubernetes/deployments/canary -n production
kubectl apply -f kubernetes/services -n production

kubectl scale deployment gceme-frontend-production -n production --replicas 4
kubectl get pods -n production -l app=gceme -l role=frontend
kubectl get pods -n production -l app=gceme -l role=backend
kubectl get service gceme-frontend -n production

export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services gceme-frontend)

sleep 10
curl http://$FRONTEND_SERVICE_IP/version
