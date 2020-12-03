# elk
The ELK stack

# git@github.com:NadavOps/terraform.git//aws/networking/security_groups
# git@github.com:NadavOps/terraform.git//aws/compute/ec2-instance

## need to handle discovery.zen.minimum_master_nodes:
## https://www.elastic.co/guide/en/elasticsearch/guide/2.x/important-configuration-changes.html#_minimum_master_nodes


## need to test what happends if dedicated master fails

## does dedicated nodes really need the entire seed nodes? i think not but need to think it over


## go over this https://www.elastic.co/blog/running-elasticsearch-on-aws

## try opster!!


## need to rewrite with having different scenarios as described in information:
# 3 dedicated out the bat and dedicated datas
# small cluster of master/ data of 3 nodes all in one
# also need to diffrentiate between inital bootstrap cluster to dedicated masters joining after failure



## do one template for dedicated master, master, data, data-master
## add cluster prefix to names
## validate clustering for all
## it can be done if instead passing terraform variables of every new instance, but to tell the script to dig records from unchanged domain
## need to add conditional for nodes that change the minimum master eligible for election


## function dns making and iam role

## fix master counting- doesnt work