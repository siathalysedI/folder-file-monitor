#!/bin/bash

# Folder File Monitor Daemon - VERSIÓN DEFINITIVA
# Monitoreo automático de archivos de cualquier folder

# Configuración - NOMBRES CONSISTENTES
WATCH_DIR="/Users/dragon/Documents/wrk/pers/action/work/gob-nvo-leon"
LOG_FILE="$HOME/Logs/folder_file_monitor.log"
DB_FILE="$HOME/Logs/folder_file_monitor.db"
PID_FILE="$HOME/Logs/folder_file_monitor.pid"

# Crear directorios si no existen
mkdir -p "$HOME/Logs"

# Función de logging con timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Inicializar base de datos SQLite
init_database() {
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS file_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    filepath TEXT NOT NULL,
    filename TEXT NOT NULL,
    event_type TEXT NOT NULL,
    file_size INTEGER,
    file_hash TEXT,
    session_id TEXT
);

CREATE TABLE IF NOT EXISTS monitor_sessions (
    session_id TEXT PRIMARY KEY,
    start_time TEXT NOT NULL,
    end_time TEXT,
    files_monitored INTEGER DEFAULT 0,
    computer_name TEXT
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON file_changes(timestamp);
CREATE INDEX IF NOT EXISTS idx_filename ON file_changes(filename);
CREATE INDEX IF NOT EXISTS idx_session ON file_changes(session_id);
EOF
}

# Session ID único
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_$$"
COMPUTER_NAME=$(scutil --get ComputerName)

# Función de cleanup al cerrar
cleanup() {
    log_message "🛑 Deteniendo Folder File Monitor (Session: $SESSION_ID)"
    
    # Actualizar sesión en DB
    sqlite3 "$DB_FILE" <<EOF
UPDATE monitor_sessions 
SET end_time = '$(date '+%Y-%m-%d %H:%M:%S')',
    files_monitored = (SELECT COUNT(*) FROM file_changes WHERE session_id = '$SESSION_ID')
WHERE session_id = '$SESSION_ID';
EOF
    
    rm -f "$PID_FILE"
    exit 0
}

# Verificar si ya está corriendo
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log_message "⚠️  Folder File Monitor ya está corriendo (PID: $pid)"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Registrar cambio de archivo
log_file_change() {
    local filepath="$1"
    local event="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local filename=$(basename "$filepath")
    local size=0
    local hash="deleted"
    
    if [ -f "$filepath" ]; then
        size=$(stat -f%z "$filepath" 2>/dev/null || echo "0")
        hash=$(shasum -a 256 "$filepath" 2>/dev/null | cut -d' ' -f1 || echo "error")
    fi
    
    # Log compacto
    log_message "📄 $event: $filename ($size bytes)"
    
    # Insertar en base de datos
    sqlite3 "$DB_FILE" <<EOF
INSERT INTO file_changes (timestamp, filepath, filename, event_type, file_size, file_hash, session_id)
VALUES ('$timestamp', '$filepath', '$filename', '$event', $size, '$hash', '$SESSION_ID');
EOF
}

# Función principal del daemon
start_daemon() {
    check_running
    echo $$ > "$PID_FILE"
    
    # Configurar señales para cleanup
    trap cleanup SIGTERM SIGINT SIGQUIT EXIT
    
    # Inicializar
    init_database
    log_message "🚀 Iniciando Folder File Monitor (Session: $SESSION_ID)"
    log_message "📂 Directorio: $WATCH_DIR"
    log_message "💻 Equipo: $COMPUTER_NAME"
    
    # Registrar nueva sesión
    sqlite3 "$DB_FILE" <<EOF
INSERT INTO monitor_sessions (session_id, start_time, computer_name)
VALUES ('$SESSION_ID', '$(date '+%Y-%m-%d %H:%M:%S')', '$COMPUTER_NAME');
EOF
    
    # Verificaciones previas
    if ! command -v fswatch &> /dev/null; then
        log_message "❌ ERROR: fswatch no instalado"
        exit 1
    fi
    
    if [ ! -d "$WATCH_DIR" ]; then
        log_message "⚠️  Directorio no existe: $WATCH_DIR"
        log_message "📁 Creando directorio..."
        mkdir -p "$WATCH_DIR"
    fi
    
    log_message "✅ Folder File Monitor iniciado correctamente (PID: $$)"
    
    # Monitoreo principal con filtros específicos
    fswatch -r \
        --event Created \
        --event Updated \
        --event Removed \
        --exclude='.git' \
        --exclude='.DS_Store' \
        --exclude='~$' \
        "$WATCH_DIR" | while read filepath
    do
        # Filtrar archivos relevantes
        if [[ "$filepath" =~ \.(xlsx|pdf|docx|md|txt|pptx|csv|json)$ ]] && [[ ! "$filepath" =~ /\.|~\$ ]]; then
            if [ -f "$filepath" ]; then
                log_file_change "$filepath" "MODIFICADO"
            elif [ ! -e "$filepath" ]; then
                log_file_change "$filepath" "ELIMINADO"
            fi
        fi
    done
}

