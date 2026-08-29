#!/bin/bash
# =================================================================
# CLYVO Predict — Sprint 3 | Remoção de todos os recursos Azure
# EXECUTE APÓS GRAVAR O VÍDEO — tire print como evidência!
# =================================================================

RESOURCE_GROUP="rg-clyvo-predict-s3"

echo "================================================================"
echo "  ⚠️  REMOÇÃO DE RECURSOS — Sprint 3 CLYVO Predict"
echo "================================================================"
echo ""
echo "  Removendo: $RESOURCE_GROUP"
echo "  (ACR, ACI, Storage Account e todos os recursos associados)"
echo ""
read -p "  Confirma? (s/N): " CONFIRM

if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
  az group delete \
    --name "$RESOURCE_GROUP" \
    --yes \
    --no-wait
  echo ""
  echo "✅ Remoção solicitada com sucesso!"
  echo ""
  echo "================================================================"
  echo "  📸 TIRE PRINT DESTA TELA PARA A ENTREGA!"
  echo "  Verifique em: https://portal.azure.com → Resource Groups"
  echo "================================================================"
else
  echo "❌ Cancelado."
fi
