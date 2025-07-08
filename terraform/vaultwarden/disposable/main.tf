terraform {
  backend "s3" {
    bucket         = "homelab-874888505976"
    key            = "tfstate/vaultwarden/disposable.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "homelab-874888505976"
  }
}

# module "vpc" {
#   source                  = "../../modules/vpc"
#   vpc_cidr_block          = var.vpc_cidr_block
#   vpc_name                = var.vpc_name
#   subnet_cidr_block       = var.subnet_cidr_block
#   subnet_name             = var.subnet_name
#   availability_zone       = var.availability_zone
#   map_public_ip_on_launch = var.map_public_ip_on_launch
#   igw_name                = var.igw_name
#   route_table_name        = var.route_table_name
#   enable_dns_hostnames    = var.enable_dns_hostnames
#   enable_dns_support      = var.enable_dns_support
#   tags                    = var.tags
# }

# Use the Vaultwarden SG created in foundation
# module "vaultwarden_instance" {
#   source = "../../modules/ec2"
#   name = var.instance_name
#   ami                         = var.ami
#   instance_type               = var.instance_type
#   subnet_id                   = data.terraform_remote_state.foundation.outputs.subnet_id
  # vpc_security_group_ids      = [data.terraform_remote_state.foundation.outputs.vaultwarden_sg_id]
  # key_name                    = var.key_name
  # associate_public_ip_address = true
  # iam_instance_profile        = data.terraform_remote_state.foundation.outputs.vaultwarden_instance_profile_name
  # tags                        = var.tags
  # user_data                   = var.user_data # For Ansible or cloud-init
# }

module "vaultwarden_instance" {
  source                     = "../../modules/ec2"
  name                       = var.instance_name
  ami                        = var.ami
  instance_type              = var.instance_type
  subnet_id                  = data.terraform_remote_state.foundation.outputs.subnet_id
  security_group_ids         = [data.terraform_remote_state.foundation.outputs.vaultwarden_sg_id]
  key_name                   = var.key_name
  associate_public_ip_address = true
  user_data                  = var.user_data
  tags                       = var.tags
  iam_instance_profile       = data.terraform_remote_state.foundation.outputs.vaultwarden_instance_profile_name
}
