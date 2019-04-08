#!/bin/bash -xe
export PROJECT=$(gcloud info --format='value(config.project)')
export ZONE=us-central1-b
export CLUSTER=gke-deploy-cluster

git checkout master
git merge new-feature
git push gcp master


echo please visit https://console.cloud.google.com/cloud-build/builds
sleep 60;

export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}" --namespace=production services gceme-frontend)
for (( i=0;i<10;i++)) true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done



git tag v2.0.0
git push gcp v2.0.0

echo please visit https://console.cloud.google.com/cloud-build/builds
sleep 60;


for (( i=0;i<10;i++)) true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done












