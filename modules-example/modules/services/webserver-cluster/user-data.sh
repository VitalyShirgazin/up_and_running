#!/bin/bash
yum update -y
yum install -y httpd

cat > /var/www/html/index.html <<EOF
<h1>Hello, World</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF

systemctl start httpd
systemctl enable httpd
