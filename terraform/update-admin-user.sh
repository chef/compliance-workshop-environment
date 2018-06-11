#!/bin/bash

TOK=`./chef-automate admin-token`
ADMIN_ID=`curl -k -H  "api-token: $TOK" https://localhost/api/v0/auth/users/admin | jq '.id'`

curl -k -X PUT -H "api-token: $TOK" -H "Content-Type: application/json" -d '{"name":"admin", "password":"chef-automate", "id": "$AMDIN_ID"}' https://localhost/api/v0/auth/users/admin
