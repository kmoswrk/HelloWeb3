#!/bin/sh
# enterShell.sh
ENV_FILE="${DEVENV_ROOT}/.env" # DEVENV_ROOT is provided by devenv

if [ -f "$ENV_FILE" ]; then
  echo "Sourcing environment variables from $ENV_FILE"
  # Temporarily enable automatic export of all variables defined or modified
  set -a
  # Source the .env file. This handles quotes, spaces, and comments correctly.
  . "$ENV_FILE"
  # Disable automatic export
  set +a
else
  echo "ERROR: Environment file $ENV_FILE not found!"
  echo "Please copy .env.template to .env and fill in all required values."
  exit 1
fi

# Check for essential variables after attempting to source .env
CRITICAL_VARS_MISSING=false
check_var() {
  local var_name="$1"
  local placeholder="$2"
  local value # Will be assigned by eval
  eval "value=\$$var_name" # Get var value, handles special chars in var_name if any

  if [ -z "$value" ]; then
    echo "ERROR: Essential environment variable $var_name is not set. Please define it in $ENV_FILE."
    CRITICAL_VARS_MISSING=true
  elif [ "$value" = "$placeholder" ]; then
    echo "ERROR: Essential environment variable $var_name is set to its placeholder value ('$placeholder'). Please update it in $ENV_FILE."
    CRITICAL_VARS_MISSING=true
  fi
}

check_var "GCP_PROJECT_ID" "your-gcp-project-id-here"
check_var "GCP_REGION" "your-gcp-region-here"
check_var "POLYGONSCAN_API_KEY" "your-polygonscan-api-key-here"
# Add more checks here if needed, e.g., for TF_VAR_gcp_project_id if you want to be extra strict
# check_var "TF_VAR_gcp_project_id" "your-gcp-project-id-here"
# check_var "TF_VAR_gcp_region" "your-gcp-region-here"

if [ "$CRITICAL_VARS_MISSING" = "true" ]; then
  echo "--------------------------------------------------------------------"
  echo "ACTION REQUIRED: Critical environment variables are missing or not configured correctly in $ENV_FILE."
  echo "Exiting shell. Please fix $ENV_FILE and try again."
  echo "--------------------------------------------------------------------"
fi


echo "Welcome to Dev Environment!"
echo "Node.js version: $(node --version), pnpm version: $(pnpm --version)"
echo "Terraform version: $(terraform --version)"
echo "Docker version: $(docker --version)"
echo "kubectl version: $(kubectl version --client=true)"
echo "gcloud version: $(gcloud --version | head -n 1)"

if [ -n "$CLOUDSDK_CONFIG" ] && [ -d "$CLOUDSDK_CONFIG" ]; then
  echo "gcloud config is isolated to: $CLOUDSDK_CONFIG"
  PROJECT=$(gcloud config get-value project 2>/dev/null)
  ACCOUNT=$(gcloud config get-value account 2>/dev/null)
  if [ -z "$PROJECT" ] || [ -z "$ACCOUNT" ]; then
    echo "NOTICE: GCP project or account not fully configured in $CLOUDSDK_CONFIG."
    echo "        Run 'gcp-init' to check and set up."
  else
    echo "GCP Project: $PROJECT, Account: $ACCOUNT"
  fi
else
  echo "Warning: CLOUDSDK_CONFIG is not set or directory does not exist. gcloud will use global config."
fi
# echo "Run 'gcp-init' to verify or initialize GCP settings for this project."

# This part needs special handling if you want to keep it dynamic
# See option B below for how to pass this from Nix
echo "Available scripts: devenv script | $DEVENV_SCRIPTS_LIST"
