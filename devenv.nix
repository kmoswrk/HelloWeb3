{
  pkgs,
  config,
  lib,
  ...
}: let
  nodejs = pkgs.nodejs_22;
in {
  packages = with pkgs; [
    # GCP
    google-cloud-sdk
    (google-cloud-sdk.withExtraComponents [pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin])
    gitleaks

    # IaC
    terraform
    # terragrunt # if you plan to use it

    # Kubernetes
    kubectl
    kubernetes-helm
    k9s # Highly recommended TUI for K8s

    # Containerization
    docker # For building and running containers locally

    # Application Development (Node.js)
    # nodejs # Provides node and npm
    # yarn # If you prefer yarn over npm

    # Utilities
    git
    gnutar # for tar commands
    gzip
    jq # for JSON processing
    curl # for testing HTTP endpoints
    watch # for observing changes
    # yq-go # for YAML processing
  ];
  # devenv.debug = true;

  # Language support
  languages = {
    javascript = {
      enable = true;
      package = nodejs;
      pnpm.enable = true;
    };
    terraform.enable = true;
  };

  # Environment variables
  # Secrets on .env file
  env = {
    CLOUDSDK_CONFIG = "${config.env.DEVENV_ROOT}/.gcloud_config";
    GOOGLE_APPLICATION_CREDENTIALS = "${config.env.DEVENV_ROOT}/.gcloud_config/application_default_credentials.json";
    DEVENV_SCRIPTS_LIST = lib.concatStringsSep ", " (lib.attrNames config.scripts);
  };

  # Load environment variables from .env file
  # DOESNT WORK WITH FLAKES AND DEVENV
  # dotenv.enable = true;

  # Scripts available in the shell
  scripts = import ./scripts.nix;

  processes.app = {
    exec = "node app.js";
  };

  # Pre-commit hooks
  pre-commit.hooks = {
    gitleaks = {
      enable = true;
      entry = "gitleaks protect --verbose --redact --staged";
    };

    alejandra.enable = true;
    terraform-format = {
      enable = true;
      entry = "terraform fmt -check -diff";
    };
    terraform-validate = {
      enable = true;
      name = "Terraform Syntax Validation";
      entry = "terraform -chdir=terraform validate";
      pass_filenames = false;
    };
    tflint.enable = true;
    yamlfmt = {
      enable = true;
      settings.lint-only = false;
    };
    check-json.enable = true;
    end-of-file-fixer.enable = true;
    trim-trailing-whitespace.enable = true;
  };

  enterShell = pkgs.lib.readFile ./enterShell.sh;
}
