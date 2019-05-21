terraform {
  backend "S3" {
    bucket  = "mdssplitziz"
    encrypt = true
    key     = "live/eu-west-2/database/terraform.state"
    region  = "eu-west-2"
  }
}
