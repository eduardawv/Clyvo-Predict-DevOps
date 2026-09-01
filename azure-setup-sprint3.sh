#!/bin/bash
# =================================================================
# CLYVO Predict — Sprint 3 DevOps
# ACR + ACI + Azure Files (volume persistente)
# Imagens no ACR: App + MySQL (sem depender do Docker Hub)
# =================================================================

set -e

RESOURCE_GROUP="rg-clyvo-predict-s3"
LOCATION="eastus"
ACR_NAME="clyvopredictacr"
CONTAINER_GROUP="clyvo-predict-group"
IMAGE_NAME="clyvo-predict"
STORAGE_ACCOUNT="clyvostorage$RANDOM"
FILE_SHARE="clyvo-mysql-data"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; }

echo ""
echo "================================================================"
echo "   CLYVO Predict — Sprint 3 | ACR + ACI + Volume Persistente"
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
  --output table 2>/dev/null || ok "ACR ja existe."

ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASS=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" --output tsv)
log "ACR Server: $ACR_SERVER"

# ── 3. Login no ACR ──────────────────────────────────────────
log "Login no ACR..."
az acr login --name "$ACR_NAME"

# ── 4. Build e Push da imagem do App ─────────────────────────
log "Build da imagem do App..."
docker build -t "$ACR_SERVER/$IMAGE_NAME:latest" .
log "Push do App para o ACR..."
docker push "$ACR_SERVER/$IMAGE_NAME:latest"
ok "Imagem do App enviada."

# ── 5. Push da imagem MySQL para o ACR ───────────────────────
log "Baixando imagem MySQL 8.0 localmente..."
docker pull mysql:8.0
log "Tagueando MySQL para o ACR..."
docker tag mysql:8.0 "$ACR_SERVER/mysql:8.0"
log "Push do MySQL para o ACR..."
docker push "$ACR_SERVER/mysql:8.0"
ok "Imagem MySQL enviada para o ACR."

log "Imagens no ACR:"
az acr repository list --name "$ACR_NAME" --output table

# ── 6. Storage Account + File Share ──────────────────────────
log "Criando Storage Account '$STORAGE_ACCOUNT'..."
az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --location "$LOCATION" \
  --output table

STORAGE_KEY=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query "[0].value" --output tsv)

log "Criando File Share '$FILE_SHARE'..."
az storage share create \
  --name "$FILE_SHARE" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$STORAGE_KEY" \
  --quota 5 \
  --output none 2>/dev/null || true
ok "Volume persistente criado (Azure Files)."

# ── 7. Deleta container group antigo ─────────────────────────
log "Removendo container group anterior (se existir)..."
az container delete \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --yes 2>/dev/null || true

# ── 8. Gera YAML com credenciais ─────────────────────────────
log "Preparando YAML do ACI..."
sed \
  -e "s|__ACR_SERVER__|$ACR_SERVER|g" \
  -e "s|__ACR_USER__|$ACR_USER|g" \
  -e "s|__ACR_PASS__|$ACR_PASS|g" \
  -e "s|__STORAGE_ACCOUNT__|$STORAGE_ACCOUNT|g" \
  -e "s|__STORAGE_KEY__|$STORAGE_KEY|g" \
  aci-deploy.yaml > aci-deploy-final.yaml

# ── 9. Deploy ACI ────────────────────────────────────────────
log "Criando Container Group (MySQL + API + Volume)..."
az container create \
  --resource-group "$RESOURCE_GROUP" \
  --file aci-deploy-final.yaml \
  --output table

rm -f aci-deploy-final.yaml
ok "Container Group criado!"

# ── 10. Resultado ────────────────────────────────────────────
log "Aguardando containers iniciarem (~60s)..."
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
echo -e " ${GREEN}CLYVO PREDICT RODANDO!${NC}"
echo "================================================================"
echo "  Resource Group  : $RESOURCE_GROUP"
echo "  ACR             : $ACR_SERVER"
echo "  Storage Account : $STORAGE_ACCOUNT"
echo "  File Share      : $FILE_SHARE (volume persistente)"
echo "  Swagger         : http://${APP_URL}:8080/swagger-ui.html"
echo ""
echo "  Logs API:   az container logs -g $RESOURCE_GROUP -n $CONTAINER_GROUP --container-name clyvo-api"
echo "  Logs MySQL: az container logs -g $RESOURCE_GROUP -n $CONTAINER_GROUP --container-name mysql-db"
echo "================================================================"
