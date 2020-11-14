provider "aws" {
  region     = var.aws_region
  profile    = var.aws_credentials_profile
}

##################################################################################
# VPC Resources
##################################################################################

module "security_groups_and_rules" {
	source = "git@github.com:NadavOps/terraform.git//aws/networking/security_groups"
	vpc_id = var.vpc_id
	security_groups_list = var.security_groups_list
}