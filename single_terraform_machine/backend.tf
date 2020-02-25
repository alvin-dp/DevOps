terraform {
  backend "s3" {
    bucket = "alvindpdevops"
    key    = "terraform_states/state"
    region = "eu-west-1"
  }
}