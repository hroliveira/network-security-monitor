# Guia de Instalação e Uso: Network Security Monitor

Este guia detalha os passos exatos para colocar sua stack de monitoramento de rede em produção no seu servidor Linux.

## 1. Preparando o Ambiente Linux

Antes de clonar o repositório, certifique-se de ter os pré-requisitos instalados em sua máquina host Linux (Ubuntu/Debian usado como exemplo):

```bash
# Atualize os pacotes
sudo apt update && sudo apt upgrade -y

# Instale dependências essenciais (Git, Curl)
sudo apt install git curl -y

# Instale o Docker (caso não possua)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicione seu usuário ao grupo docker para não precisar usar 'sudo' a todo momento
sudo usermod -aG docker $USER
newgrp docker
```

> [!IMPORTANT]
> Se o arquivo `docker-compose` não for reconhecido, instale o plugin do compose separadamente rodando: `sudo apt-get install docker-compose-plugin`.

## 2. Clonando o Repositório

Baixe o projeto já com todas as correções de persistência e segurança que definimos:

```bash
git clone https://github.com/hroliveira/network-security-monitor.git
cd network-security-monitor
```

## 3. Inicializando o Sistema

O seu projeto já veio com um script preparatório para o Docker. O script localiza qual interface de rede do seu Linux está enviando tráfego para a internet (rota padrão) e a exporta para o Zeek e o Suricata conseguirem monitorar.

```bash
# Dê permissão de execução aos scripts
chmod +x scripts/*.sh

# Inicialize o monitoramento
./scripts/start.sh
```

Aguarde cerca de 1 a 2 minutos após o script terminar para que o `Elasticsearch` suba e os outros serviços consigam se plugar a ele. 

> [!TIP]
> Você pode acompanhar o progresso subindo acompanhando os logs do kibana e vendo se ele teve sucesso ao conectar ao elastic: `docker compose logs -f kibana`

## 4. Validando no Elastic (Kibana)

1. Acesse **http://<IP-DO-SEU-LINUX>:5601** no seu navegador. 
 *(Se estiver instalando em casa/lab local ou Cloud, basta substituir pelo IP correto).*
2. Na página principal do Kibana, abra o menu lateral esquerdo (🍔) e vá para **Discover**.
3. Como atualizamos o Filebeat para usar os **módulos nativos**, você já deverá notar os índices chamados `filebeat-*` sendo populados automaticamente tanto com os arquivos JSON de alertas do Suricata (`suricata.eve`) quanto as requisições traduzidas pelo Zeek (DNS, HTTP e Conexões).
4. Para os Dashboards do Elastic: Vá em **Dashboard** no Menu lateral. Você verá que o Filebeat instalou automaticamente pacotes prontos de visualização (Procure por *"Zeek"* e *"Suricata"* na pesquisa).

## 5. Integrando o Grafana

Caso você queira montar dashboards unificados que não existem no Elastic, siga os passos abaixo:

1. Acesse **http://<IP-DO-SEU-LINUX>:3000**
2. O login padrão original do Grafana é `admin` / `admin`. O painel pedirá para criar uma nova senha.
3. No painel, vá para `Connections > Add new connection` e busque por **Elasticsearch**.
4. Configure a URL como `http://elasticsearch:9200`. O index name deve ser algo como `filebeat-*` (ou `[filebeat-]YYYY.MM.DD` na pattern de data, caso prefira mapeamento retroativo).

## 6. Realizando Testes na Rede

Para ter certeza de que o IDS (Suricata) e o monitor de acesso (Zeek) começaram a gerar dados úteis, na própria máquina rode:

```bash
# Gera logs fáceis no /zeek/current/dns.log
ping -c 4 uol.com.br

# Gera tráfego http inseguro para validar detecções ou logs /zeek/current/http.log
curl http://neverssl.com/
```

Dentro de poucos segundos isso deve aparecer tanto na pesquisa do Disover do Kibana, atestando que toda a trilha "Rede > IDS/Monitor > Arquivo Log > Filebeat > Elastic" está íntegra e salva de forma persistente.

Para **desligar** tudo sem perder nenhum histórico:
```bash
./scripts/stop.sh
```
