# Network Security Monitor

Stack de monitoramento de rede usando:

- Zeek
- Suricata
- Elasticsearch
- Kibana
- Grafana
- Filebeat

## Requisitos

- Docker
- Docker Compose
- Linux

## Iniciar

chmod +x scripts/*.sh

./scripts/start.sh

## Acessos

Grafana
http://localhost:3000

Kibana
http://localhost:5601

Elasticsearch
http://localhost:9200

## Objetivo

Capturar:

- URLs acessadas
- DNS queries
- Dispositivos da rede
- comportamento suspeito
