#!/bin/bash
set -e  

# if $proxy_domain is not set, then default to $HOSTNAME
export server_number=${server_number:-"Error, no se pudo setear el parámetro"}

# ensure the following environment variables are set. exit script and container if not set.
test $server_number

/usr/local/bin/confd -onetime -backend env

echo "Starting Apache"
exec httpd -DFOREGROUND
