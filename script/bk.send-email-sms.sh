#!/bin/bash
### Format: Rule MSG Proto Dst_addr Hits
NOW="$(date +%Y/%m/%d-%H:%M:%S)"
MILESTONE="$(head -n 1 /root/rule-sent.txt)"
EMAIL="$NOW \n"
SMS="$NOW|"
DATA="${1::-1}"
IFS=';' read -r -a array <<< "$1"

if ["$NOW" -gt "$MILESTONE"]; then
MILESTONE="$(date --date="+30 minutes" +%Y/%m/%d-%H:%M:%S)"
echo -e "$MILESTONE\n" > /root/rule-sent.txt
COUNT=0
for i in "${array[@]}"
do
IFS=',' read -r -a obj <<< "$i"
RULE="${obj[0]}"
PRIORITY="$(curl -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.priority')"

if ["$PRIORITY" -lt 3]; then
DST_ADDR="${obj[1]}"
HITS="${obj[2]}"
QUERY="{\"size\":1,\"query\":{\"match\":{\"json.rule\":\"$RULE\"}}}"
MSG="$(curl -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.msg')"
PROTO="$(curl -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.proto')"
EMAIL="$EMAIL RULE :$RULE, MSG: $MSG, PROTO $PROTO, DST_ADDR $DST_ADDR, HITS $HITS \n"
SMS="${SMS} $RULE,$MSG,$DST_ADDR|"
echo -e "$RULE\n" >> /root/rule-send.txt
COUNT=$((COUNT+1))
fi

done
echo -e "$COUNT" >> /root/rule-sent.txt

#send Email
EMAIL_ADDR="khoanase62625@fpt.edu.vn"
echo -e $EMAIL | mutt -s "Snort Alert" $EMAIL_ADDR >> /dev/null 2>&1

#Send sms
PHONENUMBER="+84933875926"
adb shell am startservice --user 0 -n com.android.shellms/.sendSMS -e contact $PHONENUMBER -e msg "\"${SMS}\"" >> /dev/null 2>&1

#NOW < MILESTONE -> Check sent rule and send new rule whose priority < 3
else
COUNT="$(tail -n 1 /root/rule-sent.txt)"
COUNT=$((COUNT+1))
TMP="$(awk 'NR > 1 && NR <= $COUNT' /root/rule-sent.txt)"
IFS=' ' read -r -a sent_rule <<< "$TMP"
CHECK="false"
for i in "${array[@]}"
do
IFS=',' read -r -a obj <<< "$i"
RULE="${obj[0]}"

for j in "${sent_rule[@]}"
do
if ["$RULE" -eq j]; then
PRIORITY="$(curl -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._sourc$
if ["$PRIORITY" -lt 3]; then
DST_ADDR="${obj[1]}"
HITS="${obj[2]}"
QUERY="{\"size\":1,\"query\":{\"match\":{\"json.rule\":\"$RULE\"}}}"
MSG="$(curl -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.jso$
PROTO="$(curl -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.j$
EMAIL="$EMAIL RULE :$RULE, MSG: $MSG, PROTO $PROTO, DST_ADDR $DST_ADDR, HITS $HITS \n"
SMS="${SMS} $RULE,$MSG,$DST_ADDR|"
CHECK="true"
COUNT=$((COUNT+1))
done
done
done

