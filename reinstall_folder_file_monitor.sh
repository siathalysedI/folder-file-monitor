#!/bin/bash

# Script de Reinstalación - Folder File Monitor
# Ejecutar con: bash reinstall_folder_file_monitor.sh

set -e  # Detener en cualquier error

echo "Reinstalando Folder File Monitor..."
echo "==================================="

# Variables
SCRIPT_FILE="$HOME/Scripts/folder_file_monitor.sh"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.folder.filemonitor.plist"
GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh"
CONFIG_FILE="$HOME/.folder_monitor_config"

# Verificar argumentos
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [DIRECTORIO_A_MONITOREAR]"
    echo ""
    echo "Opciones:"
    echo "  DIRECTORIO_A_MONITOREAR   Nuevo directorio a monitorear (opcional)"
    echo "  --help, -h                Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 /Users/$(whoami)/Documents/mi-proyecto"
    echo "  $0 ~/trabajo/documentos"
    echo "  $0                        # Mantiene configuración actual"
    exit 0
fi

# Manejar configuración
if [ -n "$1" ]; then
    echo "Actualizando configuración con nuevo directorio: $1"
    # Expandir ~ si se usa
    NEW_DIR="${1/#\~/$HOME}"
    
    # Verificar que el directorio existe
    if [ ! -d "$NEW_DIR" ]; then
        echo "El directorio no existe: $NEW_DIR"
        read -p "¿Quieres crearlo? (y/N): " create_dir
        if [[ $create_dir =~ ^[Yy]$ ]]; then
            mkdir -p "$NEW_DIR"
            echo "Directorio creado: $NEW_DIR"
        else
            echo "ERROR: Directorio requerido no existe"
            exit 1
        fi
    fi
    
    # Actualizar configuración
    echo "$NEW_DIR" > "$CONFIG_FILE"
    echo "Configuración actualizada con: $NEW_DIR"
    echo ""
else
    echo "Manteniendo configuración existente"
    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        echo "Directorios configurados actualmente:"
        cat -n "$CONFIG_FILE"
    else
        echo "No hay configuración existente."
        echo "El monitor pedirá directorios al ejecutarse por primera vez."
    fi
    echo ""
fi

# 1. Verificar instalación actual
echo "Paso 1: Verificando instalación actual..."
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "ERROR: Folder File Monitor no está instalado"
    echo "   Ejecuta primero: install_folder_file_monitor.sh"
    exit 1
fi
echo "   Instalación encontrada"

# 2. Detener servicio actual
echo "Paso 2: Deteniendo servicio actual..."
"$SCRIPT_FILE" stop 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true
sleep 2
echo "   Servicio detenido"

# 3. Hacer backup del script actual
echo "Paso 3: Haciendo backup..."
cp "$SCRIPT_FILE" "$SCRIPT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "   Backup creado"

# 4. Descargar nueva versión
echo "Paso 4: Descargando nueva versión..."
if ! curl -fsSL "$GITHUB_SCRIPT_URL" -o "$SCRIPT_FILE"; then
    echo "ERROR: No se pudo descargar la nueva versión"
    echo "   Verifica tu conexión a internet y la URL del repositorio"
    exit 1
fi
chmod +x "$SCRIPT_FILE"
echo "   Nueva versión instalada"

# 5. Reiniciar servicio
echo "Paso 5: Reiniciando servicio..."
launchctl load "$PLIST_FILE"
sleep 3
echo "   Servicio reiniciado"

# 6. Verificar funcionamiento
echo "Paso 6: Verificando funcionamiento..."
"$SCRIPT_FILE" status

echo ""
echo "REINSTALACIÓN COMPLETADA"
echo "========================"
echo ""
echo "Folder File Monitor reinstalado exitosamente"
echo "Servicio corriendo automáticamente"
echo ""
if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
    echo "Configuración actual:"
    cat -n "$CONFIG_FILE"
else
    echo "Sin configuración - el monitor pedirá directorios al iniciarse"
fi
echo ""
echo "Archivo de configuración: $CONFIG_FILE"
echo ""
echo "Para probar:"
echo "   1. Modifica algún archivo en los directorios configurados"
echo "   2. Espera unos segundos"
echo "   3. Ejecuta: $SCRIPT_FILE recent"
echo ""
echo "Comandos útiles:"
echo "   $SCRIPT_FILE status   - Ver estado"
echo "   $SCRIPT_FILE recent   - Ver cambios de hoy"
echo "   $SCRIPT_FILE add      - Agregar más directorios"
echo "   $SCRIPT_FILE list     - Ver directorios configurados"
echo "   $SCRIPT_FILE export   - Exportar datos"
