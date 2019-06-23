# Snort-Capstone
This project is capstone project about Snort with ELK on Docker. It's based on my knownledge therefore it should not be used in production environment.

# Environment
**Snort**:CentOS 7
 lan1: 192.168.3.1
 lan2: 192.168.4.1
**Logserver**:Ubuntu 18.04
 lan1: 192.168.4.2
 
# 1.Tools use in this project:
- Snort (3.0)
- OpenAppID
- Elasticsearch (7.1.1)
- Logstash (7.1.1)
- Filebeat (7.1.1)
- Kibana (7.1.1)
# 2.Install Snort
Change some configure in snort.lua (/etc/snort/etc/snort/snort.lua).
```
appid =
{
    log_stats = true,
    app_detector_dir = 'ODP'
}

alert_json =
{
    fields = 'timestamp pkt_num proto pkt_gen pkt_len dir src_addr src_port dst_addr dst_port service rule priority class action b64_data'
}
```
**ODP** is the path where you installed Open App ID.  Note this path does not include the trailing /odp.
**Run Snort**
```
INSTALL/bin/snort \
-c INSTALL/etc/snort/snort.lua \
-R RULES/snort3-community.rules \
--plugin-path INSTALL/lib64 \ 
-i lan1 \
-A json -y -q > alerts.json
```
**INSTALL** is the install prefix you used when configuring your Snort 3.0 build.
**RULES** is the path containing the community rules.
# 3.Install Docker
I use Docker-ce version which is enough to use for this project.
https://docs.docker.com/install/
# 4. Create a Docker network for ELK stack
**Host:Logserver**
```
docker network create elasticstack
```
# 5. Install Elasticsearch
**Host:Logserver**
```
docker run -d --name elasticsearch --net elasticstack \
-p 9200:9200 \
-p 9300:9300 \
-e "discovery.type=single-node" \
docker.elastic.co/elasticsearch/elasticsearch:7.1.1
```
# 6. Install Logstash
**Host:Logserver**
```
docker run -d --name logstash --net elasticstack \
-p 5044:5044 \
-p 5045:5045 \
-v /path/to/Snort-Capstone:/usr/share/logstash/snort_config \
-v /path/to/Snort-Capstone/pipelines.yml:/usr/share/logstash/config/pipelines.yml \
docker.elastic.co/logstash/logstash:7.1.1
```
# 7. Install Kibana
**Host:Logserver**
```
docker run -d --name kibana \
--net elasticstack \
-e ELASTICSEARCH_URL=http://elasticsearch:9200 \
-p 5601:5601 \
docker.elastic.co/kibana/kibana:7.1.1
```
# 8. Install Filebeat
**Host:Snort**
```
docker run -d \
  --name=filebeat \
  --user=root \
  --volume="/path/to/filebeat.config/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume "/var/log/snort/:/usr/share/filebeat/logs/:ro" \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  docker.elastic.co/beats/filebeat:7.1.1 filebeat -e -strict.perms=false \
  -E setup.kibana.host=192.168.4.2:5601
```
```
docker run -d \
  --name=filebeat_i2 \
  --user=root \
  --volume="/path/to/filebeat.config/filebeat.i2.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume="/path/to/appid_stats.log:/usr/share/filebeat/logs/appid_stats.log:ro" \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  docker.elastic.co/beats/filebeat:7.1.1 filebeat -e -strict.perms=false \
  -E setup.kibana.host=192.168.4.2:5601  
```
