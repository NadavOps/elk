#!/bin/bash

#### changing hostname
hostnamectl set-hostname name???

#### installing java, installing kibana and registering it to systemd
sudo apt update -y
sudo apt install openjdk-11-jdk -y
kibana_version=${kibana_version_input}
curl -L -O https://artifacts.elastic.co/downloads/kibana/kibana-$kibana_version-amd64.deb
sudo dpkg -i kibana-$kibana_version-amd64.deb
rm -rf kibana-$kibana_version-amd64.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service

#### configuring jvm.options to 2g heapsize, saving elasticsearch.yml defaults configuration, configuring elastic.yml
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
##### does kibana heap setup is also at the elasticsearch path?
half_machine_ram=$(free -h | grep Mem | awk '{print $2/2}' | cut -d "." -f1)
sed -i 's/1g/'$half_machine_ram'g/g' /etc/elasticsearch/jvm.options


#### save default configurations and make new ones
cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.defaults
cat << EOF > /etc/kibana/kibana.yml
server.host: "${LOCAL_IPV4}"  #### check what this is?????
elasticsearch.hosts: ["http://??????:9200"] ###### need to put the data nodes here
logging.timezone: UTC
csp.strict: true
EOF

#### Verify kibana user have the permissions, and starting kibana
chown -R kibana:kibana /etc/kibana
sudo systemctl start kibana.service