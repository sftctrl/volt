#!/bin/bash

# ==============================================================================
# volt.sh - v3.1 - Um Gerenciador de Energia Deliberado
# Autor: Lucas Bastos Barboza
# Filosofia: Vontade sobre o algoritmo. Controle direto, consciente e
#            não destrutivo sobre os arquivos de sistema do hardware.
# ==============================================================================

# --- Variáveis de Configuração ---
CONSERVATION_MODE_FILE="/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode"
CPU_GOVERNOR_PATH="/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
AVAILABLE_GOVERNORS_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
BRIGHTNESS_FILE="/sys/class/backlight/amdgpu_bl1/brightness"
MAX_BRIGHTNESS_FILE="/sys/class/backlight/amdgpu_bl1/max_brightness"

# Arquivos de estado temporários
CURRENT_PROFILE_FILE="/tmp/volt_current_profile"
LAST_BRIGHTNESS_FILE="/tmp/volt_last_brightness" # Arquivo para guardar o brilho anterior

# --- Bloco para encontrar o caminho real do script ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" &> /dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" &> /dev/null && pwd )"
# ----------------------------------------------------

source "$SCRIPT_DIR/config.sh"

# --- Funções de Sistema ---
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Erro: Este script precisa ser executado como root (sudo)."
        exit 1
    fi
}

# --- Funções de Controle Direto ---
set_conservation_mode() {
    echo "$1" > "$CONSERVATION_MODE_FILE"
}

set_cpu_governor() {
    local governor=$1
    for cpu_gov_file in $CPU_GOVERNOR_PATH; do
        echo "$governor" > "$cpu_gov_file" || true
    done
}

set_brightness_value() {
    echo "$1" > "$BRIGHTNESS_FILE"
}

# --- Funções de Perfil ---
set_economico() {
    echo "Aplicando perfil 'Economico'..."
    set_cpu_governor "powersave"
    set_conservation_mode 0

    # LÓGICA APRIMORADA: Salva o brilho atual antes de alterá-lo.
    if [ -f "$BRIGHTNESS_FILE" ]; then
        cat "$BRIGHTNESS_FILE" > "$LAST_BRIGHTNESS_FILE" && chmod 666 "$LAST_BRIGHTNESS_FILE"
    fi
    
    # Calcula e define o brilho para 30%
    local max_brightness
    max_brightness=$(cat "$MAX_BRIGHTNESS_FILE")
    local new_brightness
    new_brightness=$(( max_brightness * 30 / 100 ))
    set_brightness_value "$new_brightness"
    
    echo "Economico" > "$CURRENT_PROFILE_FILE" && chmod 666 "$CURRENT_PROFILE_FILE"
}

restore_brightness() {
    # Função auxiliar para restaurar o brilho a partir do arquivo salvo.
    if [ -f "$LAST_BRIGHTNESS_FILE" ]; then
        last_brightness=$(cat "$LAST_BRIGHTNESS_FILE")
        set_brightness_value "$last_brightness"
    fi
}

set_normal() {
    echo "Aplicando perfil 'Normal'..."
    restore_brightness # Restaura o brilho salvo

    if [ -f "$AVAILABLE_GOVERNORS_FILE" ] && grep -q "schedutil" "$AVAILABLE_GOVERNORS_FILE"; then
        set_cpu_governor "schedutil"
    elif [ -f "$AVAILABLE_GOVERNORS_FILE" ] && grep -q "ondemand" "$AVAILABLE_GOVERNORS_FILE"; then
        set_cpu_governor "ondemand"
    fi
    set_conservation_mode 1
    echo "Normal" > "$CURRENT_PROFILE_FILE" && chmod 666 "$CURRENT_PROFILE_FILE"
}

set_desempenho() {
    echo "Aplicando perfil 'Desempenho'..."
    restore_brightness # Restaura o brilho salvo

    set_cpu_governor "performance"
    set_conservation_mode 0
    echo "Desempenho" > "$CURRENT_PROFILE_FILE" && chmod 666 "$CURRENT_PROFILE_FILE"
}


