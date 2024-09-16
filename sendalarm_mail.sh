#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "input params err, should like: sendemail.sh \"connect timeout\""
    exit 2
fi

#must modify the xxx to be your own

# todo 设置收件人邮箱地址
recipient_list=("xxx@xxx.com" "xxx@xxx.com" "xxx@xxx.com")
recipient_cmd=""
recipient_data=""
isfirst=1
for recipient in "${recipient_list[@]}"
do
    recipient_cmd=${recipient_cmd}" --mail-rcpt \""$recipient"\""
    if [[ $isfirst -eq 1 ]]; then
        isfirst=0
    else
        recipient_data=${recipient_data}","
    fi
    recipient_data=${recipient_data}${recipient}
done

# 设置发件人邮箱地址
sender="xxx@xxx.com"

# 设置邮件标题
subject="系统资源监控告警"

# 设置邮件正文
body=$(echo -e "$1" | sed 's/\\\\n/\\n/g')

# 设置SMTP服务器地址和端口
smtp_server="smtphz.qiye.163.com"
smtp_port="465"

# 设置发件人邮箱的用户名和密码
username="xxx@xxx.com"
password="xxx"

# 使用curl命令进行SMTP身份验证并发送邮件
response=$(curl --silent --url "smtps://$smtp_server:$smtp_port" --ssl-reqd \
    --mail-from "$sender" $recipient_cmd --user "$username:$password" \
    --insecure --mail-auth "PLAIN" --upload-file "-" <<EOF
Content-Type:text/plain;charset=utf-8
From: <$sender>
To: $recipient_data
Subject: $subject

$body
Please check and fix problem as soon as possible.
email send time: $(date +"%Y-%m-%d %H:%M:%S")
EOF
)

return_code=$?
# 检查响应中是否包含"OK"，表示邮件发送成功
if [[ $return_code -eq 0 ]]; then
    echo "Email sent successfully!"
    exit 0
else
    echo "Failed to send email. Error code: $return_code"
    exit 3
fi
