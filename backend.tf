terraform {
  # S3 backend works here because Yandex Object Storage is S3-compatible
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "dibok396-terraform-states-bucket"
    region = "ru-central1"
    key    = "terraform-yc-app-template/production/terraform.tfstate"

    # Skip AWS-specific checks that do not apply to Yandex Object Storage
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
