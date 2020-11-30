output "elasticsearch_master_nodes" {
  value = { for instance in module.es_dedicated_master_nodes :
  instance.ec2_tags.Name => "ssh -i ~/.ssh/${var.aws_keypair} ubuntu@${instance.ec2_public_ip}" }
}

output "elasticsearch_data_nodes" {
  value = { for instance in module.es_data_nodes :
  instance.ec2_tags.Name => "ssh -i ~/.ssh/${var.aws_keypair} ubuntu@${instance.ec2_public_ip}" }
}