terraform {
  required_version = "~> 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket       = "demo-bucket-jdu7z2q2"
    region       = "ru-central1"
    key          = "terraform.tfstate"
    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}
