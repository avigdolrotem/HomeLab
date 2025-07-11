data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "homelab-874888505976"
    key    = "tfstate/vaultwarden/foundation.tfstate"
    region = "eu-central-1"
  }
}

locals {
  db_endpoint                     = data.terraform_remote_state.foundation.outputs.db_endpoint
  db_username                     = data.terraform_remote_state.foundation.outputs.db_username
  db_password                     = data.terraform_remote_state.foundation.outputs.db_password
  db_name                         = data.terraform_remote_state.foundation.outputs.db_name
}

data "aws_iam_instance_profile" "vaultwarden" {
  name = data.terraform_remote_state.foundation.outputs.vaultwarden_instance_profile_name
}
