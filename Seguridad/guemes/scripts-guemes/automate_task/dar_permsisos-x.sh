#!/bin/bash

echo "╔════════════════════════════╗"
echo "║  Asignar permisos +x 💻   ║"
echo "╚════════════════════════════╝"
echo

# Mostrar menú de selección de carpeta
read -rp "👉 Ingresá la ruta completa de la carpeta (o presioná Enter para usar la actual: $(pwd)): " ruta

# Si no se ingresa nada, usar la carpeta actual
if [ -z "$ruta" ]; then
    ruta=$(pwd)
fi

# Verificamos si la carpeta existe
if [ ! -d "$ruta" ]; then
    echo "❌ La carpeta '$ruta' no existe. Abortando."
    exit 1
fi

echo "📁 Carpeta seleccionada: $ruta"
echo "🔐 Aplicando permisos +x a todos los archivos..."

# Aplicar permisos solo a archivos (no directorios)
find "$ruta" -type f -exec chmod +x {} \;

echo "✅ Permisos aplicados con éxito."
