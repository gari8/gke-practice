#!/bin/zsh

export PROJECT_ID=stately-lodge-375906
export REGION=asia-northeast1
export TERRAFORM_BUCKET_NAME=stately-lodge-375906-tfstate
gcloud config set project ${PROJECT_ID}

gcloud container clusters get-credentials private --region $REGION --project $PROJECT_ID
kubectl create namespace wordpress

sed "s/<PROJECT_ID>/$PROJECT_ID/g;" ../k8s/base/service-account.yaml > ../k8s/data/service-account.yaml

kubectl create -f ../k8s/data/service-account.yaml -n wordpress

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[wordpress/cloud-sql-access]" \
  cloud-sql-access@$PROJECT_ID.iam.gserviceaccount.com

sed "s/<CLOUD_SQL_PROJECT_ID>/$PROJECT_ID/g;s/<CLOUD_SQL_INSTANCE_NAME>/$(terraform output cloud_sql_instance_name | tr -d '"')/g;s/<CLOUD_SQL_REGION>/$REGION/g;" ../k8s/base/config-map.yaml > ../k8s/data/config-map.yaml

kubectl create -f ../k8s/data -n wordpress

kubectl create secret generic mysql \
    --from-literal=password=$(gcloud secrets versions access latest --secret=wordpress-admin-user-password --project $PROJECT_ID) -n wordpress

gcloud compute addresses create wordpress --global
kubectl create -f ../k8s/web -n wordpress
kubectl get pods -l app=wordpress -n wordpress

