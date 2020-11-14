## Required
variable "aws_provider_main_region" {
  description = "Region of deployment"
  type        = string
}

variable "aws_credentials_profile" {
  description = "Profile name with the credentials to run. profiles usually are found at ~/.aws/credentials"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy in"
  type        = string
}

variable "aws_keypair" {
  description = "The SSH key to connect with to EC2s"
  type        = string
}

variable "subnet_ids" {
  description = "The subnets to deploy in"
  type        = list(string)
}

variable "ssh_ips" {
  description = "Allowed ips to ssh into the instances"
  type        = list(string)
}

## Optional
# miscellaneous
variable "elasticsearch_cluster_name" {
  description = "Elasticsearch cluster name"
  type        = string
  default     = "dev"
}

variable "instances_domain_name" {
  description = "EC2 hostname suffix- domain name"
  type        = string
  default     = "elasticsearch"
}

variable "elasticsearch_version" {
  description = "Elasticsearch version to install"
  type        = string
  default     = "7.10.0"
}
# amount of node types
variable "es_initial_master_nodes_amount" {
  description = "The amount of dedicated masters to bootstrap the cluster with"
  type        = number
  default     = 3
}

variable "es_dedicated_master_nodes_amount" {
  description = "The amount of dedicated masters to add to a running ES cluster"
  type        = number
  default     = 0
}

variable "es_data_master_nodes_amount" {
  description = "The amount of nodes acting bot as data and master to add to a running ES cluster"
  type        = number
  default     = 0
}

variable "es_dedicated_data_nodes_amount" {
  description = "The amount of dedicated data nodes to add to a running ES cluster"
  type        = number
  default     = 2
}