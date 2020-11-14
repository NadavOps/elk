# The ELK stack
The project currently allows fairly easily to create an elasticsearch cluster of master and data nodes. \
There are 4 ES node types in the eyes of this project:
1. es_initial_master_node; the first node to bootstrap the cluster. \
    this node is required for every first setup to bootstrap the cluster. for deployments require redundancy don't spin more than one of this type, \
    but rather spin along it dedicated masters, which are easier to maintain with this terraform project.
2. es_dedicated_master_node; nodes for master duties only
3. es_data_master_node; nodes for both master and data roles
4. es_dedicated_data_node; data only node

Configuration for 2 different scenarios:
1. Budget is not an issue, redundancy and performace are critical
```
es_initial_master_nodes_amount   = 1
es_dedicated_master_nodes_amount = 2
es_data_master_nodes_amount      = 0
es_dedicated_data_nodes_amount   = 2 (for the very least)
```
2. Budget constraints, will require to have mix nondes, \
   in this way we still maintain redundancy and as long no problems arise performance is good
```
es_initial_master_nodes_amount   = 1
es_dedicated_master_nodes_amount = 0
es_data_master_nodes_amount      = 2
es_dedicated_data_nodes_amount   = 0
```

here is a way to use this project as a module:
```
module "elk" {
    source                   = "git@github.com:NadavOps/elk.git"
    aws_provider_main_region = aws region 
    aws_credentials_profile  = credentials profile name
    vpc_id                   = vpc id

    aws_keypair = name of ec2 key
    subnet_ids  = [subnet ids]
    ssh_ips     = [allowed ips]

    es_initial_master_nodes_amount   = 1
    es_dedicated_master_nodes_amount = 0
    es_data_master_nodes_amount      = 0
    es_dedicated_data_nodes_amount   = 2
}
```

This project relies on: \
git@github.com:NadavOps/terraform.git//aws/networking/security_groups \
git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance

The project still requires more work including:
1. Kibana
2. Logstash
3. Test it with opster -->> https://checkups.opster.com/input
4. formalize into terraform modules
5. more options for initial in elk app configurations