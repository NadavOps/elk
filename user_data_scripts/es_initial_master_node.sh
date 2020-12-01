#!/bin/bash
#### changing hostname
hostnamectl set-hostname master${index}.${domain}

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
node.name: master${index}.${domain}

node.roles: [ master ]
# Add custom attributes to the node, for example: node.attr.rack: r1

## Paths, changing the defaults so reinstallation will not overwrite data
path.data: /etc/elasticsearch/state_elasticsearch_data
path.logs: /etc/elasticsearch/state_elasticsearch_logs

## Network
network.host: ["localhost", "$LOCAL_IPV4"]

## Cluster Bootstrap
discovery.seed_hosts: [${discovery_seed_hosts}]
cluster.initial_master_nodes: [${masters_dns_records}]
EOF

#### Verify elasticsearch user have the permissions, and starting elasticsearch
chown -R elasticsearch:elasticsearch /etc/elasticsearch
sudo /etc/init.d/elasticsearch start

#### Validate successful clustering and removing cluster.initial_master_nodes
#### https://www.elastic.co/guide/en/elasticsearch/reference/master/important-settings.html
for interval in {1..36}
do
    es_running_nodes=$(curl -s localhost:9200/_cat/nodes | wc -l)
    if [[ $es_running_nodes -gt 1 ]]; then
        echo "More than one node found ($es_running_nodes). assuming successful clustering, removing initial_master_nodes"
        sed -i '/cluster.initial_master_nodes/d' /etc/elasticsearch/elasticsearch.yml
        break
    fi
    echo "number of nodes: $es_running_nodes, clustering unsucessful, rechecking in 10 seconds"
    sleep 10
done

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