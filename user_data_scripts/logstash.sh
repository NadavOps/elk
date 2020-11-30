#!/bin/bash
#### changing hostname
hostnamectl set-hostname ???

#### installing java, installing logstash and registering it to systemd
sudo apt update -y
sudo apt install openjdk-11-jdk -y
logstash_version=${logstash_version_input}
curl -L -O https://artifacts.elastic.co/downloads/logstash/logstash-$logstash_version.deb
sudo dpkg -i logstash-$logstash_version.deb
rm -rf logstash-$logstash_version.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable logstash.service

#### configuring jvm.options to 2g heapsize
half_machine_ram=$(free -h | grep Mem | awk '{print $2/2}' | cut -d "." -f1)
sed -i 's/1g/'$half_machine_ram'g/g' /etc/logstash/jvm.options

#### save default configurations and make new ones
cp /etc/logstash/logstash.yml /etc/logstash/logstash.yml.unused.defaults
cat << EOF > /etc/logstash/logstash.yml
path.data: /var/lib/logstash
path.logs: /var/log/logstash
pipeline.ordered: auto
EOF

#### Verify logstash user have the permissions, and starting logstash
# /usr/share/logstash/bin/logstash -f /etc/logstash/test.conf
chown -R logstash:logstash /etc/logstash
sudo systemctl start logstash.service