#!/bin/bash
# Verificación de la infraestructura (script base del docente, completado por el estudiante)

# Se ejecuta desde cualquier carpeta: se posiciona en terraform/
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/terraform" || exit 1

NET="red-evaluacion"
WEB="servidor-web"
APP="servidor-app"
WEB_URL=$(terraform output -raw web_url 2>/dev/null || echo "http://localhost:8080")
APP_URL=$(terraform output -raw app_url 2>/dev/null || echo "http://localhost:8081")
FALLOS=0

ok()   { echo "  [OK]    $1"; }
fail() { echo "  [FALLO] $1"; FALLOS=$((FALLOS+1)); }

echo "======================================"
echo " VERIFICACIÓN DE INFRAESTRUCTURA"
echo "======================================"

echo ""
echo "[1] Verificando Terraform..."

terraform validate

if [ $? -ne 0 ]; then
    echo "ERROR: La configuración de Terraform no es válida."
    exit 1
fi

echo "Terraform: OK"

echo ""
echo "[2] Verificando contenedores..."

docker ps --filter "name=servidor-" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

for c in "$WEB" "$APP"; do
    if [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ]; then
        ok "Contenedor $c en ejecución"
    else
        fail "Contenedor $c NO está en ejecución"
    fi
done

echo ""
echo "[3] Verificando red..."

docker network ls --filter "name=$NET"

SUBNET=$(docker network inspect "$NET" -f '{{(index .IPAM.Config 0).Subnet}}' 2>/dev/null)
[ "$SUBNET" = "10.20.0.0/24" ] && ok "Subred correcta: $SUBNET" || fail "Subred incorrecta: '$SUBNET'"

WEB_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" "$WEB" 2>/dev/null)
APP_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" "$APP" 2>/dev/null)
[ "$WEB_IP" = "10.20.0.10" ] && ok "Web con IP fija $WEB_IP" || fail "Web tiene IP '$WEB_IP', se esperaba 10.20.0.10"
[ "$APP_IP" = "10.20.0.20" ] && ok "App con IP fija $APP_IP" || fail "App tiene IP '$APP_IP', se esperaba 10.20.0.20"

echo ""
echo "[4] Verificando servidor web..."

curl -I --max-time 5 "$WEB_URL"
CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$WEB_URL")
[ "$CODE" = "200" ] && ok "Web responde HTTP 200 en $WEB_URL" || fail "Web respondió '$CODE' en $WEB_URL"

echo ""
echo "[5] Verificando servidor de aplicaciones..."

curl -I --max-time 5 "$APP_URL"
CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$APP_URL")
[ "$CODE" = "200" ] && ok "App responde HTTP 200 en $APP_URL" || fail "App respondió '$CODE' en $APP_URL"

echo ""
echo "[6] Verificando conectividad entre servidores..."

docker exec "$WEB" ping -c 2 -W 2 10.20.0.20 > /dev/null 2>&1 && ok "web -> app (10.20.0.20)" || fail "web -> app"
docker exec "$APP" ping -c 2 -W 2 10.20.0.10 > /dev/null 2>&1 && ok "app -> web (10.20.0.10)" || fail "app -> web"
docker exec "$WEB" ping -c 1 -W 2 app > /dev/null 2>&1 && ok "web resuelve el alias 'app'" || fail "alias 'app' no resuelve"

echo ""
echo "======================================"
if [ "$FALLOS" -eq 0 ]; then
    echo " FIN DE LA VERIFICACIÓN: todo correcto"
else
    echo " FIN DE LA VERIFICACIÓN: $FALLOS prueba(s) fallaron"
fi
echo "======================================"

[ "$FALLOS" -eq 0 ]
