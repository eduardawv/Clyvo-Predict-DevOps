#!/bin/bash
# =================================================================
# CLYVO Predict — Sprint 3 DevOps
# Azure Container Registry (ACR) + Azure Container Instance (ACI)
# App: Java 17 + Spring Boot | DB: Oracle XE 21c (containerizado)
# FIAP 2026 — 2TDS Fevereiro
# =================================================================
# PRÉ-REQUISITOS:
#   - Azure CLI instalado e autenticado (az login)
#   - Docker Desktop rodando localmente
#   - Estar na raiz do projeto (onde está o Dockerfile)
#
# USO:
#   chmod +x azure-setup-sprint3.sh
#   az login
#   ./azure-setup-sprint3.sh
# =================================================================

set -e

# ── VARIÁVEIS ────────────────────────────────────────────────
RESOURCE_GROUP="rg-clyvo-predict-s3"
LOCATION="eastus"
ACR_NAME="clyvopredictacr"               # Deve ser único globalmente, sem traços
CONTAINER_GROUP="clyvo-predict-group"
STORAGE_ACCOUNT="clyvostorage$RANDOM"    # Nome único com número aleatório
FILE_SHARE="oracle-data"
IMAGE_NAME="clyvo-predict"
IMAGE_TAG="latest"
DNS_LABEL="clyvo-predict-api"            # URL pública do ACI

# Senhas (use variáveis de ambiente em produção real)
ORACLE_PASS="ClyvoPredict@2024"
APP_USER_PASS="Clyvo@Pass123"

# ── Cores ────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "================================================================"
echo "   CLYVO Predict — Sprint 3 DevOps | ACR + ACI"
echo "================================================================"
echo ""

# ── PASSO 1: Resource Group ──────────────────────────────────
log "Criando Resource Group '$RESOURCE_GROUP'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table
ok "Resource Group criado."

# ── PASSO 2: Azure Container Registry (ACR) ──────────────────
log "Criando Azure Container Registry '$ACR_NAME'..."
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --location "$LOCATION" \
  --output table
ok "ACR criado."

# Captura credenciais do ACR
ACR_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --query loginServer \
  --output tsv)
ACR_USER=$(az acr credential show \
  --name "$ACR_NAME" \
  --query username \
  --output tsv)
ACR_PASS=$(az acr credential show \
  --name "$ACR_NAME" \
  --query "passwords[0].value" \
  --output tsv)

log "ACR Server: $ACR_SERVER"

# ── PASSO 3: Build e Push da imagem para o ACR ───────────────
log "Fazendo login no ACR..."
az acr login --name "$ACR_NAME"

log "Buildando imagem Docker localmente..."
docker build \
  --tag "$ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG" \
  --file Dockerfile \
  .

log "Fazendo push da imagem para o ACR..."
docker push "$ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG"
ok "Imagem '$ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG' enviada para o ACR."

# Verifica se a imagem está no ACR
log "Verificando imagem no ACR..."
az acr repository list \
  --name "$ACR_NAME" \
  --output table

# ── PASSO 4: Storage Account + Azure Files (volume nomeado) ───
log "Criando Storage Account para persistência do Oracle..."
az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --location "$LOCATION" \
  --output table

STORAGE_KEY=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query "[0].value" \
  --output tsv)

log "Criando File Share '$FILE_SHARE' para dados do Oracle..."
az storage share create \
  --name "$FILE_SHARE" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$STORAGE_KEY" \
  --quota 10 \
  --output table
ok "Volume nomeado (Azure Files) criado: $FILE_SHARE"

# ── PASSO 5: Deploy Multi-container ACI ──────────────────────
log "Gerando arquivo YAML do ACI com credenciais..."
sed \
  -e "s|__ACR_SERVER__|$ACR_SERVER|g" \
  -e "s|__ACR_USER__|$ACR_USER|g" \
  -e "s|__ACR_PASS__|$ACR_PASS|g" \
  -e "s|__STORAGE_ACCOUNT__|$STORAGE_ACCOUNT|g" \
  -e "s|__STORAGE_KEY__|$STORAGE_KEY|g" \
  aci-deploy.yaml > aci-deploy-final.yaml

log "Criando Container Group ACI (Oracle + API)..."
az container create \
  --resource-group "$RESOURCE_GROUP" \
  --file aci-deploy-final.yaml \
  --output table

ok "Container Group criado!"

# Remove YAML com credenciais em texto claro
rm -f aci-deploy-final.yaml

# ── PASSO 6: Aguarda containers subirem ──────────────────────
log "Aguardando containers iniciarem (~3 minutos para Oracle)..."
sleep 30

log "Status do Container Group:"
az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --query "[name, containers[*].name, ipAddress.fqdn, ipAddress.ports]" \
  --output table

# Captura FQDN público
APP_URL=$(az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --query "ipAddress.fqdn" \
  --output tsv)

log "Aguardando Oracle inicializar completamente (~2 min)..."
sleep 90

log "Testando saúde da API..."
curl -sf "http://${APP_URL}:8080/swagger-ui.html" \
  && ok "Swagger respondendo!" \
  || warn "API ainda inicializando. Tente em 2 minutos."

# ── PASSO 7: Exibe comandos usados no README ─────────────────
echo ""
echo "================================================================"
echo " COMANDOS DE BUILD E EXECUÇÃO (coloque no README)"
echo "================================================================"
echo ""
echo "# Build da imagem:"
echo "docker build -t $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG ."
echo ""
echo "# Login no ACR:"
echo "az acr login --name $ACR_NAME"
echo ""
echo "# Push da imagem:"
echo "docker push $ACR_SERVER/$IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "# Deploy ACI:"
echo "az container create --resource-group $RESOURCE_GROUP --file aci-deploy.yaml"
echo ""
echo "# Logs da API:"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_GROUP --container-name clyvo-api"
echo ""
echo "# Logs do Oracle:"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_GROUP --container-name oracle-db"
echo ""

# ── RESUMO FINAL ─────────────────────────────────────────────
echo "================================================================"
echo -e " ${GREEN}✅  CLYVO PREDICT — SPRINT 3 PRONTO!${NC}"
echo "================================================================"
echo "  Resource Group   : $RESOURCE_GROUP"
echo "  ACR              : $ACR_SERVER"
echo "  Container Group  : $CONTAINER_GROUP"
echo "  API (Swagger)    : http://${APP_URL}:8080/swagger-ui.html"
echo "  API (Health)     : http://${APP_URL}:8080/actuator/health"
echo "  Oracle           : localhost:1521/CLYVODB (interno ao grupo)"
echo "  Storage (Volume) : $STORAGE_ACCOUNT / $FILE_SHARE"
echo "================================================================"
warn "APÓS O VÍDEO: delete todos os recursos:"
echo "  ./azure-destroy-sprint3.sh"
echo "================================================================"
echo ""

# Salva informações para uso posterior
cat > sprint3-info.txt << EOF
RESOURCE_GROUP=$RESOURCE_GROUP
ACR_NAME=$ACR_NAME
ACR_SERVER=$ACR_SERVER
CONTAINER_GROUP=$CONTAINER_GROUP
STORAGE_ACCOUNT=$STORAGE_ACCOUNT
APP_URL=http://${APP_URL}:8080
EOF
log "Informações salvas em sprint3-info.txt"
