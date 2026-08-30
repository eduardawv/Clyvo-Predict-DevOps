#!/bin/bash
# =================================================================
# CLYVO Predict — Sprint 3 DevOps (VERSAO FINAL)
# ACR + ACI Multi-container | Java 17 + MySQL 8
# =================================================================
# USO:
#   az login
#   ./azure-setup-sprint3.sh
# =================================================================

set -e

RESOURCE_GROUP="rg-clyvo-predict-s3"
LOCATION="eastus"
ACR_NAME="clyvopredictacr"
CONTAINER_GROUP="clyvo-predict-group"
IMAGE_NAME="clyvo-predict"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "================================================================"
echo "   CLYVO Predict — Sprint 3 | ACR + ACI | MySQL 8"
echo "================================================================"
echo ""

# ── 1. Resource Group ────────────────────────────────────────
log "Criando Resource Group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table
ok "Resource Group criado."

# ── 2. ACR ───────────────────────────────────────────────────
log "Criando ACR '$ACR_NAME'..."
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --location "$LOCATION" \
  --output table 2>/dev/null || ok "ACR já existe."
ok "ACR pronto."

ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASS=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" --output tsv)
log "ACR Server: $ACR_SERVER"

# ── 3. Build e Push ──────────────────────────────────────────
log "Login no ACR..."
az acr login --name "$ACR_NAME"

log "Build da imagem Docker..."
docker build -t "$ACR_SERVER/$IMAGE_NAME:latest" .

log "Push para o ACR..."
docker push "$ACR_SERVER/$IMAGE_NAME:latest"
ok "Imagem enviada."

log "Verificando imagem no ACR..."
az acr repository list --name "$ACR_NAME" --output table

# ── 4. Deleta container group antigo (se existir) ────────────
log "Removendo container group anterior..."
az container delete \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --yes 2>/dev/null || true

# ── 5. Gera YAML com credenciais ─────────────────────────────
log "Preparando YAML do ACI..."
sed \
  -e "s|__ACR_SERVER__|$ACR_SERVER|g" \
  -e "s|__ACR_USER__|$ACR_USER|g" \
  -e "s|__ACR_PASS__|$ACR_PASS|g" \
  aci-deploy.yaml > aci-deploy-final.yaml

# ── 6. Deploy multi-container ACI ────────────────────────────
log "Criando Container Group (MySQL + API)..."
az container create \
  --resource-group "$RESOURCE_GROUP" \
  --file aci-deploy-final.yaml \
  --output table

# Remove YAML com credenciais
rm -f aci-deploy-final.yaml
ok "Container Group criado!"

# ── 7. Aguarda e mostra resultado ────────────────────────────
log "Aguardando containers iniciarem (~60s para MySQL)..."
sleep 60

APP_URL=$(az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --query "ipAddress.fqdn" --output tsv)

log "Status dos containers:"
az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --query "containers[].{Nome:name, Estado:instanceView.currentState.state}" \
  --output table

echo ""
echo "================================================================"
echo -e " ${GREEN}✅  CLYVO PREDICT RODANDO!${NC}"
echo "================================================================"
echo "  Swagger: http://${APP_URL}:8080/swagger-ui.html"
echo "  API:     http://${APP_URL}:8080"
echo ""
echo "  Logs API:   az container logs -g $RESOURCE_GROUP -n $CONTAINER_GROUP --container-name clyvo-api"
echo "  Logs MySQL: az container logs -g $RESOURCE_GROUP -n $CONTAINER_GROUP --container-name mysql-db"
echo "================================================================"
warn "Após o vídeo: az group delete --name $RESOURCE_GROUP --yes --no-wait"
