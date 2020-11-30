provider "aws" {
  region  = var.aws_provider_main_region
  profile = var.aws_credentials_profile
}

#### Security groups
module "security_groups" {
  source           = "git@github.com:NadavOps/terraform.git//aws/networking/security_groups"
  for_each         = local.security_groups
  sg_name          = each.value.sg_name
  sg_description   = each.value.sg_description
  vpc_id           = var.vpc_id
  cidr_block_rules = contains(keys(each.value), "cidr_block_rule") ? each.value.cidr_block_rule : {}
  self_sg_rules    = contains(keys(each.value), "self_sg_rules") ? each.value.self_sg_rules : {}
}

### create internal dns zone
resource "aws_route53_zone" "elasticsearch_internal_zone" {
  name = var.instances_domain_name

  vpc {
    vpc_id = var.vpc_id
  }
}

#### Dedicated ES masters
module "es_dedicated_master_nodes" {
  source                 = "git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance"
  for_each               = { for index in range(1, var.es_dedicated_master_nodes_amount + 1) : index => "master" }
  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = local.instance_types.dedicated_master_node
  key_name               = var.aws_keypair
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = [module.security_groups["elasticsearch"].sg_id]
  root_block_device      = local.root_block_device
  tags                   = { Name = "${each.value}${each.key}" }
  user_data              = "./user_data_scripts/es_initial_master_node.sh"
  user_data_variables = {
    index                      = each.key
    domain                     = aws_route53_zone.elasticsearch_internal_zone.name
    elasticsearch_version      = var.elasticsearch_version
    elasticsearch_cluster_name = var.elasticsearch_cluster_name
    masters_dns_records = local.dedicated_masters_dns_records_list
    discovery_seed_hosts = local.discovery_seed_hosts
  }
}
## Dedicated ES masters records
resource "aws_route53_record" "es_dedicated_master_node" {
  allow_overwrite = true
  for_each        = module.es_dedicated_master_nodes
  zone_id         = aws_route53_zone.elasticsearch_internal_zone.zone_id
  name            = each.value.ec2_tags.Name
  type            = "A"
  ttl             = "60"
  records         = [each.value.ec2_private_ip]
}

#### ES data nodes, can be used as master backup
module "es_data_nodes" {
  source                 = "git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance"
  for_each               = { for index in range(1, var.es_data_nodes_amount + 1) : index => "data" }
  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = local.instance_types.data_node
  key_name               = var.aws_keypair
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = [module.security_groups["elasticsearch"].sg_id]
  root_block_device      = local.root_block_device
  tags                   = { Name = "${each.value}${each.key}" }
  user_data              = "./user_data_scripts/es_joining_node.sh"
  user_data_variables = {
    index                      = each.key
    es_node_main_role          = each.value
    domain                     = aws_route53_zone.elasticsearch_internal_zone.name
    elasticsearch_version      = var.elasticsearch_version
    elasticsearch_cluster_name = var.elasticsearch_cluster_name
    masters_dns_records = local.dedicated_masters_dns_records_list
    discovery_seed_hosts = local.discovery_seed_hosts
    joining_node_roles = join(
      ", ", compact([each.value, var.is_data_node_master_eligible ? "master" : ""])
    )
  }
}
## Backup ES masters records (Data node primary role)
resource "aws_route53_record" "es_data_backup_master_node" {
  allow_overwrite = true
  for_each        = var.is_data_node_master_eligible ? module.es_data_nodes : {}
  zone_id         = aws_route53_zone.elasticsearch_internal_zone.zone_id
  name            = each.value.ec2_tags.Name
  type            = "A"
  ttl             = "60"
  records         = [each.value.ec2_private_ip]
}