# --- Funções de Status e Display ---
print_terminal_status() {
    battery_status=$(cat "$CONSERVATION_MODE_FILE")
    profile_status=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "Nenhum")
    cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    brightness_val=$(cat "$BRIGHTNESS_FILE")
    max_brightness_val=$(cat "$MAX_BRIGHTNESS_FILE")
    brightness_percent=$(( brightness_val * 100 / max_brightness_val ))

    echo "---------------------------------"
    echo "  Status do Gerenciador (volt.sh)"
    echo "---------------------------------"
    if [ "$battery_status" -eq 1 ]; then
        echo "  Bateria: CONSERVAÇÃO (Carga limitada)"
    else
        echo "  Bateria: CARGA MÁXIMA (100%)"
    fi
    echo "  Brilho:  $brightness_percent%"
    echo "  CPU Gov: $cpu_gov"
    echo "  Perfil:  $profile_status"
    echo "---------------------------------"
}

get_polybar_status() {
    if [ ! -f "$CURRENT_PROFILE_FILE" ]; then
        echo "Normal" > "$CURRENT_PROFILE_FILE"
        chmod 666 "$CURRENT_PROFILE_FILE"
    fi

    current_profile=$(cat "$CURRENT_PROFILE_FILE")
    case "$current_profile" in
        "Economico")
            polybar_profile="%{F#${COLOR_PERFIL_ECO}}${ICON_PERFIL_ECO}%{F-} $current_profile"
            ;;
        "Normal")
            polybar_profile="%{F#${COLOR_PERFIL_NORMAL}}${ICON_PERFIL_NORMAL}%{F-} $current_profile"
            ;;
        "Desempenho")
            polybar_profile="%{F#${COLOR_PERFIL_PERFORMANCE}}${ICON_PERFIL_PERFORMANCE}%{F-} $current_profile"
            ;;
    esac

    current_battery_mode=$(cat "$CONSERVATION_MODE_FILE")
    if [ "$current_battery_mode" -eq 1 ]; then
        polybar_battery="%{F#${COLOR_BAT_CONSERVE}}${ICON_BAT_CONSERVE}%{F-}"
    else
        polybar_battery="%{F#${COLOR_BAT_MAX}}${ICON_BAT_MAX}%{F-}"
    fi

    echo "$polybar_profile  $polybar_battery"
}

# --- Lógica Principal ---
case "$1" in
    --economico)  check_root; set_economico; echo "Perfil 'Economico' ativado.";;
    --normal)     check_root; set_normal; echo "Perfil 'Normal' ativado.";;
    --desempenho) check_root; set_desempenho; echo "Perfil 'Desempenho' ativado.";;
    --on)  check_root; set_conservation_mode 1; echo "Modo de Conservação ATIVADO.";;
    --off) check_root; set_conservation_mode 0; echo "Modo de Conservação DESATIVADO.";;
    --status)  print_terminal_status;;
    --polybar) get_polybar_status;;
    *)
        echo "Uso: $0 [opção]"
        echo "Opções de Perfil:"
        echo "  --economico   Define o perfil de economia de energia (CPU powersave, brilho baixo)."
        echo "  --normal      Define o perfil de uso geral (CPU ondemand/schedutil, bateria em conservação)."
        echo "  --desempenho  Define o perfil de máxima performance (CPU performance)."
        echo "Opções de Bateria:"
        echo "  --on          Ativa a limitação de carga (~60%) independentemente do perfil."
        echo "  --off         Desativa a limitação de carga (permite 100%) independentemente do perfil."
        echo "Opções de Display:"
        echo "  --status      Mostra o status atual no terminal."
        echo "  --polybar     Gera a saída para a Polybar."
        exit 1
        ;;
esac

exit 0
