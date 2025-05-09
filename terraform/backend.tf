terraform {
  backend "gcs" {
    # IMPORTANT: This bucket name should match the one created by your
    # 'setup-tf-backend-bucket' script, which typically derives it from
    # your GCP_PROJECT_ID.
    # Ensure your GCP_PROJECT_ID in .env results in this bucket name,
    # or update this bucket name accordingly.
    bucket = "grounded-pivot-459013-d1-pgn-mon-tfstate"
    prefix = "gke" # Or your desired prefix for this specific state
  }
}
