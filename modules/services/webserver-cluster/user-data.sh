#!/bin/bash

cat > index.html <<EOF
<h1>Keep Learning, Keep Growing, Keep Striving, Ryan!</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} &