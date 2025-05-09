{
  # Checks and helps initialize GCP configuration for the isolated devenv environment.
  gcp-init = {
    exec = ''
      echo "--- GCP Configuration Check (''${CLOUDSDK_CONFIG}) ---"

      # Ensure the config directory exists for subsequent commands
      mkdir -p "''${CLOUDSDK_CONFIG}"

      # Check if essential .env variables are set (they should be by enterShell.sh or dotenv)
      if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" = "your-gcp-project-id-here" ]; then
        echo "ERROR: GCP_PROJECT_ID is not set or is a placeholder in your .env file."
        echo "       Please configure it in .env and re-enter the devenv shell."
        exit 1
      fi
      if [ -z "$GCP_REGION" ] || [ "$GCP_REGION" = "your-gcp-region-here" ]; then
        echo "ERROR: GCP_REGION is not set or is a placeholder in your .env file."
        echo "       Please configure it in .env and re-enter the devenv shell."
        exit 1
      fi

      ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
      CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
      ADC_FILE="''${CLOUDSDK_CONFIG}/application_default_credentials.json"
      ADC_EXISTS="false"
      if [ -f "''${ADC_FILE}" ]; then
          ADC_EXISTS="true"
      fi

      echo "Active Account:      ''${ACTIVE_ACCOUNT:-Not logged in}"
      echo "Configured Project:  ''${CURRENT_PROJECT:-Not set}"
      echo "ADC File Exists:     ''${ADC_EXISTS} (''${ADC_FILE})"
      echo "--------------------------------------------------"

      NEEDS_ACTION=false

      if [ -z "''${ACTIVE_ACCOUNT}" ]; then
        echo "ACTION REQUIRED: No active gcloud account."
        echo "  Run: gcloud auth login --update-adc"
        NEEDS_ACTION=true
      fi

      if [ -z "''${CURRENT_PROJECT}" ]; then
        # GCP_PROJECT_ID is guaranteed to be set and not a placeholder here due to checks above
        echo "INFO: GCP project not set in gcloud config. Attempting to set project to ''${GCP_PROJECT_ID}' from .env..."
        gcloud config set project "''${GCP_PROJECT_ID}"
        if [ ''$? -eq 0 ]; then
          echo "SUCCESS: GCP project set to ''${GCP_PROJECT_ID}'."
          CURRENT_PROJECT="''${GCP_PROJECT_ID}"
        else
          echo "ERROR: Failed to set GCP project. Please set it manually:"
          echo "  Run: gcloud config set project ''${GCP_PROJECT_ID}"
          NEEDS_ACTION=true
        fi
      elif [ "''${CURRENT_PROJECT}" != "''${GCP_PROJECT_ID}" ]; then
        echo "WARNING: gcloud project (''${CURRENT_PROJECT}') differs from GCP_PROJECT_ID (''${GCP_PROJECT_ID}') in .env."
        echo "  Consider aligning them. To set gcloud project to match .env, run:"
        echo "  gcloud config set project ''${GCP_PROJECT_ID}"
        # NEEDS_ACTION=true # Optional: make this a required action
      fi


      if [ "''${ADC_EXISTS}" = "false" ] && [ -n "''${ACTIVE_ACCOUNT}" ]; then
          echo "INFO: Application Default Credentials (ADC) file not found."
          echo "  It's recommended to set this up for applications and Terraform."
          echo "  Consider running: gcloud auth application-default login"
          echo "  (If you ran 'gcloud auth login --update-adc' recently, this might already be handled)."
      fi

      if [ "''${NEEDS_ACTION}" = "false" ]; then
        echo "GCP configuration appears to be set up correctly for project ''${CURRENT_PROJECT}' with account ''${ACTIVE_ACCOUNT}'."
      else
        echo "--------------------------------------------------"
        echo "Please address the 'ACTION REQUIRED' or 'WARNING' items above."
      fi
      echo "--- End of GCP Configuration Check ---"
    '';
  };

  setup-tf-backend-bucket = {
    exec = ''
      set -e # Exit immediately if a command exits with a non-zero status.

      # Check if essential .env variables are set (they should be by enterShell.sh or dotenv)
      if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" = "your-gcp-project-id-here" ]; then
        echo "ERROR: GCP_PROJECT_ID is not set or is a placeholder in your .env file."
        echo "       Please configure it in .env and re-enter the devenv shell."
        exit 1
      fi
      if [ -z "$GCP_REGION" ] || [ "$GCP_REGION" = "your-gcp-region-here" ]; then
        echo "ERROR: GCP_REGION is not set or is a placeholder in your .env file."
        echo "       Please configure it in .env and re-enter the devenv shell."
        exit 1
      fi

      PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
      if [ -z "$PROJECT_ID" ]; then
        echo "ERROR: GCP Project ID not set in gcloud config."
        echo "Please run 'gcp-init' first to ensure your gcloud CLI is configured with a project."
        exit 1
      fi
      if [ "$PROJECT_ID" != "$GCP_PROJECT_ID" ]; then
        echo "ERROR: The active gcloud project ('$PROJECT_ID') does not match GCP_PROJECT_ID ('$GCP_PROJECT_ID') from .env."
        echo "       Please run 'gcp-init' to align them or manually run: gcloud config set project '$GCP_PROJECT_ID'"
        exit 1
      fi

      # Derive bucket name: replace dots with dashes and append a suffix
      # GCS bucket names must be globally unique, lowercase, numbers, dashes, underscores.
      # Project IDs can have colons (e.g. domain:project) which are invalid in bucket names.
      # We'll sanitize the project ID for bucket naming. Using PROJECT_ID from gcloud config.
      SANITIZED_PROJECT_ID=$(echo "''${PROJECT_ID}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
      BUCKET_SUFFIX="-pgn-mon-tfstate" # You can customize this suffix
      BUCKET_NAME="''${SANITIZED_PROJECT_ID}''${BUCKET_SUFFIX}"

      # Ensure bucket name is within GCS length limits (3-63 chars)
      if [ ''${#BUCKET_NAME} -gt 63 ]; then
        echo "ERROR: Derived bucket name ''${BUCKET_NAME}' is too long (''${#BUCKET_NAME} chars). Max 63."
        exit 1
      fi
      if [ ''${#BUCKET_NAME} -lt 3 ]; then
        echo "ERROR: Derived bucket name ''${BUCKET_NAME}' is too short (''${#BUCKET_NAME} chars). Min 3."
        exit 1
      fi

      BUCKET_URI="gs://''${BUCKET_NAME}"
      # GCP_REGION is guaranteed to be set and not a placeholder here due to checks above.
      REGION="$GCP_REGION"

      echo "--- Terraform Backend GCS Bucket Setup ---"
      echo "Project ID:          ''${PROJECT_ID}"
      echo "Derived Bucket Name: ''${BUCKET_NAME}"
      echo "Bucket URI:          ''${BUCKET_URI}"
      echo "Target Region:       ''${REGION}"
      echo "-------------------------------------------"
      echo ""
      echo "This script will attempt to create and configure the GCS bucket for Terraform state."
      echo "This is typically a one-time setup for your Terraform backend."
      # Prompt for confirmation
      read -p "Proceed with creating/configuring ''${BUCKET_URI}'? (y/N): " CONFIRM
      if ! [[ "''${CONFIRM}" =~ ^[yY](es)?$ ]]; then
          echo "Operation cancelled by user."
          exit 0
      fi

      # Check if bucket already exists
      if gsutil ls "''${BUCKET_URI}" >/dev/null 2>&1; then
        echo "INFO: Bucket ''${BUCKET_URI}' already exists."
      else
        echo "INFO: Creating bucket ''${BUCKET_URI}' in project ''${PROJECT_ID}' and region ''${REGION}'..."
        if gsutil mb -p "''${PROJECT_ID}" -l "''${REGION}" "''${BUCKET_URI}"; then
          echo "SUCCESS: Bucket ''${BUCKET_URI}' created."
        else
          echo "ERROR: Failed to create bucket ''${BUCKET_URI}'."
          echo "Possible reasons: Name conflict (globally unique), insufficient permissions, or invalid project/region."
          exit 1
        fi
      fi

      echo "INFO: Enabling versioning on ''${BUCKET_URI}'..."
      if gsutil versioning set on "''${BUCKET_URI}"; then
        echo "SUCCESS: Versioning enabled on ''${BUCKET_URI}'."
      else
        echo "ERROR: Failed to enable versioning on ''${BUCKET_URI}'."
        # Not exiting here, as the bucket might still be usable, but versioning is highly recommended.
      fi

      echo ""
      echo "--- ACTION REQUIRED ---"
      echo "Update your Terraform backend configuration (e.g., in terraform/backend.tf) to:"
      echo ""
      echo "terraform {"
      echo "  backend \"gcs\" {"
      echo "    bucket  = \"''${BUCKET_NAME}\""
      echo "    prefix  = \"gke\"  # Or your desired prefix for this specific state"
      echo "  }"
      echo "}"
      echo ""
      echo "After updating, run 'devenv script tf-init' (or 'cd terraform && terraform init')."
      echo "-----------------------"
    '';
    description = "Automatically derives and creates/configures a GCS bucket for Terraform state.";
  };

  kubeconfig-gke = {
    exec = ''
      set -e # Exit immediately if a command exits with a non-zero status.
      echo "--- Configuring kubectl for GKE Cluster ---"

      # Ensure we are in the terraform directory to access outputs
      # or that terraform is configured to run from the root.
      # For simplicity, assuming terraform commands are run from the terraform/ directory
      # or that the state is accessible globally if initialized from root.

      # Check if terraform is available
      if ! command -v terraform &> /dev/null; then
          echo "ERROR: terraform command could not be found. Is it in your PATH?"
          exit 1
      fi

      # Check if gcloud is available
      if ! command -v gcloud &> /dev/null; then
          echo "ERROR: gcloud command could not be found. Is it in your PATH?"
          exit 1
      fi

      # Check if CLOUDSDK_CONFIG is set and directory exists, to ensure gcloud uses isolated config
      if [ -z "$CLOUDSDK_CONFIG" ] || [ ! -d "$CLOUDSDK_CONFIG" ]; then
        echo "WARNING: CLOUDSDK_CONFIG is not set or directory does not exist."
        echo "         gcloud will use its global configuration. This might not be what you want for an isolated devenv."
        echo "         Consider running 'devenv script gcp-init' first."
        # Optionally, you could make this an error:
        # exit 1
      fi

      # Fetch Terraform outputs.
      # This assumes that `terraform init` has been run in the terraform directory
      # and the state backend is configured correctly.
      # We'll cd into the terraform directory to be safe.
      TERRAFORM_DIR="''${DEVENV_ROOT}/terraform" # Assuming terraform files are in DEVENV_ROOT/terraform
      if [ ! -d "$TERRAFORM_DIR" ]; then
        echo "ERROR: Terraform directory not found at $TERRAFORM_DIR"
        exit 1
      fi

      echo "Fetching GKE cluster details from Terraform outputs in $TERRAFORM_DIR..."

      CLUSTER_NAME=$(terraform -chdir="$TERRAFORM_DIR" output -raw polygon_monitor_gke_cluster_name 2>/dev/null || true)
      CLUSTER_REGION=$(terraform -chdir="$TERRAFORM_DIR" output -raw gcp_region 2>/dev/null || true)
      PROJECT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw gcp_project_id 2>/dev/null || true)

      # Validate fetched outputs
      if [ -z "$CLUSTER_NAME" ]; then
        echo "ERROR: Could not fetch 'gke_cluster_name' from Terraform outputs."
        echo "       Ensure 'terraform apply' has been run successfully and the output is defined."
        exit 1
      fi
      if [ -z "$CLUSTER_REGION" ]; then
        echo "ERROR: Could not fetch 'gcp_region' (for cluster region) from Terraform outputs."
        exit 1
      fi
      if [ -z "$PROJECT_ID" ]; then
        echo "ERROR: Could not fetch 'gcp_project_id' (for cluster project) from Terraform outputs."
        exit 1
      fi

      echo "Cluster Name:    $CLUSTER_NAME"
      echo "Cluster Region:  $CLUSTER_REGION"
      echo "Project ID:      $PROJECT_ID"
      echo ""
      echo "Attempting to get credentials for GKE cluster..."

      # The --project flag for get-credentials should be the project where the cluster resides.
      if gcloud container clusters get-credentials "$CLUSTER_NAME" \
          --region "$CLUSTER_REGION" \
          --project "$PROJECT_ID"; then
        echo ""
        echo "SUCCESS: kubectl has been configured to use the '$CLUSTER_NAME' cluster."
        echo "You can now use kubectl commands, e.g., 'kubectl get nodes'"
      else
        echo "ERROR: Failed to get GKE cluster credentials."
        echo "       Please check the gcloud command output above for details."
        echo "       Ensure your gcloud user has 'container.clusters.getCredentials' permission on the cluster."
        exit 1
      fi
      echo "--- kubectl configuration complete ---"
    '';
    description = "Configures kubectl to connect to the GKE cluster using Terraform outputs.";
  };

  # Initializes Terraform in the ./terraform directory.
  tf-init = {
    exec = "cd terraform && terraform init";
  };

  # Generates a Terraform execution plan and saves it to tfplan.
  tf-plan = {
    exec = "cd terraform && terraform plan -out=tfplan";
  };

  # Applies the Terraform plan stored in tfplan.
  tf-apply = {
    exec = "cd terraform && terraform apply tfplan";
  };

  # Builds the Docker image 'hello-web3-app' from the current directory.
  docker-build = {
    exec = "docker build -t hello-web3-app .";
  };

  # Runs the 'hello-web3-app' Docker container locally, exposing port 3000.
  # Requires POLYGONSCAN_API_KEY env var to be set.
  docker-run-local = {
    exec = ''
      if [ -z "$POLYGONSCAN_API_KEY" ] || [ "$POLYGONSCAN_API_KEY" = "your-polygonscan-api-key-here" ]; then
        echo "Error: POLYGONSCAN_API_KEY is not set or is a placeholder. Please set it in your .env file."
        exit 1
      fi
      docker run -p 3000:8080 --rm -e POLYGONSCAN_API_KEY="$POLYGONSCAN_API_KEY" hello-web3-app
    '';
  };
}
