#!/bin/bash -xe
export PROJECT=$(gcloud info --format='value(config.project)')
export ZONE=us-central1-b
export CLUSTER=gke-deploy-cluster

git config --global credential.'https://source.developers.google.com'.helper gcloud.sh
gcloud source repos create container-builder-workshop
git remote add google \
https://source.developers.google.com/p/$PROJECT/r/container-builder-workshop


git push google master


gcloud alpha source repos create default

git init
git config credential.helper gcloud.sh
git remote add gcp https://source.developers.google.com/p/$PROJECT/r/default
git config --global user.email "shu.eclipse@gmail.com"
git config --global user.name "metalbreeze"
git add .
git commit -m "Initial commit"
git push gcp master


#########setup trigger
cat <<EOF > branch-build-trigger.json
{
  "triggerTemplate": {
    "projectId": "${PROJECT}",
    "repoName": "default",
    "branchName": "[^(?!.*master)].*"
  },
  "description": "branch",
  "substitutions": {
    "_CLOUDSDK_COMPUTE_ZONE": "${ZONE}",
    "_CLOUDSDK_CONTAINER_CLUSTER": "${CLUSTER}"
  },
  "filename": "builder/cloudbuild-dev.yaml"
}
EOF

curl -X POST \
    https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud config config-helper --format='value(credential.access_token)')" \
    --data-binary @branch-build-trigger.json

cat <<EOF > master-build-trigger.json
{
  "triggerTemplate": {
    "projectId": "${PROJECT}",
    "repoName": "default",
    "branchName": "master"
  },
  "description": "master",
  "substitutions": {
    "_CLOUDSDK_COMPUTE_ZONE": "${ZONE}",
    "_CLOUDSDK_CONTAINER_CLUSTER": "${CLUSTER}"
  },
  "filename": "builder/cloudbuild-canary.yaml"
}
EOF


curl -X POST \
    https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud config config-helper --format='value(credential.access_token)')" \
    --data-binary @master-build-trigger.json
    
    
cat <<EOF > tag-build-trigger.json
{
  "triggerTemplate": {
    "projectId": "${PROJECT}",
    "repoName": "default",
    "tagName": ".*"
  },
  "description": "tag",
  "substitutions": {
    "_CLOUDSDK_COMPUTE_ZONE": "${ZONE}",
    "_CLOUDSDK_CONTAINER_CLUSTER": "${CLUSTER}"
  },
  "filename": "builder/cloudbuild-prod.yaml"
}
EOF


curl -X POST \
    https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud config config-helper --format='value(credential.access_token)')" \
    --data-binary @tag-build-trigger.json

    
    
###########new branch
git checkout -b new-feature
sed -i  's/blue/orange/g' html.go
sed -i  's/1.0.0/2.0.0/g' main.go

git add html.go main.go
git commit -m "Version 2.0.0"
git push gcp new-feature

sleep 60 
echo please visit https://console.cloud.google.com/gcr/builds 


kubectl get service gceme-frontend -n new-feature


export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}" --namespace=new-feature services gceme-frontend)

curl http://$FRONTEND_SERVICE_IP/version



