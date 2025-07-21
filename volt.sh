#!/bin/bash

# ==============================================================================
# volt.sh - Um Gerenciador de Energia Deliberado
# Autor: Lucas Bastos Barboza
# Filosofia: Vontade sobre o algoritmo. Controle manual e consciente
#            sobre a gestão de energia do hardware.
# ==============================================================================

# --- Variáveis de Configuração ---
# O kernel do Linux expõe o controle do modo de conservação da bateria
# para notebooks Lenovo/IdeaPad neste arquivo.
# É uma interface direta, sem necessidade de daemons ou software complexo.
CONSERVATION_MODE_FILE="/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode"

# Carrega as configurações de ícones e cores para a Polybar
# Isso separa a lógica da apresentação, um princípio de bom design.
source "$(dirname "$0")/config.sh"

# --- Funções ---

# Função para verificar se o script está sendo executado como root
# A modificação do arquivo de sistema exige privilégios elevados.
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Erro: Este script precisa ser executado como root (sudo) para alterar as configurações."
        exit 1
    fi
}

# Função para definir o estado do modo de conservação
# Parâmetro: $1 - deve ser 0 (desligado) ou 1 (ligado)
set_conservation_mode() {
    local mode=$1
    if [ ! -w "$CONSERVATION_MODE_FILE" ]; then
        echo "Erro: Não é possível escrever no arquivo '$CONSERVATION_MODE_FILE'."
        echo "Verifique se o módulo 'ideapad_laptop' está carregado e se você tem as permissões corretas."
        exit 1
    fi

    # Escreve o valor no arquivo do kernel, efetivamente mudando o modo.
    # Esta é a ação central, a "vontade" sendo aplicada diretamente. [cite: 8]
    echo "$mode" > "$CONSERVATION_MODE_FILE"
}

# Função para obter o status atual e formatar para a Polybar
get_polybar_status() {
    if [ ! -f "$CONSERVATION_MODE_FILE" ]; then
        echo -e "${ICON_ERROR} Driver não encontrado"
        exit 1
    fi

    current_mode=$(cat "$CONSERVATION_MODE_FILE")

    if [ "$current_mode" -eq 1 ]; then
        # Modo de Conservação ATIVADO: A bateria não passará de 60%.
        # A cor e o ícone refletem um estado de "proteção" ou "limite".
        echo -e "%{F${COLOR_ON}}${ICON_ON}%{F-} Carga Limitada"
    else
        # Modo de Conservação DESATIVADO: A bateria carregará até 100%.
        # A cor e o ícone refletem um estado de "plena potência" ou "liberdade".
        echo -e "%{F${COLOR_OFF}}${ICON_OFF}%{F-} Carga Máxima"
    fi
}

# Função para mostrar o status no terminal de forma legível
print_terminal_status() {
    if [ ! -f "$CONSERVATION_MODE_FILE" ]; then
        echo "Erro: Driver 'ideapad_acpi' não parece estar ativo."
        exit 1
    fi

    current_mode=$(cat "$CONSERVATION_MODE_FILE")

    echo "---------------------------------"
    echo "  Status do Gerenciador de Energia (volt.sh)"
    echo "---------------------------------"
    if [ "$current_mode" -eq 1 ]; then
        echo "  Modo Atual: CONSERVAÇÃO (Carga limitada a ~60%)"
        echo "  Ação: A bateria está protegida contra desgaste."
    else
        echo "  Modo Atual: CARGA MÁXIMA (Carga habilitada até 100%)"
        echo "  Ação: Ideal para uso fora da tomada."
    fi
    echo "---------------------------------"
}

# --- Lógica Principal ---
# Analisa os argumentos passados para o script.
# Um simples 'case' é mais limpo e eficiente do que múltiplos 'if/elifs'.
case "$1" in
    --on)
        check_root
        echo "Ativando o Modo de Conservação de Energia..."
        set_conservation_mode 1
        echo "Concluído. A bateria não carregará acima de 60%."
        ;;
    --off)
        check_root
        echo "Desativando o Modo de Conservação de Energia..."
        set_conservation_mode 0
        echo "Concluído. A bateria agora pode carregar até 100%."
        ;;
    --status)
        print_terminal_status
        ;;
    --polybar)
        get_polybar_status
        ;;
    *)
        echo "Uso: $0 [--on | --off | --status | --polybar]"
        echo "  --on      : Liga o modo de conservação (limita a carga em 60%). Requer sudo."
        echo "  --off     : Desliga o modo de conservação (permite carga total). Requer sudo."
        echo "  --status  : Mostra o status atual no terminal."
        echo "  --polybar : Saída formatada para o módulo da Polybar."
        exit 1
        ;;
esac

exit 0
