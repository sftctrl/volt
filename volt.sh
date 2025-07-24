#!/bin/bash
# shellcheck disable=SC2034 # Desabilita avisos para variáveis usadas em outros scripts.

# ==============================================================================
# volt.sh - v4.0 - O Motor de Gerenciamento de Energia
# Autor: Lucas Bastos Barboza
#
# DESCRIÇÃO:
# Este script é o núcleo de controle de energia, projetado para interagir
# diretamente com os arquivos de sistema do kernel Linux para gerenciar
# perfis de energia, estado da bateria e brilho da tela. Ele é construído
# para ser modular, robusto e independente de qualquer interface de usuário.
#
# FILOSOFIA:
# Vontade sobre o algoritmo. Controle direto, consciente e resiliente sobre
# os arquivos de sistema do hardware.
# ==============================================================================


## -----------------------------------------------------------------------------
## VARIÁVEIS GLOBAIS E DE CONFIGURAÇÃO
## -----------------------------------------------------------------------------
# Define os caminhos para os arquivos de sistema que controlam o hardware.
# Esta abordagem direta garante máxima compatibilidade e controle.
CONSERVATION_MODE_FILE="/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode"
CPU_GOVERNOR_PATH="/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
AVAILABLE_GOVERNORS_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
BRIGHTNESS_FILE="/sys/class/backlight/amdgpu_bl1/brightness"
MAX_BRIGHTNESS_FILE="/sys/class/backlight/amdgpu_bl1/max_brightness"

# Define os caminhos para os arquivos de estado temporários.
# Estes arquivos permitem que o script mantenha um estado entre execuções
# e que diferentes componentes (como a Polybar) leiam o estado atual.
CURRENT_PROFILE_FILE="/tmp/volt_current_profile"
LAST_BRIGHTNESS_FILE="/tmp/volt_last_brightness"


## -----------------------------------------------------------------------------
## FUNÇÕES DE SISTEMA
## -----------------------------------------------------------------------------

#
# Garante que o script seja executado com privilégios de root (superusuário).
# A modificação de arquivos de sistema críticos exige permissões elevadas.
#
check_root() {
    # "$EUID" é uma variável de ambiente que contém o ID do usuário efetivo.
    # O ID 0 é reservado para o usuário root.
    if [ "$EUID" -ne 0 ]; then
        echo "Erro: Este script precisa ser executado como root (sudo)." >&2
        exit 1
    fi
}

#
# Escreve um valor em um arquivo de estado de forma robusta e segura.
# Resolve o problema de permissão entre o usuário (`brbz`) e o `root`.
# @param {string} $1 - O caminho completo para o arquivo de estado.
# @param {string} $2 - O valor a ser escrito no arquivo.
#
write_state_file() {
    local file_path="$1"
    local value="$2"

    # Usa 'tee' para sobrescrever o arquivo com o novo valor, mesmo que o dono
    # seja outro usuário. O `sudo` que chama o script dá ao `tee` o poder
    # necessário. '> /dev/null' evita que o 'tee' imprima na tela.
    echo "$value" | tee "$file_path" > /dev/null

    # Após escrever (como root), ajusta as permissões para que qualquer
    # usuário (como o da Polybar) possa ler e escrever no arquivo no futuro.
    chmod 666 "$file_path"
}


## -----------------------------------------------------------------------------
## FUNÇÕES DE CONTROLE DIRETO DE HARDWARE
## -----------------------------------------------------------------------------

# Define o modo de conservação da bateria.
# @param {integer} $1 - O modo a ser definido (1 para ligado, 0 para desligado).
set_conservation_mode() {
    echo "$1" > "$CONSERVATION_MODE_FILE"
}

# Define o governador de frequência para todos os núcleos da CPU.
# @param {string} $1 - O nome do governador (ex: "powersave").
set_cpu_governor() {
    local governor=$1
    # Itera sobre cada arquivo de governador de CPU e aplica a configuração.
    # O '|| true' é uma salvaguarda que impede o script de parar se, por
    # algum motivo, a escrita em um dos núcleos falhar.
    for cpu_gov_file in $CPU_GOVERNOR_PATH; do
        echo "$governor" > "$cpu_gov_file" || true
    done
}

# Define o valor absoluto do brilho da tela.
# @param {integer} $1 - O valor numérico do brilho.
set_brightness_value() {
    echo "$1" > "$BRIGHTNESS_FILE"
}


## -----------------------------------------------------------------------------
## FUNÇÕES DE GERENCIAMENTO DE PERFIS
## -----------------------------------------------------------------------------

