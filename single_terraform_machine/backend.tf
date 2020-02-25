terraform {
  backend "s3" {
    bucket = "alvindpdevops"
    key    = "terraform_states"
    region = "eu-west-1"
  }
}