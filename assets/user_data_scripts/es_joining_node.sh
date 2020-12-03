#!/bin/bash
#### changing hostname
hostnamectl set-hostname ${es_node_main_role}${index}.${domain}

#### installing java, installing elasticsearch and registering it to systemd
sudo apt update -y
sudo apt install openjdk-11-jdk -y
elasticsearch_version=${elasticsearch_version}
curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$elasticsearch_version-amd64.deb
sudo dpkg -i elasticsearch-$elasticsearch_version-amd64.deb
rm -rf elasticsearch-$elasticsearch_version-amd64.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

#### configuring jvm.options to 2g heapsize, saving elasticsearch.yml defaults configuration, configuring elastic.yml
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
half_machine_ram=$(free -h | grep Mem | printf %.0f $(awk '{printf $2/2}'))
sed -i 's/1g/'$half_machine_ram'g/g' /etc/elasticsearch/jvm.options
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.unused.defaults

cat << EOF > /etc/elasticsearch/elasticsearch.yml
## Cluster
cluster.name: ${elasticsearch_cluster_name}

## Node
node.name: ${es_node_main_role}${index}.${domain}

node.roles: [ ${joining_node_roles} ]
# Add custom attributes to the node, for example: node.attr.rack: r1

## Paths, changing the defaults so reinstallation will not overwrite data
path.data: /etc/elasticsearch/state_elasticsearch_data
path.logs: /etc/elasticsearch/state_elasticsearch_logs

## Network
network.host: ["localhost", "$LOCAL_IPV4"]

## Cluster Bootstrap
discovery.seed_hosts: [${discovery_seed_hosts}]
EOF

#### Verify elasticsearch user have the permissions, and starting elasticsearch
chown -R elasticsearch:elasticsearch /etc/elasticsearch
sudo /etc/init.d/elasticsearch start

#### Sets dynamically the required number of master eligible nodes by the cluster for elections
#### The rule is N/2 + 1
sleep 20
master_eligible_nodes=$(expr $(curl -s "localhost:9200/_cat/nodes?v&h=master" | wc -l) - 1)
let "required_master_eligible_nodes_for_elections = $master_eligible_nodes/2 + 1"
curl -X PUT localhost:9200/_cluster/settings -H "Content-Type: application/json" -d'
{
    "persistent" : {
        "discovery.zen.minimum_master_nodes" : '$required_master_eligible_nodes_for_elections'
    }
}'