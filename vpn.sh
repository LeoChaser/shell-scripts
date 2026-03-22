#!/bin/bash
# Defina o nome da interface da VPN a ser detectada
interface_vpn="wg0"
# Defina o domínio de busca de DNS interno da VPN
dominio_vpn="INSIRADOMINIO"
# IP da VPN esperado
ip_vpn="INSIRAIP"
# IP do resolvedor DNS na rede da VPN
ip_resolvedor_vpn="INSIRAIPINTERNO"

resolvedor="$(resolvectl dns $interface | cut -d' ' -f4)"
resultado_resolvedor=$?
teste_interface_vpn="$(ip a | grep $interface_vpn)"
resultado_teste=$?
ip_externo="$(curl -sS -4 icanhazip.com)"
ip -4 route show | grep "$ip_vpn" 1>> /dev/null
resultado=$?
interface="$(ip -4 route show default | grep dhcp | cut -d' ' -f5)"
# Se o resolvedor não existe
if ! [[ "$resultado_resolvedor" -eq 0 ]]; then
    echo "Verifique sua conexão à Internet e tente novamente."
    exit 1
# A interface wg0 não existe ainda (uso o NetworkManager)
elif ! [[ "$resultado_teste" -eq 0 ]]; then
    echo "Conecte à VPN antes!"
    exit 1
# Se o IP da VPN já está na rota e é igual ao IP externo
elif [[ "$resultado" -eq 0 && "$ip_externo" == "$ip_vpn" ]]; then
    echo "Já conectado à VPN e a rota está configurada!"
    # Configura o resolvedor DNS com o IP do gateway da VPN
    # e seu respectivo domínio de busca
    if [[ "$resolvedor" != "$ip_resolvedor_vpn" ]]; then
         sudo resolvectl dns "$interface_vpn" "$ip_resolvedor_vpn" && sudo resolvectl domain "$interface_vpn" "$dominio_vpn" && echo "DNS da VPN configurado! Você já pode navegar."
    else
        echo "DNS da VPN já configurado!"
    fi
elif [[ "$ip_externo" != "$ip_vpn" ]]; then
    echo "IP externo $ip_externo não é o esperado, abortando!"
    exit 1
else
    # Mostra o gateway da rede atual
    echo "Seu gateway é: $(ip -4 route show default | grep $interface | cut -d' ' -f3)"
    # Adiciona o IP da VPN à rota para garantir que esteja
    # sempre alcançável da rede atual. Mostra o IP externo
    # para o usuário ver se o IP está a contento e qual a 
    # interface está sendo usada para conectar à VPN
    sudo ip route add "$ip_vpn"/32 via "$(ip -4 route show default | grep $interface | cut -d' ' -f3)" dev "$interface" metric 1 && echo "IP externo: $ip_externo" && echo "Rota da VPN adicionada." && echo "VPN conectada com sucesso via $interface!"
    # Configura o resolvedor DNS com o IP do gateway da VPN
    # e seu respectivo domínio de busca
    sudo resolvectl dns "$interface_vpn" "$ip_resolvedor_vpn" && sudo resolvectl domain "$interface_vpn" "$dominio_vpn" && echo "DNS da VPN configurado! Você já pode navegar."
fi
exit 0