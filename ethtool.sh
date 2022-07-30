#!/bin/bash
#
# ---------------------------------------------------------------- #
# Script Name: ethtool.sh
# Description: Renegotiate network interface speed if it's not equal
# to 10000Mb/s
# Github: https://github.com/LeoChaser
# Escrito por: Leonardo Alencar
# Mantido por: Leonardo Alencar
# ---------------------------------------------------------------- #
# Usage:
# # ./ethtool.sh
# ---------------------------------------------------------------- #
# Bash Version:
# Bash 5.1-2
# -----------------------------------------------------------------#
# History: v0.1 2022/07/07, Leonardo:
#          - First version
#          v1.0 2022/07/30, Leonardo:
#          - Cleanup, structure changes and some corrections
# -----------------------------------------------------------------#

# comandos executados repetidamente, transformados em variaveis
CUT=/usr/bin/cut
DATA=/usr/bin/date
GREP=/usr/bin/grep
ETH=/usr/sbin/ethtool
SLEEP=/usr/bin/sleep

# placa a ser testada e alterada
PLACA="enp2s0"
# cria a variavel SPEED vazia para armazenar a velocidade e usa-la depois
SPEED=
# cria a variavel ISUP vazia para armazenar se a placa foi detectada 
ISUP=
# cria a variavel N para evitar loop eterno
N=0

# funcao "executa", que faz o grosso do script
executa(){
# enquanto a variavel for diferente de 10000Mb/s (velocidade da placa do
# servidor), executa
	while [ "$SPEED" != "10000Mb/s" ]
	do
# data YYYY/MM/DD e hora enviados junto do resultado da variavel para o
# arquivo com a data YYYY/MM/DD e executa o comando ethtool -r para rene-
# gociar a velocidade da placa de rede e consulta novamente a velocidade
		echo "$($DATA "+%F-%T") - $SPEED" >> "/var/log/ethtool-$($DATA "+%F").log"
		$ETH -r $PLACA && $SLEEP 30 && SPEED=$($ETH $PLACA | $GREP Speed | $CUT -d " " -f 2)
# se a velocidade estiver correta, finaliza o script com exit 0
		if [ "$SPEED" = "10000Mb/s" ]; then
# envia a data e a velocidade para o arquivo de log
			echo "$($DATA "+%F-%T") - $SPEED" >> "/var/log/ethtool-$($DATA "+%F").log"
			exit 0
		fi
# escape para nao ficar em loop eterno
# se N e igual a 1000 (para nao ficar em loop eterno)
		N=$((N+1))
		if [ $N -eq 10 ]; then
			break
		fi
	done
# finaliza com exit 255 para voltar ao loop da funcao "verifica"
	exit 255
}


# funcao que verifica o link e depois executa a funcao "executa"
verifica(){
# aguarda 30s para esperar a rede
$SLEEP 30

# verifica se o link esta ativo com "Link detected: yes"
	ISUP=$($ETH $PLACA | $GREP "Link detected"  | $CUT -d " " -f 3)
# se o link estiver como nao detectado, tenta levanta-lo
	if [ "$ISUP" = no ]; then
		/usr/sbin/ifup "$PLACA" && $SLEEP 10
	else
		while [ "$ISUP" = "yes" ]
		do
# pega as informacoes da placa de rede, captura a linha com a informacao Speed,
# exemplo: "Speed: 100Mb/s", e corta so a velocidade
			SPEED=$($ETH $PLACA | $GREP Speed | $CUT -d " " -f 2)
# se a velocidade estiver correta, finaliza o script com exit 0
			if [ "$SPEED" = "10000Mb/s" ]; then
# envia a data e a velocidade para o arquivo de log
				echo "$($DATA "+%F-%T") - $SPEED" >> "/var/log/ethtool-$($DATA "+%F").log"
				exit 0
			else
# executa a funcao "executa", se for finalizada com exit 255, entao volta
# 'a funcao "verifica"
				(executa)
				RES=$?
				if [ "$RES" != 255 ]; then
					break
				fi
			fi
		done
	fi
}

# principal do script, inicia a funcao "verifica" e finaliza se a saida exit
# for diferente de 255
while [ "$SPEED" != "10000Mb/s" ]
do
	(verifica)
	RES=$?
	if [ "$RES" != 255 ]; then
		break
	fi
done
exit 0
