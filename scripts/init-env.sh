#!/bin/sh

export PROJECT_ID=gke-sql-linker
export REGION=asia-northeast1
export TERRAFORM_BUCKET_NAME=${PROJECT_ID}-tfstate
gcloud config set project ${PROJECT_ID}

gcloud services enable compute.googleapis.com \
  servicenetworking.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com --project $PROJECT_ID

gsutil mb -p ${PROJECT_ID} -c standard -l ${REGION} gs://${TERRAFORM_BUCKET_NAME}
gsutil versioning set on gs://${TERRAFORM_BUCKET_NAME}

gcloud secrets create app-admin-user-password --locations $REGION --replication-policy user-managed
echo -n "changeme" | gcloud beta secrets versions add app-admin-user-password --data-file=-

terraform init \
  -backend-config="bucket=${TERRAFORM_BUCKET_NAME}" \
  -backend-config="prefix=state"
