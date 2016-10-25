#!/bin/bash


exec supervisord -n && \
    mysql -e "CREATE DATABASE example"

/opt/scripts/create_mysql_admin_user.sh
