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

variable "es_dedicated_master_nodes_amount" {
  description = "The amount of dedicated masters to bootstrap the cluster with, changing this after deployment will destroy the cluster"
  type        = number
  default     = 3
}

variable "elasticsearch_version" {
  description = "Elasticsearch version to install"
  type        = string
  default     = "7.10.0"
}

variable "elasticsearch_cluster_name" {
  description = "Elasticsearch cluster name"
  type        = string
  default     = "dev"
}

variable "es_data_nodes_amount" {
  description = "The amount of data nodes to deploy"
  type        = number
  default     = 2
}

variable "is_data_node_master_eligible" {
  description = "True will configre data nodes role as backup master"
  type        = bool
  default     = false
}

variable "instances_domain_name" {
  description = "EC2 hostname suffix- domain name"
  type        = string
  default     = "elasticsearch"
}