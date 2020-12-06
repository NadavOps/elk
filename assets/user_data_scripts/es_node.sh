#!/bin/bash
#### changing hostname
hostnamectl set-hostname ${es_cluster_name}-${es_node_description}${index}.${domain}

#### installing java, installing elasticsearch and registering it to systemd
sudo apt update -y
sudo apt install openjdk-11-jdk -y
elasticsearch_version=${es_version}
curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$elasticsearch_version-amd64.deb
sudo dpkg -i elasticsearch-$elasticsearch_version-amd64.deb
rm -rf elasticsearch-$elasticsearch_version-amd64.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

#### Query AWS DNS periodically to find 3 masters for ES discovery using file -> /etc/elasticsearch/unicast_hosts.txt
apt install -y awscli jq
cat << 'EOF' > /etc/elasticsearch/discovery.sh
for interval in {1..18}
do
    records_raw=$(aws route53 list-resource-record-sets --hosted-zone-id ${route53_es_zone_id} --query "ResourceRecordSets[?Type == 'A']")
    records_names=$(echo $records_raw | jq -r .[].Name | rev | cut -c 2- | rev | tr " " "\n" | sort -r)
    for record in $records_names
    do
        cluster_name_prefix=$(echo $record | cut -d "-" -f1)
        node_name_suffix=$(echo $record | cut -d "-" -f2)
        record_status=$(curl -s -o /dev/null -w "%%{http_code}" $record:9200)
        if [[ $cluster_name_prefix == ${es_cluster_name} && $node_name_suffix == *"master"* && $record_status -eq 200 ]]
        then
            echo "Adding $record to /tmp/temp_unicast_hosts.txt"
            echo $record >> /tmp/temp_unicast_hosts.txt
            if [[ $(wc -l < /tmp/temp_unicast_hosts.txt) -gt 2 ]]; then break; fi
        fi
    done
    if [[ -f /tmp/temp_unicast_hosts.txt && $(wc -l < /tmp/temp_unicast_hosts.txt) -ge 1 ]]; then break; fi
    echo "didn't found any masters. Attempt $interval/18, sleeping 10 and retrying"
    sleep 10
done

if [[ -f /tmp/temp_unicast_hosts.txt ]]
then
    echo "Creating /etc/elasticsearch/unicast_hosts.txt and removing /tmp/temp_unicast_hosts.txt"
    cat /tmp/temp_unicast_hosts.txt > /etc/elasticsearch/unicast_hosts.txt
    rm -f /tmp/temp_unicast_hosts.txt
fi
EOF
if [[ ${es_node_description} == *"initial"* ]]; then touch /etc/elasticsearch/unicast_hosts.txt; fi
if [[ ${es_node_description} != *"initial"* ]]; then bash /etc/elasticsearch/discovery.sh; fi
echo "0 */12 * * * bash /etc/elasticsearch/discovery.sh" | crontab -

#### configuring jvm.options to 2g heapsize, saving elasticsearch.yml defaults configuration, configuring elastic.yml
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
half_machine_ram=$(free -h | grep Mem | printf %.0f $(awk '{printf $2/2}'))
sed -i 's/1g/'$half_machine_ram'g/g' /etc/elasticsearch/jvm.options
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.unused.defaults

cat << EOF > /etc/elasticsearch/elasticsearch.yml
## Cluster
cluster.name: ${es_cluster_name}

## Node
node.name: ${es_cluster_name}-${es_node_description}${index}.${domain}

node.roles: [ ${node_roles} ]
# Add custom attributes to the node, for example: node.attr.rack: r1

## Paths, changing the defaults so reinstallation will not overwrite data
path.data: /etc/elasticsearch/state_elasticsearch_data
path.logs: /etc/elasticsearch/state_elasticsearch_logs

## Network
network.host: ["localhost", "$LOCAL_IPV4"]

## Cluster Bootstrap
discovery.seed_providers: file
EOF

### Adding to elasticsearch the bootstrap configuration if it is a bootstrap run
if [[ ${es_node_description} == *"initial"* ]]
then
    echo "The node is an initial bootstrap node, adding relevant configuration (initial_master_nodes)"
    echo "cluster.initial_master_nodes: [${initial_masters_dns_records}]" >> /etc/elasticsearch/elasticsearch.yml
fi

#### Verify elasticsearch user have the permissions, and starting elasticsearch
chown -R elasticsearch:elasticsearch /etc/elasticsearch
sudo /etc/init.d/elasticsearch start

#### Validate successful clustering and removing cluster.initial_master_nodes
#### https://www.elastic.co/guide/en/elasticsearch/reference/master/important-settings.html
for interval in {1..36}
do
    es_running_nodes=$(curl -s localhost:9200/_cat/nodes | wc -l)
    if [[ $es_running_nodes -gt 1 ]]; then
        echo "More than one node found ($es_running_nodes). assuming successful clustering."
        if [[ ${es_node_description} == *"initial"* ]]
        then
            echo "The node is an initial bootstrap node, removing relevant configuration (initial_master_nodes)"
            sed -i '/cluster.initial_master_nodes/d' /etc/elasticsearch/elasticsearch.yml
        fi
        break
    fi
    echo "number of nodes: $es_running_nodes, clustering unsucessful. Attempt $interval/36, rechecking in 10 seconds"
    sleep 10
done

#### Sets dynamically the required number of master eligible nodes for the cluster elections
#### The rule is N/2 + 1
sleep 20
es_all_nodes_roles_raw=$(curl -s "localhost:9200/_cat/nodes?v&h=node.role")
es_all_nodes_roles=$(echo $es_all_nodes_roles_raw | cut -d " " -f2-)
echo "all node roles: $es_all_nodes_roles"
for node_roles in $es_all_nodes_roles
do
    if [[ $node_roles == *"m"* ]]; then master_eligible_nodes=$((master_eligible_nodes+1)); fi
done
echo "Number of master eligible nodes: $master_eligible_nodes"
let "required_master_eligible_nodes_for_elections = $master_eligible_nodes/2 + 1"
curl -X PUT localhost:9200/_cluster/settings -H "Content-Type: application/json" -d'
{
    "persistent" : {
        "discovery.zen.minimum_master_nodes" : '$required_master_eligible_nodes_for_elections'
    }
}'