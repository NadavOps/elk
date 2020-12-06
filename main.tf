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

#### Initial ES masters
module "es_initial_master_nodes" {
  source                 = "git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance"
  for_each               = { for index in range(0, var.es_initial_master_nodes_amount) : index => "initial_master" }
  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = local.instance_types.initial_master_node
  key_name               = var.aws_keypair
  subnet_id              = element(var.subnet_ids, each.key)
  vpc_security_group_ids = [module.security_groups["elasticsearch"].sg_id]
  root_block_device      = local.root_block_device
  iam_instance_profile   = aws_iam_instance_profile.profile.id
  tags                   = { Name = "${each.value}${each.key + 1}" }
  user_data              = "./assets/user_data_scripts/es_node.sh"
  user_data_variables = {
    es_cluster_name             = var.elasticsearch_cluster_name
    es_node_description         = each.value
    index                       = each.key + 1
    domain                      = aws_route53_zone.elasticsearch_internal_zone.name
    es_version                  = var.elasticsearch_version
    route53_es_zone_id          = aws_route53_zone.elasticsearch_internal_zone.id
    node_roles                  = "master"
    initial_masters_dns_records = local.initial_masters_dns_records_list
  }
}
## Initial ES masters records
resource "aws_route53_record" "es_initial_master_nodes" {
  allow_overwrite = true
  for_each        = module.es_initial_master_nodes
  zone_id         = aws_route53_zone.elasticsearch_internal_zone.zone_id
  name            = "${var.elasticsearch_cluster_name}-${each.value.ec2_tags.Name}"
  type            = "A"
  ttl             = "60"
  records         = [each.value.ec2_private_ip]
}

#### Dedicated ES masters
module "es_dedicated_master_nodes" {
  source                 = "git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance"
  for_each               = { for index in range(0, var.es_dedicated_master_nodes_amount) : index => "dedicated_master" }
  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = local.instance_types.dedicated_master_node
  key_name               = var.aws_keypair
  subnet_id              = element(var.subnet_ids, each.key)
  vpc_security_group_ids = [module.security_groups["elasticsearch"].sg_id]
  root_block_device      = local.root_block_device
  iam_instance_profile   = aws_iam_instance_profile.profile.id
  tags                   = { Name = "${each.value}${each.key + 1}" }
  user_data              = "./assets/user_data_scripts/es_node.sh"
  user_data_variables = {
    es_cluster_name             = var.elasticsearch_cluster_name
    es_node_description         = each.value
    index                       = each.key + 1
    domain                      = aws_route53_zone.elasticsearch_internal_zone.name
    es_version                  = var.elasticsearch_version
    route53_es_zone_id          = aws_route53_zone.elasticsearch_internal_zone.id
    node_roles                  = "master"
    initial_masters_dns_records = ""
  }
}
## Dedicated ES masters records
resource "aws_route53_record" "es_dedicated_master_node" {
  allow_overwrite = true
  for_each        = module.es_dedicated_master_nodes
  zone_id         = aws_route53_zone.elasticsearch_internal_zone.zone_id
  name            = "${var.elasticsearch_cluster_name}-${each.value.ec2_tags.Name}"
  type            = "A"
  ttl             = "60"
  records         = [each.value.ec2_private_ip]
}

#### ES data-master nodes
module "es_data_master_nodes" {
  source                 = "git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance"
  for_each               = { for index in range(0, var.es_data_master_nodes_amount) : index => "data_master" }
  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = local.instance_types.data_master_node
  key_name               = var.aws_keypair
  subnet_id              = element(var.subnet_ids, each.key)
  vpc_security_group_ids = [module.security_groups["elasticsearch"].sg_id]
  root_block_device      = local.root_block_device
  iam_instance_profile   = aws_iam_instance_profile.profile.id
  tags                   = { Name = "${each.value}${each.key + 1}" }
  user_data              = "./assets/user_data_scripts/es_node.sh"
  user_data_variables = {
    es_cluster_name             = var.elasticsearch_cluster_name
    es_node_description         = each.value
    index                       = each.key + 1
    domain                      = aws_route53_zone.elasticsearch_internal_zone.name
    es_version                  = var.elasticsearch_version
    route53_es_zone_id          = aws_route53_zone.elasticsearch_internal_zone.id
    node_roles                  = "data, master"
    initial_masters_dns_records = ""
  }
}
## ES data-master records
resource "aws_route53_record" "es_data_master_node" {
  allow_overwrite = true
  for_each        = module.es_data_master_nodes
  zone_id         = aws_route53_zone.elasticsearch_internal_zone.zone_id
  name            = "${var.elasticsearch_cluster_name}-${each.value.ec2_tags.Name}"
  type            = "A"
  ttl             = "60"
  records         = [each.value.ec2_private_ip]
}

#### ES dedicated data nodes
module "es_dedicated_data_nodes" {
  source                 = "git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance"
  for_each               = { for index in range(0, var.es_dedicated_data_nodes_amount) : index => "data" }
  ami                    = data.aws_ami.ubuntu_18_04.id
  instance_type          = local.instance_types.dedicated_data_node
  key_name               = var.aws_keypair
  subnet_id              = element(var.subnet_ids, each.key)
  vpc_security_group_ids = [module.security_groups["elasticsearch"].sg_id]
  root_block_device      = local.root_block_device
  iam_instance_profile   = aws_iam_instance_profile.profile.id
  tags                   = { Name = "${each.value}${each.key + 1}" }
  user_data              = "./assets/user_data_scripts/es_node.sh"
  user_data_variables = {
    es_cluster_name             = var.elasticsearch_cluster_name
    es_node_description         = each.value
    index                       = each.key + 1
    domain                      = aws_route53_zone.elasticsearch_internal_zone.name
    es_version                  = var.elasticsearch_version
    route53_es_zone_id          = aws_route53_zone.elasticsearch_internal_zone.id
    node_roles                  = "data"
    initial_masters_dns_records = ""
  }
}

###### how to function this????
### iam
resource "aws_iam_role" "role" {
  name                  = "elasticsearch-${var.elasticsearch_cluster_name}-ec2-role"
  description           = "elasticsearch-${var.elasticsearch_cluster_name}-ec2-role"
  force_detach_policies = true
  assume_role_policy    = file("./assets/iam/ec2_role_trust_relationship.json")
  path                  = "/elasticsearch-${var.elasticsearch_cluster_name}/"

  #tags = local.general_tags
}

resource "aws_iam_instance_profile" "profile" {
  name = aws_iam_role.role.name
  role = aws_iam_role.role.name
  path = "/elasticsearch-${var.elasticsearch_cluster_name}/"
}

resource "aws_iam_policy" "policy" {
  name   = "elasticsearch-${var.elasticsearch_cluster_name}-route53"
  policy = templatefile("./assets/iam/es_permissions_policy.json", { zone_id = aws_route53_zone.elasticsearch_internal_zone.id })
  path   = "/elasticsearch-${var.elasticsearch_cluster_name}/"
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}