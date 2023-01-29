#!/bin/sh

export PROJECT_ID=gke-app-artifacts
export REGION=asia-northeast1
export TERRAFORM_BUCKET_NAME=${PROJECT_ID}-tfstate
gcloud config set project ${PROJECT_ID}

gcloud services enable compute.googleapis.com \
  servicenetworking.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  iap.googleapis.com \
  run.googleapis.com \
  secretmanager.googleapis.com --project $PROJECT_ID

gsutil mb -p ${PROJECT_ID} -c standard -l ${REGION} gs://${TERRAFORM_BUCKET_NAME}
gsutil versioning set on gs://${TERRAFORM_BUCKET_NAME}

terraform init \
  -backend-config="bucket=${TERRAFORM_BUCKET_NAME}" \
  -backend-config="prefix=state"
