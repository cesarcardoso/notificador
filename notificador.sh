#!/bin/sh
#
# Notificador simples para o Gmail
# 2013 Cesar Cardoso
#
# Verifica se o arquivo de configuração existe

CONFIG=$HOME/.notificador
if [ ! -f $CONFIG ]; then
    exit 1
fi

# Verifica se a permissão do arquivo está correta (600)

perms=$(stat $CONFIG | sed -n '/^Access: (/{s/Access: (\([0-9]\+\).*$/\1/;p}')
if [[ $perms != 0600 ]]; then
    echo "Permissão errada"
    exit 1
fi

# Faz um parsing mínimo do arquivo de configuração
# Se a conta não for do Google Apps, adiciona gmail.com ao nome de usuário

USUARIO=$(grep USER $CONFIG | cut -d"=" -f 2)
SENHA=$(grep PASS $CONFIG | cut -d"=" -f 2)
TAPPS=$(grep APPS $CONFIG)
if [ -z "${TAPPS-unset}" ]; then
    GAPPS=gmail.com
else
    GAPPS=$(echo $TAPPS | cut -d"=" -f 2)
fi

# Se gnome-gmail estiver instalado, aproveita o ícone, senão usa um ícone padrão do GNOME

if [[ -f /usr/share/icons/hicolor/48x48/apps/gnome-gmail.png ]]; then
   ICONE=/usr/share/icons/hicolor/48x48/apps/gnome-gmail.png
else
   ICONE=/usr/share/icons/gnome/48x48/status/mail-unread.png
fi


# Pega a saída do feed Atom do Gmail com o marcador "Importante"

SAIDA="$(curl -s -u $USUARIO\@$GAPPS:$SENHA https://mail.google.com/mail/feed/atom/important/)"

# Faz o parsing da saída para pegar APENAS o que está dentro das tags <fullcount> e </fullcount>

NOVAS=$( echo "$SAIDA" | cut -d">" -f2 | cut -d"<" -f1 | sed -n 5p )

# Se o conteúdo de NOVAS for diferente de zero, ou seja, haver email novo...

if [[ $NOVAS -ne 0 ]]; then 
    notify-send -u critical -i $ICONE "No Gmail" "$NOVAS email(s) importante(s) novos"
else

# Não temos mensagens novas, mas podemos ter mensagens não lidas. E, para isso, contamos quantas tag <entry> temos se $NOVAS estiver zerado.

    NAOLIDAS=$( echo "$SAIDA" | grep "<entry>" | wc -l )
    if [[ $NAOLIDAS -ne 0 ]]; then
        notify-send -u critical -i $ICONE "No Gmail" "$NAOLIDAS email(s) importante(s) não lidos"
    fi
fi
