# Folder File Monitor

Monitoreo automático de cambios en archivos de cualquier directorio en macOS. Se ejecuta como servicio en background y registra todos los cambios con timestamps, estadísticas y exportación a CSV.

## Características

- **Inicio automático** al login
- **Monitoreo en tiempo real** de todos los archivos
- **Base de datos SQLite** con historial completo
- **Estadísticas detalladas** por archivo y fecha
- **Exportación a CSV** para análisis
- **Filtros inteligentes** (excluye .git, .DS_Store, temporales)
- **Control completo** via comandos

## Instalación

### Opción 1: Instalación Automática (Recomendada)

```bash
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/install_folder_file_monitor.sh | bash
```

**Te solicitará que especifiques qué directorio quieres monitorear.**

### Opción 2: Instalación Manual

1. **Instalar dependencias:**
   ```bash
   brew install fswatch
   ```

2. **Crear directorios:**
   ```bash
   mkdir -p ~/Scripts ~/Logs ~/Library/LaunchAgents
   ```

3. **Descargar script principal:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh
   chmod +x ~/Scripts/folder_file_monitor.sh
   ```

4. **Configurar directorio a monitorear:**
   ```bash
   # Reemplaza /ruta/a/tu/directorio con la ruta real
   sed -i '' 's|WATCH_DIR="{FOLDER}"|WATCH_DIR="/ruta/a/tu/directorio"|g' ~/Scripts/folder_file_monitor.sh
   ```

5. **Crear LaunchAgent:**
   ```bash
   cat > ~/Library/LaunchAgents/com.user.folder.filemonitor.plist << 'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.user.folder.filemonitor</string>
       <key>ProgramArguments</key>
       <array>
           <string>/Users/USUARIO/Scripts/folder_file_monitor.sh</string>
           <string>daemon</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <dict>
           <key>SuccessfulExit</key>
           <false/>
       </dict>
       <key>StandardOutPath</key>
       <string>/Users/USUARIO/Logs/folder_launchd.log</string>
       <key>StandardErrorPath</key>
       <string>/Users/USUARIO/Logs/folder_launchd_error.log</string>
       <key>WorkingDirectory</key>
       <string>/Users/USUARIO</string>
       <key>EnvironmentVariables</key>
       <dict>
           <key>PATH</key>
           <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
           <key>HOME</key>
           <string>/Users/USUARIO</string>
       </dict>
       <key>ProcessType</key>
       <string>Background</string>
       <key>LowPriorityIO</key>
       <true/>
       <key>ThrottleInterval</key>
       <integer>1</integer>
   </dict>
   </plist>
   EOF
   ```
   
   **Importante:** Reemplaza `USUARIO` con tu nombre de usuario real.

6. **Activar servicio:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
   ```

7. **Verificar:**
   ```bash
   ~/Scripts/folder_file_monitor.sh status
   ```

## Actualización Rápida (Si ya lo tienes instalado)

```bash
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor_update.sh | bash
```

**Te solicitará que especifiques qué directorio quieres monitorear si no está configurado.**

## Reinstalación Completa (Cambiar directorio)

Para actualizar a la última versión y/o cambiar el directorio a monitorear:

```bash
# Descargar script de reinstalación
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/reinstall_folder_file_monitor.sh -o reinstall_folder_file_monitor.sh
chmod +x reinstall_folder_file_monitor.sh

# Reinstalar especificando nuevo directorio
./reinstall_folder_file_monitor.sh /nueva/ruta/a/monitorear

# O ejecutar sin parámetros para que te solicite el directorio
./reinstall_folder_file_monitor.sh
```

## Comandos de Uso

### Comandos Básicos

```bash
# Ver estado del monitor
~/Scripts/folder_file_monitor.sh status

# Ver cambios recientes del día
~/Scripts/folder_file_monitor.sh recent

# Ver últimas líneas del log
~/Scripts/folder_file_monitor.sh logs

# Exportar todos los datos a CSV
~/Scripts/folder_file_monitor.sh export
```

### Control del Servicio

