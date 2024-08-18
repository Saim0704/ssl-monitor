#!/bin/bash

#Files Path
website_file="websites.txt"
recipient_file="recipient.txt"
ssl_notification_file="/tmp/website_ssl_notification-up.txt"

#Email Functions:
sender_name="SSL Report"
sender_email="indicsoftnoida@gmail.com"
subject="SSL is Expiring Soon"
mail_command="/usr/sbin/sendmail"
send_email() {
    echo "Subject: $subject" > "$ssl_notification_file"
    echo "To: $recipients" >> "$ssl_notification_file"
    echo "Content-Type: text/html; charset=utf-8\n" >> "$ssl_notification_file"
    echo -e "\n$1" >> "$ssl_notification_file"
    $mail_command -F "$sender_name" -f "$sender_email" -t < "$ssl_notification_file"
}

#SSL Function
check_ssl_expiry() {
    hostname=$1
    echo "$hostname"
    expire_date=$(echo | openssl s_client -servername $hostname -connect $hostname:443 2>/dev/null | openssl x509 -noout -enddate | cut -d "=" -f 2)
    expire_timestamp=$(date -d "$expire_date" +%s)
    current_timestamp=$(date +%s)
    seconds_left=$((expire_timestamp - current_timestamp))
    days_left=$((seconds_left / 86400))  # 86400 seconds in a day
    if [ $days_left -gt 7 ] && [ $days_left -le 14 ]; then
        echo "The SSL certificate for $hostname expires in $days_left days."
        send_email "The SSL certificate for $hostname expires in $days_left days.  <br> <br>"
    elif [ $days_left -gt 0 ] &&  [ $days_left -le 7 ]; then
        echo "The SSL certificate for $hostname expires in $days_left days."
        send_email "The SSL certificate for $hostname expires in $days_left days.  <br> <br>"
    elif [ $days_left -le 0 ]; then
        echo "The SSL certificate for $hostname expired."
         send_email "The SSL certificate for $hostname has expired. <br> <br>"
    else        
        echo "The SSL certificate for $hostname is valid for $days_left days."
	echo
    fi
}
# Recipient Added
IFS= read -r recipients <<< "$(cat "$recipient_file")"

# Main
while IFS= read -r url; do
check_ssl_expiry $url
done < "$website_file"
