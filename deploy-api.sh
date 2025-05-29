#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLDER_NAME="$(basename "$SCRIPT_DIR")"
API_ID="django$FOLDER_NAME.service"
PORT_START=8000
PORT_END=8999
SERVICE_FILE="/etc/systemd/system/$API_ID"

# Buscar un puerto libre
find_free_port() {
    local start=$1
    local end=$2
    for ((port=start; port<=end; port++)); do
        if ! ss -tuln | grep -q ":$port\b"; then
            echo "$port"
            return
        fi
    done
    echo "❌ No se encontró puerto libre entre $start y $end" >&2
    exit 1
}

PORT_LOCAL=$(find_free_port $PORT_START $PORT_END)
echo "📡 Puerto local disponible encontrado: $PORT_LOCAL"

# Crear entorno virtual e instalar dependencias
echo "🛠️  Creando entorno virtual..."
python3 -m venv "$SCRIPT_DIR/venv"

echo "⬆️  Activando entorno virtual y actualizando pip..."
source "$SCRIPT_DIR/venv/bin/activate"
pip install --upgrade pip

# Instalar dependencias necesarias
if [ -f "$SCRIPT_DIR/pyproject.toml" ]; then
    echo "📦 Instalando con pyproject.toml..."
    pip install .
elif [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    echo "📦 Instalando con requirements.txt..."
    pip install -r "$SCRIPT_DIR/requirements.txt"
else
    echo "❌ No se encontró pyproject.toml ni requirements.txt"
    exit 1
fi

echo "✅ Entorno y dependencias listas."

# Crear servicio systemd si no existe
if [ ! -f "$SERVICE_FILE" ]; then
  echo "🛠️ Creando servicio systemd ..."
  sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Django Web Server
After=network.target

[Service]
ExecStart=${SCRIPT_DIR}/venv/bin/python manage.py runserver ${PORT_LOCAL}
WorkingDirectory=${SCRIPT_DIR}
User=sistemasweb
Group=sistemasweb
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable "$API_ID"
fi

# Reiniciar servicio
echo "🔄 Reiniciando servicio para aplicar cambios..."
sudo systemctl restart "$API_ID"

# Mensajes finales
echo ""
echo "✅ API $API_ID configurada y corriendo en puerto $PORT_LOCAL."                
echo "Puedes acceder a la API en http://localhost:$PORT_LOCAL"
echo "Para detener el servicio, usa: sudo systemctl stop $API_ID"
echo "Para iniciar el servicio, usa: sudo systemctl start $API_ID"
echo "Para reiniciar el servicio, usa: sudo systemctl restart $API_ID"
echo "Para ver el estado del servicio, usa: sudo systemctl status $API_ID"