# Ativa o perfil de Economia de Energia.
set_economico() {
    set_cpu_governor "powersave"
    set_conservation_mode 0 # Desliga a conservação para uso móvel

    # Salva o brilho atual antes de alterá-lo para poder restaurá-lo depois.
    if [ -f "$BRIGHTNESS_FILE" ]; then
        write_state_file "$LAST_BRIGHTNESS_FILE" "$(cat "$BRIGHTNESS_FILE")"
    fi

    # Calcula e define o brilho para 30%
    local max_brightness
    max_brightness=$(cat "$MAX_BRIGHTNESS_FILE")
    local new_brightness
    new_brightness=$(( max_brightness * 30 / 100 ))
    set_brightness_value "$new_brightness"

    # Atualiza o arquivo de estado com o perfil atual.
    write_state_file "$CURRENT_PROFILE_FILE" "Economico"
}

# Restaura o brilho da tela para o último valor salvo.
restore_brightness() {
    if [ -f "$LAST_BRIGHTNESS_FILE" ]; then
        last_brightness=$(cat "$LAST_BRIGHTNESS_FILE")
        set_brightness_value "$last_brightness"
    fi
}

# Ativa o perfil Normal.
set_normal() {
    restore_brightness # Restaura o brilho antes de qualquer outra ação.

    # Lógica inteligente: Verifica qual governador usar para máxima compatibilidade.
    if [ -f "$AVAILABLE_GOVERNORS_FILE" ] && grep -q "schedutil" "$AVAILABLE_GOVERNORS_FILE"; then
        set_cpu_governor "schedutil"
    elif [ -f "$AVAILABLE_GOVERNORS_FILE" ] && grep -q "ondemand" "$AVAILABLE_GOVERNORS_FILE"; then
        set_cpu_governor "ondemand" # Fallback para sistemas mais antigos
    fi

    set_conservation_mode 1 # Ativa a conservação para longevidade
    write_state_file "$CURRENT_PROFILE_FILE" "Normal"
}

# Ativa o perfil de Desempenho.
set_desempenho() {
    restore_brightness
    set_cpu_governor "performance"
    set_conservation_mode 0
    write_state_file "$CURRENT_PROFILE_FILE" "Desempenho"
}


## -----------------------------------------------------------------------------
## FUNÇÃO DE STATUS
## -----------------------------------------------------------------------------

# Imprime um relatório de status completo e legível no terminal.
print_terminal_status() {
    # Garante que o arquivo de perfil exista antes de tentar lê-lo.
    if [ ! -f "$CURRENT_PROFILE_FILE" ]; then
        write_state_file "$CURRENT_PROFILE_FILE" "Normal"
    fi

    local battery_status
    battery_status=$(cat "$CONSERVATION_MODE_FILE")
    local profile_status
    profile_status=$(cat "$CURRENT_PROFILE_FILE")
    local cpu_gov
    cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    local brightness_val
    brightness_val=$(cat "$BRIGHTNESS_FILE")
    local max_brightness_val
    max_brightness_val=$(cat "$MAX_BRIGHTNESS_FILE")
    local brightness_percent
    brightness_percent=$(( brightness_val * 100 / max_brightness_val ))

    echo "--- Status do Gerenciador volt.sh ---"
    echo "Perfil Ativo:     $profile_status"
    echo "Status Bateria:   $battery_status (0=Máxima, 1=Conservação)"
    echo "Governador CPU:   $cpu_gov"
    echo "Brilho Tela:      $brightness_percent%"
}


## -----------------------------------------------------------------------------
## LÓGICA PRINCIPAL (CASE STATEMENT)
## -----------------------------------------------------------------------------
# Analisa o primeiro argumento passado para o script e executa a função correspondente.
# Esta é a estrutura de controle principal do programa.
case "$1" in
    --economico)
        check_root
        set_economico
        echo "Perfil 'Economico' ativado."
        ;;
    --normal)
        check_root
        set_normal
        echo "Perfil 'Normal' ativado."
        ;;
    --desempenho)
        check_root
        set_desempenho
        echo "Perfil 'Desempenho' ativado."
        ;;
    --on)
        check_root
        set_conservation_mode 1
        echo "Modo de Conservação ATIVADO."
        ;;
    --off)
        check_root
        set_conservation_mode 0
        echo "Modo de Conservação DESATIVADO."
        ;;
    --status)
        print_terminal_status
        ;;
    *)
        # Se nenhum argumento válido for fornecido, exibe a ajuda.
        echo "Uso: $0 [--economico|--normal|--desempenho|--on|--off|--status]"
        exit 1
        ;;
esac

exit 0
