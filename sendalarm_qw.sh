#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "input params err, should like: sendemail.sh \"connect timeout\""
    exit 2
fi

#must modify the serverlabel to be your own
serverlabel="系统资源监控告警\n"

success_rsp='{"errcode":0,"errmsg":"ok"}'

#发送企业微信告警
response=$(curl --silent 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxxx' \
        -H 'Content-Type: application/json' \
        -d @- <<EOF
{"msgtype":"text", "text":{"content": "$serverlabel$1"}}
EOF
)
if [ $response != $success_rsp ]; then
    echo "QYWeiXin Response: "$response
    exit 100
fi
exit 0
