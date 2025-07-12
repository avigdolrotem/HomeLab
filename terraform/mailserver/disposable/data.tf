data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "your-bucket"
    key    = "tfstate/mailserver/foundation.tfstate"
    region = "eu-central-1"
  }
}

# Get the bucket name as a string (for use in backup scripts, envs, etc)
locals {
  mail_backup_bucket_name = data.terraform_remote_state.foundation.outputs.mail_backup_bucket_name
  mail_backup_bucket_prefix = data.terraform_remote_state.foundation.outputs.mail_backup_bucket_prefix
}

data "aws_iam_instance_profile" "mailserver" {
  name = data.terraform_remote_state.foundation.outputs.mailserver_instance_profile_name
}
