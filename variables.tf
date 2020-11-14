variable "aws_region" {
  description = "The region in AWS to deploy into"
  type        = string
}

variable "aws_credentials_profile" {
  description = "AWS credentials profile name to use, profiles are usually in ~/.aws/credentials"
  type        = string
}

variable "vpc_id" {
  description = "The VPC to deploy elasticsearch into"
  type        = string
}




#######
variable "security_groups_list" {
  # example [ ["sg1", "description1"], ["sg2", "description2"] ]
  description = "Names and description of the security groups to be created for ELK"
  type        = list(list(string))
}