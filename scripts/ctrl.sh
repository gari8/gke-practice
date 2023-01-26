#!/bin/zsh

export PROJECT_ID=gke-sql-linker
export REGION=asia-northeast1
export TERRAFORM_BUCKET_NAME=${PROJECT_ID}-tfstate
gcloud config set project ${PROJECT_ID}

gcloud container clusters get-credentials private --region $REGION --project $PROJECT_ID
kubectl create namespace app

sed "s/<PROJECT_ID>/$PROJECT_ID/g;" ../manifests/base/service-account.yaml > ../manifests/data/service-account.yaml
sed "s/<CLOUD_SQL_PROJECT_ID>/$PROJECT_ID/g;s/<CLOUD_SQL_INSTANCE_NAME>/$(terraform output cloud_sql_instance_name | tr -d '"')/g;s/<CLOUD_SQL_REGION>/$REGION/g;" ../manifests/base/config-map.yaml > ../manifests/data/config-map.yaml

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[app/cloud-sql-access]" \
  cloud-sql-access@$PROJECT_ID.iam.gserviceaccount.com

kubectl create -f ../manifests/data -n app

kubectl create secret generic mysql \
    --from-literal=password=$(gcloud secrets versions access latest --secret=app-admin-user-password --project $PROJECT_ID) -n app

gcloud compute addresses create app --global
kubectl create -f ../manifests/web -n app
kubectl get pods -l app=app -n app

