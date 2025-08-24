#!/bin/bash

# Actualización simple para usuarios que ya tienen el monitor corriendo
# Ejecutar con: bash folder_file_monitor_update.sh

echo "🔄 Actualizando Folder File Monitor..."
echo "====================================="

# Reiniciar con la nueva configuración
~/Scripts/folder_file_monitor.sh stop
sleep 2

# Actualizar el script con la nueva versión
curl -fsSL https://raw.githubusercontent.com/siathalysedI/folder-file-monitor/main/folder_file_monitor.sh -o ~/Scripts/folder_file_monitor.sh
chmod +x ~/Scripts/folder_file_monitor.sh

# Reiniciar el servicio automático
launchctl unload ~/Library/LaunchAgents/com.user.folder.filemonitor.plist
launchctl load ~/Library/LaunchAgents/com.user.folder.filemonitor.plist

# Verificar que funciona
sleep 3
~/Scripts/folder_file_monitor.sh status

echo ""
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "El monitor ha sido actualizado y reiniciado"
