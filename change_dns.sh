#!/bin/bash

usage() {
  echo "Usage: $0 -e EMAIL -k KEY -n DOMAIN_NAME -p NEWIP -c CLIENTIP"
  exit 1
}

while getopts "e:k:n:p:c:h" options; do
  case "${options}" in
  e)
    EMAIL=${OPTARG}
    ;;
  k)
    KEY=${OPTARG}
    ;;
  n)
    DOMAIN_NAME=${OPTARG}
    ;;
  p)
    IP=${OPTARG}
    ;;
  c)
    CLIENTIP=${OPTARG}
    ;;
  h)
    usage
    ;;
  esac
done

#
# Check dependencies
#
type jq >/dev/null 2>&1 || { echo "Binary 'jq' not found - install with: 'sudo apt install jq'"; exit 1; }
type curl >/dev/null 2>&1 || { echo "Binary 'curl' not found - install with: 'sudo apt install curl'"; exit 1; }

GET_STATUS=$(curl --silent --request GET \
    "http://$CLIENTIP/healthcheck.json" | jq -r '.status')

if [ "$GET_STATUS" = "ok" ]; then
    echo "$GET_STATUS"
else
    echo "error: status is '$UPDATE_DNS'"
    
    echo "INFO: get ZONE_ID"
    ZONE_ID=$(curl --silent --request GET \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones?name=boomtech.me" | jq -r  --arg domain "$DOMAIN_NAME" '.result | .[] | select(.name == $domain)'.id)

    if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "null" ]; then
    echo "error: retrieving ZONE_ID, got '$ZONE_ID'"
    exit 4
    else
    echo "success: retrieving ZONE_ID, got '$ZONE_ID'"
    fi

    echo "INFO: get IDENTIFIER A RECORD"
    IDENTIFIER=$(curl --silent --request GET \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/" | jq -r  --arg type "A" '.result | .[] | select(.type == $type)'.id)

    if [ -z "$IDENTIFIER" ] || [ "$IDENTIFIER" = "null" ]; then
    echo "error: retrieving IDENTIFIER, got '$IDENTIFIER'"
    exit 4
    else
    echo "success: retrieving IDENTIFIER, got '$IDENTIFIER'"
    fi

    echo "INFO: update DNS"
    UPDATE_DNS=$(curl --silent --request PUT \
        --data "{\"type\":\"A\",\"name\":\"$DOMAIN_NAME\",\"content\":\"$IP\",\"ttl\":1,\"proxied\":false}" \
        -H "X-Auth-Email: $EMAIL" \
        -H "X-Auth-Key: $KEY" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$IDENTIFIER/" | jq -r ".success")

    if [ -z "$UPDATE_DNS" ] || [ "$UPDATE_DNS" = "true" ]; then
    echo "success: status is '$UPDATE_DNS'"
    else
    echo "error: status is '$UPDATE_DNS'"
    exit 6
    fi
fi
