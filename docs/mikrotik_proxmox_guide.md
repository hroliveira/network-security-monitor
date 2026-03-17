# Guia de Espelhamento de Rede: Mikrotik + Proxmox para Monitoramento

Para que o **Network Security Monitor** capture todo o tráfego da sua rede enquanto roda como uma Máquina Virtual (VM) no Proxmox, precisamos configurar o **Mikrotik** para copiar (espelhar) os pacotes e o **Proxmox** para permiti-los chegar até a interface da VM. 

Essa configuração utiliza a técnica de **Port Mirroring** física (Recomendado).

## 🪟 Fase 1: Configurando o Proxmox (Host)

O Proxmox precisa de uma interface virtual (Bridge) exclusiva para receber o tráfego capturado e uma porta física ligada diretamente ao Mikrotik onde o "espelho" vai desaguar.

1. **Acesse a interface web do Proxmox**.
2. Vá em **Seu Nó (Node) > Network**.
3. Clique em **Create > Linux Bridge**.
   - **Name**: `vmbr1` (ou a próxima numeração livre).
   - **Bridge ports**: Coloque o nome da interface de rede física que você conectará ao cabo de pacotes do Mikrotik (ex: `eno2` ou `eth1`). Se o seu servidor tiver apenas uma placa de rede, é possível usar VLANs, mas o ideal é ter uma porta física apenas para captura.
   - **Deixe os campos IPv4/IPv6 em branco!** (Esta ponte será "invisível" para IPs, servindo apenas de antena).
   - Clique em **Create** e depois em **Apply Configuration** no topo da tela.

## 💻 Fase 2: Configurando a sua VM Linux (Network Monitor)

Sua VM precisa de uma segunda "placa de rede" que receberá os pacotes espelhados no Proxmox.

1. Selecione a sua VM do Linux no painel esquerdo do Proxmox.
2. Vá em **Hardware > Add > Network Device**.
3. Em **Bridge**, escolha a que você criou no passo anterior (`vmbr1`).
4. **MUITO IMPORTANTE**: Desmarque a caixinha chamada **Firewall** nesta interface. (O firewall do Proxmox descarta pacotes alheios por segurança, o que mataria nosso monitoramento).
5. Clique em Add. Reinicie sua VM Linux para que ela reconheça a nova placa de rede (ex: ela vai aparecer com um nome como `ens19` ou `eth1`).

> [!TIP]
> Dentro do Linux (logado no terminal), digite `ip a` e verifique o nome da sua nova interface. Você precisará alterar o arquivo `start.sh` do repositório para apontar para o nome dessa nova placa (ex: `export INTERFACE=ens19`), ao invés de usar a que acessa a internet. 
> Exemplo de comando Linux para habilitar captura:
> `sudo ip link set ens19 up promisc on`

## 📡 Fase 3: Configurando Port Mirroring no Mikrotik

O Mikrotik fará a "cópia" de todo o tráfego da sua rede local (LAN) rumo ao Proxmox. 
Para isso, conecte um cabo de rede da porta dedicada de captura no Proxmox (a `vmbr1`) para uma porta livre no Mikrotik (ex: `ether5`).

Você pode configurar via WinBox ou pelo Terminal do Mikrotik. Pelo Terminal é mais direto:

```routeros
# Digamos que sua rede local (LAN) esteja na interface bridge chamada 'bridge-local'
# e o Proxmox (para receber a captura) esteja ligado na porta física 'ether5'

# 1. Defina o alvo do espelhamento (porta que vai pro Proxmox)
/interface ethernet switch
set mirror-target=ether5 [find name=switch1]

# 2. Defina qual porta SERÁ espelhada (onde a internet/LAN passa, ex: ether1 - Porta ISP ou ether2 - Trunk geral LAN)
/interface ethernet switch port
set ether2 mirror-source=yes
```

> [!CAUTION]
> **Limitações de Switch Chip:** O modelo exato do seu Mikrotik determina como o Port Mirroring é configurado. Equipamentos mais modernos com hardware de Switch (como a série CRS ou RB3011/4011) fazem isso por hardware (comandos acima). 
> Se o seu tiver as regras em software, talvez seja necessário usar as regras de Bridge Filtros (`/interface bridge settings set use-ip-firewall=yes` e `/interface bridge filter ...`). Mas o Switch Port Mirroring (hardware) é o recomendado para não carregar a CPU do Mikrotik a 100%.

## ✅ Validando a Configuração Completa

Depois de tudo plugado e configurado:
1. No seu Linux, abra o terminal e use o tcpdump para "escutar" a placa nova:
   ```bash
   sudo apt install tcpdump
   sudo tcpdump -i ens19 -nn     # (Troque ens19 pelo nome da sua interface de captura)
   ```
2. Pegue o celular (conectado no WiFi da sua casa/Mikrotik) e acesse algum site.
3. Você deve ver o `tcpdump` enlouquecer mostrando os pacotes IP passando pela tela!
4. Aperte `Ctrl+C` para parar.
5. Agora é só atualizar o `scripts/start.sh` para usar o nome exato da interface (`ens19`), rodar `./scripts/start.sh` e apreciar o Kibana enchendo de logs de toda a rede!
