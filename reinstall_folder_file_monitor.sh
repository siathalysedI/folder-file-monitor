#!/bin/bash

# Script de Reinstalación - Folder File Monitor
# Ejecutar con: bash reinstall_folder_file_monitor.sh

set -e  # Detener en cualquier error

echo "🔄 Reinstalando Folder File Monitor..."
echo "====================================="

# Variables
SCRIPT_FILE="$HOME/Scripts/folder_file_monitor.sh"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.folder.filemonitor.plist"
GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh"

# Función para solicitar directorio si no se proporciona
get_watch_directory() {
    if [ -z "$1" ]; then
        echo ""
        echo "📂 ¿Cuál directorio quieres monitorear?"
        echo "Ejemplo: /Users/$(whoami)/Documents/mi-proyecto"
        read -p "Ruta completa: " WATCH_DIR
        
        if [ -z "$WATCH_DIR" ]; then
            echo "❌ ERROR: Debes especificar un directorio"
            exit 1
        fi
    else
        WATCH_DIR="$1"
    fi
    
    # Expandir ~ si se usa
    WATCH_DIR="${WATCH_DIR/#\~/$HOME}"
    
    # Verificar que el directorio existe
    if [ ! -d "$WATCH_DIR" ]; then
        echo "⚠️  El directorio no existe: $WATCH_DIR"
        read -p "¿Quieres crearlo? (y/N): " create_dir
        if [[ $create_dir =~ ^[Yy]$ ]]; then
            mkdir -p "$WATCH_DIR"
            echo "📁 Directorio creado: $WATCH_DIR"
        else
            echo "❌ Operación cancelada"
            exit 1
        fi
    fi
}

# Verificar argumentos
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [DIRECTORIO_A_MONITOREAR]"
    echo ""
    echo "Opciones:"
    echo "  DIRECTORIO_A_MONITOREAR   Ruta del directorio a monitorear"
    echo "  --help, -h                Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 /Users/$(whoami)/Documents/mi-proyecto"
    echo "  $0 ~/trabajo/documentos"
    echo "  $0                        # Te preguntará el directorio"
    exit 0
fi

# Obtener directorio a monitorear
get_watch_directory "$1"

echo "🎯 Directorio objetivo: $WATCH_DIR"
echo ""

# 1. Verificar instalación actual
echo "📋 Paso 1: Verificando instalación actual..."
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ ERROR: Folder File Monitor no está instalado"
    echo "   Ejecuta primero: install_folder_file_monitor.sh"
    exit 1
fi
echo "   ✅ Instalación encontrada"

# 2. Detener servicio actual
echo "🛑 Paso 2: Deteniendo servicio actual..."
"$SCRIPT_FILE" stop 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true
sleep 2
echo "   ✅ Servicio detenido"

# 3. Hacer backup del script actual
echo "💾 Paso 3: Haciendo backup..."
cp "$SCRIPT_FILE" "$SCRIPT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "   ✅ Backup creado"

# 4. Descargar nueva versión
echo "⬇️  Paso 4: Descargando nueva versión..."
if ! curl -fsSL "$GITHUB_SCRIPT_URL" -o "$SCRIPT_FILE.new"; then
    echo "❌ ERROR: No se pudo descargar la nueva versión"
    echo "   Verifica tu conexión a internet y la URL del repositorio"
    exit 1
fi
echo "   ✅ Nueva versión descargada"

# 5. Configurar directorio correcto
echo "⚙️  Paso 5: Configurando directorio objetivo..."
# Escapar caracteres especiales en la ruta para sed
ESCAPED_WATCH_DIR=$(printf '%s\n' "$WATCH_DIR" | sed 's/[[\.*^$()+?{|]/\\&/g')
sed "s|WATCH_DIR=\"{FOLDER}\"|WATCH_DIR=\"$ESCAPED_WATCH_DIR\"|g" "$SCRIPT_FILE.new" > "$SCRIPT_FILE"
rm "$SCRIPT_FILE.new"
chmod +x "$SCRIPT_FILE"
echo "   ✅ Directorio configurado: $WATCH_DIR"

# 6. Verificar configuración
echo "🔍 Paso 6: Verificando configuración..."
if grep -q "WATCH_DIR=\"{FOLDER}\"" "$SCRIPT_FILE"; then
    echo "❌ ERROR: La configuración del directorio falló"
    echo "   Restaurando backup..."
    mv "$SCRIPT_FILE.backup."* "$SCRIPT_FILE" 2>/dev/null || true
    exit 1
fi
echo "   ✅ Configuración verificada"

# 7. Reiniciar servicio
echo "🚀 Paso 7: Reiniciando servicio..."
launchctl load "$PLIST_FILE"
sleep 3
echo "   ✅ Servicio reiniciado"

# 8. Verificar funcionamiento
echo "✅ Paso 8: Verificando funcionamiento..."
"$SCRIPT_FILE" status

echo ""
echo "🎉 REINSTALACIÓN COMPLETADA"
echo "==========================="
echo ""
echo "✅ Folder File Monitor reinstalado exitosamente"
echo "✅ Nuevo directorio objetivo: $WATCH_DIR"
echo "✅ Servicio corriendo automáticamente"
echo ""
echo "🧪 Para probar:"
echo "   1. Modifica algún archivo en: $WATCH_DIR"
echo "   2. Espera unos segundos"
echo "   3. Ejecuta: $SCRIPT_FILE recent"
echo ""
echo "📋 Comandos útiles:"
echo "   $SCRIPT_FILE status   - Ver estado"
echo "   $SCRIPT_FILE recent   - Ver cambios de hoy"
echo "   $SCRIPT_FILE export   - Exportar datos"