```bash
# Iniciar monitor manualmente
~/Scripts/folder_file_monitor.sh start

# Detener monitor
~/Scripts/folder_file_monitor.sh stop

# Reiniciar monitor
~/Scripts/folder_file_monitor.sh restart
```

### Control del LaunchAgent

```bash
# Detener servicio automático
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# Iniciar servicio automático
launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# Ver estado del servicio
launchctl list | grep folder.filemonitor
```

## Consultas Avanzadas

### Consultas SQL Directas

```bash
# Ver todos los cambios de hoy
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT timestamp, filename, event_type, file_size 
FROM file_changes 
WHERE date(timestamp) = date('now') 
ORDER BY timestamp DESC;"

# Archivos más modificados
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT filename, COUNT(*) as modificaciones 
FROM file_changes 
GROUP BY filename 
ORDER BY modificaciones DESC 
LIMIT 10;"

# Estadísticas por día
sqlite3 ~/Logs/folder_file_monitor.db "
SELECT date(timestamp) as fecha, COUNT(*) as cambios 
FROM file_changes 
GROUP BY date(timestamp) 
ORDER BY fecha DESC 
LIMIT 7;"
```

## Ubicación de Archivos

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| **Script principal** | `~/Scripts/folder_file_monitor.sh` | Ejecutable principal |
| **Base de datos** | `~/Logs/folder_file_monitor.db` | SQLite con historial |
| **Log principal** | `~/Logs/folder_file_monitor.log` | Log del monitor |
| **Log sistema** | `~/Logs/folder_launchd.log` | Log del LaunchAgent |
| **Servicio** | `~/Library/LaunchAgents/com.user.folder.filemonitor.plist` | Configuración del servicio |

## Mantenimiento

### Limpiar Registros Antiguos

```bash
# Eliminar registros de más de 90 días
sqlite3 ~/Logs/folder_file_monitor.db "
DELETE FROM file_changes 
WHERE date(timestamp) < date('now', '-90 days');"

# Optimizar base de datos
sqlite3 ~/Logs/folder_file_monitor.db "VACUUM;"
```

### Ver Tamaño de Base de Datos

```bash
du -h ~/Logs/folder_file_monitor.db
sqlite3 ~/Logs/folder_file_monitor.db "SELECT COUNT(*) FROM file_changes;"
```

## Desinstalación

```bash
# 1. Detener y descargar servicio
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# 2. Eliminar archivos
rm -f ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
rm -f ~/Scripts/folder_file_monitor.sh
rm -f ~/Logs/folder_file_monitor.*
rm -f ~/Logs/folder_launchd.*

# 3. Limpiar directorios vacíos
rmdir ~/Scripts 2>/dev/null || true
rmdir ~/Logs 2>/dev/null || true
```

## Troubleshooting

### El monitor no detecta cambios

1. **Verificar que está corriendo:**
   ```bash
   ~/Scripts/folder_file_monitor.sh status
   ```

2. **Revisar logs:**
   ```bash
   ~/Scripts/folder_file_monitor.sh logs
   tail -f ~/Logs/folder_launchd_error.log
   ```

3. **Reiniciar servicio:**
   ```bash
   ~/Scripts/folder_file_monitor.sh restart
   ```

### Error de permisos

```bash
# Verificar permisos del script
ls -la ~/Scripts/folder_file_monitor.sh
chmod +x ~/Scripts/folder_file_monitor.sh
```

### Fswatch no encontrado

```bash
# Instalar fswatch
brew install fswatch

# Verificar instalación
which fswatch
fswatch --version
```

## Notas

- **Archivos monitoreados:** Todos excepto `.git/`, `.DS_Store`, temporales (`~$`, `.swp`, `.tmp`)
- **Inicio automático:** Se activa en cada login
- **Rendimiento:** Usa `LowPriorityIO` para no impactar el sistema
- **Base de datos:** SQLite para consultas rápidas y confiabilidad
- **Compatibilidad:** macOS con Homebrew

## Contribuir

1. Fork el repositorio
2. Crea tu branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## Licencia

MIT License - ver archivo LICENSE para detalles.
