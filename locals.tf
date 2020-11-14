data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_ami" "ubuntu_18_04" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  security_groups = {
    elasticsearch = {
      sg_name        = "ES node",
      sg_description = "Elasticsearch nodes",
      cidr_block_rule = {
        ssh = {
          type        = "ingress", from_port = 22, to_port = 22, protocol = "TCP",
          cidr_blocks = var.ssh_ips, description = "SSH from specified IPs"
        }
        elasticsearch_rest = {
          type        = "ingress", from_port = 9200, to_port = 9200, protocol = "TCP",
          cidr_blocks = [data.aws_vpc.vpc.cidr_block], description = "Elasticsearch REST all in vpc"
        }
        outbound = {
          type        = "egress", from_port = 0, to_port = 0, protocol = "-1",
          cidr_blocks = ["0.0.0.0/0"], description = "Allow all outbound traffic"
        }
      }
      self_sg_rules = {
        elasticsearch_discovery = {
          type     = "ingress", from_port = 9300, to_port = 9300,
          protocol = "TCP", description = "Elasticsearch discovery self"
        }
      }
    }
  }

  instance_types = {
    initial_master_node   = "t3a.small"
    dedicated_master_node = "t3a.small"
    data_master_node      = "t3a.small"
    dedicated_data_node   = "t3a.medium"
  }

  root_block_device = [{ volume_size = 15 }]

  initial_masters_dns_records_list = join(", ",
    [for index in range(1, var.es_initial_master_nodes_amount + 1) :
    "${var.elasticsearch_cluster_name}-initial_master${index}.${aws_route53_zone.elasticsearch_internal_zone.name}"]
  )
}