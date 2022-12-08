#!/bin/bash
yum -y update
yum -y install httpd

MYIP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<h2>Congratulations!!!</h2>
<h3>You have deployed high availability web service!!</h3>
<p>My Private Ip: $MYIP</p>
</html>
EOF

service httpd start
chkconfig httpd ons