# Mostrar estado del servicio
show_status() {
    echo "📊 Estado del Folder File Monitor"
    echo "================================="
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            echo "✅ Estado: CORRIENDO (PID: $pid)"
            echo "📂 Directorio: $WATCH_DIR"
            echo "📄 Log: $LOG_FILE"
            echo "🗄️  Base datos: $DB_FILE"
            
            if [ -f "$DB_FILE" ]; then
                echo ""
                echo "📈 Estadísticas de HOY:"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        COUNT(*) as cambios_hoy,
                        COUNT(DISTINCT filename) as archivos_únicos,
                        MAX(timestamp) as último_cambio
                    FROM file_changes 
                    WHERE date(timestamp) = date('now');
                "
                
                echo ""
                echo "🔥 Archivos más modificados (últimos 7 días):"
                sqlite3 -header -column "$DB_FILE" "
                    SELECT 
                        filename,
                        COUNT(*) as modificaciones
                    FROM file_changes 
                    WHERE date(timestamp) >= date('now', '-7 days')
                    GROUP BY filename 
                    ORDER BY modificaciones DESC 
                    LIMIT 5;
                "
            fi
        else
            echo "❌ Estado: DETENIDO (PID file obsoleto)"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Estado: DETENIDO"
    fi
}

# Detener el servicio
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log_message "🛑 Deteniendo Folder File Monitor (PID: $pid)"
            kill $pid
            sleep 3
            if ps -p $pid > /dev/null 2>&1; then
                kill -9 $pid
                log_message "🔪 Detención forzada"
            fi
            rm -f "$PID_FILE"
            echo "✅ Folder File Monitor detenido"
        else
            echo "⚠️  Folder File Monitor no estaba corriendo"
            rm -f "$PID_FILE"
        fi
    else
        echo "⚠️  Folder File Monitor no está corriendo"
    fi
}

# Mostrar historial reciente
show_recent() {
    if [ -f "$DB_FILE" ]; then
        echo "📋 Últimos 15 cambios:"
        echo "====================="
        sqlite3 -header -column "$DB_FILE" "
            SELECT 
                substr(timestamp, 12, 8) as hora,
                filename,
                event_type as evento,
                CASE 
                    WHEN file_size < 1024 THEN file_size || ' B'
                    WHEN file_size < 1048576 THEN ROUND(file_size/1024.0, 1) || ' KB'
                    ELSE ROUND(file_size/1048576.0, 1) || ' MB'
                END as tamaño
            FROM file_changes 
            WHERE date(timestamp) = date('now')
            ORDER BY timestamp DESC 
            LIMIT 15;
        "
    else
        echo "❌ No hay base de datos disponible"
    fi
}

# Exportar datos
export_data() {
    local export_file="folder_file_changes_$(date +%Y%m%d_%H%M%S).csv"
    if [ -f "$DB_FILE" ]; then
        sqlite3 -header -csv "$DB_FILE" "
            SELECT 
                timestamp,
                filename,
                event_type,
                file_size,
                substr(file_hash, 1, 8) as hash_short,
                session_id
            FROM file_changes 
            ORDER BY timestamp DESC;
        " > "$export_file"
        echo "📊 Datos exportados a: $export_file"
        echo "📁 Ubicación: $(pwd)/$export_file"
    else
        echo "❌ No hay base de datos para exportar"
    fi
}

# Main - Manejo de comandos
case "$1" in
    "daemon")
        start_daemon
        ;;
    "start")
        start_daemon &
        echo "🚀 Folder File Monitor iniciado en background"
        sleep 2
        show_status
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        show_status
        ;;
    "recent")
        show_recent
        ;;
    "export")
        export_data
        ;;
    "restart")
        stop_daemon
        sleep 2
        start_daemon &
        echo "🔄 Folder File Monitor reiniciado"
        ;;
    "logs")
        if [ -f "$LOG_FILE" ]; then
            echo "📄 Últimas 50 líneas del log:"
            tail -50 "$LOG_FILE"
        else
            echo "❌ No hay archivo de log"
        fi
        ;;
    *)
        echo "🛠️  Folder File Monitor - Comandos disponibles:"
        echo "==============================================="
        echo "  daemon   - Ejecutar como daemon (uso interno)"
        echo "  start    - Iniciar monitor en background"
        echo "  stop     - Detener monitor"
        echo "  status   - Ver estado y estadísticas"
        echo "  recent   - Mostrar cambios de hoy"
        echo "  export   - Exportar datos a CSV"
        echo "  restart  - Reiniciar monitor"
        echo "  logs     - Ver últimas líneas del log"
        echo ""
        echo "💡 El monitor se inicia automáticamente al login"
        ;;
esac
