#!/bin/zsh

export PROJECT_ID=gke-app-artifacts
export REGION=asia-northeast1
export CLUSTER_NAME=private
gcloud config set project ${PROJECT_ID}

gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

## ここterraformでいけないかな？
kubectl create secret generic mysql \
    --from-literal=password=$(gcloud secrets versions access latest --secret=app-admin-user-password --project $PROJECT_ID) -n app

kubectl create -f ../manifests/web -n app
kubectl get pods -l app=app -n app

