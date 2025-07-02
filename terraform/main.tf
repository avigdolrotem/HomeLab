module "vpc" {
  source            = "./modules/vpc"
  vpc_cidr_block    = var.vpc_cidr_block
  vpc_name          = var.vpc_name
  subnet_cidr_block = var.subnet_cidr_block
  subnet_name       = var.subnet_name
  availability_zone = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
  igw_name          = var.igw_name
  route_table_name  = var.route_table_name
  tags              = var.tags
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
}

module "vaultwarden_sg" {
  source         = "./modules/security_group"
  name           = var.sg_name
  description    = var.sg_description
  vpc_id         = module.vpc.vpc_id
  ingress_rules  = var.ingress_rules
  egress_rules   = var.egress_rules
  tags           = var.tags
}

module "vaultwarden_instance" {
  source                     = "./modules/ec2"
  name                       = var.instance_name
  ami                        = var.ami
  instance_type              = var.instance_type
  subnet_id                  = module.vpc.subnet_id
  security_group_ids         = [module.vaultwarden_sg.security_group_id]
  key_name                   = var.key_name
  associate_public_ip_address = true
  user_data                  = file(var.user_data)
  tags                       = var.tags
}
