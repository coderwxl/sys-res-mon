#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "input params err, should like: sendemail.sh \"connect timeout\""
    exit 2
fi

#must modify the serverlabel to be your own
#serverlabel="加密服务测试环境\n"
serverlabel="测试环境\n"

success_rsp='{"errcode":0,"errmsg":"ok"}'

deviceip=$(hostname -I | paste -sd ",")"\n"

#发送企业微信告警
response=$(curl --silent 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=98750431-eef0-4180-adec-c679e61a3066' \
        -H 'Content-Type: application/json' \
        -d @- <<EOF
{"msgtype":"text", "text":{"content": "$serverlabel$deviceip$1"}}
EOF
)
if [ "$response" != "$success_rsp" ]; then
    echo "QYWeiXin Response Error: $response"
fi
exit 0