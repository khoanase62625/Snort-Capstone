#!/bin/bash
### Format: Rule MSG Proto Dst_addr Hits
NOW="$(date +%s)"
MILESTONE="$(head -n 1 /root/rule-sent.txt)"
EMAIL=""
SMS=""
DATA="${1::-1}"
IFS=';' read -r -a array <<< "$DATA"
CHECK="false"

if [ "$NOW" -gt "$MILESTONE" ]; then
echo "NOW > MILESTONE"
MILESTONE="$(date --date="+30 minutes" +%s)"
echo -e "$MILESTONE" > /root/rule-sent.txt
COUNT=0
for i in "${array[@]}"
do
IFS=',' read -r -a obj <<< "$i"
RULE="${obj[0]}"
QUERY="{\"size\":1,\"query\":{\"match\":{\"json.rule\":\"$RULE\"}}}"
PRIORITY="$(curl -u elastic:GXhaSnQRBkDIHmHfaX60 -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.priority')"
if [ "$PRIORITY" -lt 3 ]; then
DST_ADDR="${obj[1]}"
HITS="${obj[2]}"
MSG="$(curl -u elastic:GXhaSnQRBkDIHmHfaX60 -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.msg')"
PROTO="$(curl -u elastic:GXhaSnQRBkDIHmHfaX60 -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.proto')"
EMAIL="$EMAIL RULE :$RULE, MSG: $MSG, PROTO :$PROTO, DST_ADDR :$DST_ADDR, HITS :$HITS \n"
SMS="${SMS} $RULE,$MSG,$DST_ADDR|"
echo "${RULE}" >> /root/rule-sent.txt
COUNT=$((COUNT+1))
CHECK="true"
fi
done
echo -e "$COUNT" >> /root/rule-sent.txt

#NOW < MILESTONE -> Check sent rule and send new rule whose priority < 3
else
echo "NOW < MILESTONE"
COUNT="$(tail -n 1 /root/rule-sent.txt)"
#Remove last line in rule-sent.txt
sed -i '$ d' /root/rule-sent.txt
#Get sent rules and convert into array
sent_rule=( $(cat /root/rule-sent.txt | head -n $((COUNT+1)) | tail -n $((COUNT))) )
#Check variable whether have new data
CHECK="false"
#Checking whether rules have been sent. If not prepare EMAIL and SMS 
for i in "${array[@]}"
do
IFS=',' read -r -a obj <<< "$i"
RULE="${obj[0]}"
QUERY="{\"size\":1,\"query\":{\"match\":{\"json.rule\":\"$RULE\"}}}"
PRIORITY="$(curl -u elastic:GXhaSnQRBkDIHmHfaX60 -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.priority')"
if [[ ! "${sent_rule[@]}" =~ "$RULE" && "${PRIORITY}" -lt 3 ]]; then
DST_ADDR="${obj[1]}"
HITS="${obj[2]}"
MSG="$(curl -u elastic:GXhaSnQRBkDIHmHfaX60 -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.msg')"
PROTO="$(curl -u elastic:GXhaSnQRBkDIHmHfaX60 -s -XGET "http://localhost:9200/logstash-snort3j/_search" -H 'Content-Type: application/json' -d $QUERY | jq --raw-output '.hits.hits[]._source.json.proto')"
EMAIL="$EMAIL RULE :$RULE, MSG :$MSG, PROTO :$PROTO, DST_ADDR :$DST_ADDR, HITS :$HITS \n"
SMS="${SMS} $RULE,$MSG,$DST_ADDR|"
COUNT=$((COUNT+1))
echo -e "$RULE" >> /root/rule-sent.txt
CHECK="true"
fi
done
echo -e "$COUNT" >> /root/rule-sent.txt
fi
#Sent new data
if [ "$CHECK" == "true" ]; then
#send Email
EMAIL_ADDR="snort.test.fpt@gmail.com"
echo -e $EMAIL | mutt -s "Snort Alert" $EMAIL_ADDR
#Send sms
PHONENUMBER="+84764535161"
adb shell am startservice --user 0 -n com.android.shellms/.sendSMS -e contact $PHONENUMBER -e msg "\"${SMS}\"" >> /dev/null 2>&1
fi



