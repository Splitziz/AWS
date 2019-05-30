terraform {
  backend "s3" {
    bucket  = "mdssplitziz"
    encrypt = true
    key     = "live/eu-west-2/bastionWP/terraform.state"
    region  = "eu-west-2"
  }
}
