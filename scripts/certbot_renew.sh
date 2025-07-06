#!/bin/bash
certbot renew --quiet
docker compose -f /opt/mailserver/docker-compose.yml restart mailserver
