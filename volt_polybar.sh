#!/bin/bash

# ==============================================================================
# volt-polybar.sh - Módulo de Exibição para Polybar
# Lê o estado do sistema e formata a saída usando as configurações visuais.
# ==============================================================================

# --- Bloco para encontrar o caminho real do script e carregar a configuração ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" &> /dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" &> /dev/null && pwd )"
# ----------------------------------------------------

# Carrega as configurações de ícones e cores
source "$SCRIPT_DIR/config.sh"

# --- Variáveis de Hardware e Estado ---
CONSERVATION_MODE_FILE="/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode"
CURRENT_PROFILE_FILE="/tmp/volt_current_profile"

# --- Lógica de Exibição ---

# Inicializa o arquivo de perfil se ele não existir
if [ ! -f "$CURRENT_PROFILE_FILE" ]; then
    echo "Normal" > "$CURRENT_PROFILE_FILE"
    chmod 666 "$CURRENT_PROFILE_FILE"
fi

# --- Parte 1: Display do Perfil Ativo ---
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

# --- Parte 2: Display do Status da Bateria ---
current_battery_mode=$(cat "$CONSERVATION_MODE_FILE")
if [ "$current_battery_mode" -eq 1 ]; then
    polybar_battery="%{F#${COLOR_BAT_CONSERVE}}${ICON_BAT_CONSERVE}%{F-}"
else
    polybar_battery="%{F#${COLOR_BAT_MAX}}${ICON_BAT_MAX}%{F-}"
fi

# --- Final: Combina os dois displays ---
echo "$polybar_profile  $polybar_battery"
