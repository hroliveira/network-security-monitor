#!/bin/bash

echo "Detectando interface de rede..."

INTERFACE=$(ip route | grep default | awk '{print $5}')

export INTERFACE

echo "Interface usada: $INTERFACE"

docker compose up -d

echo ""
echo "Sistema iniciado"
echo ""
echo "Grafana:  http://localhost:3000"
echo "Kibana:   http://localhost:5601"
echo "Elastic:  http://localhost:9200"