terraform {
  # these come from the backend directory
  backend "s3" {
    encrypt        = true
    key            = "path/to/state"
    use_lockfile = true
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}