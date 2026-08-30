# 🐾 CLYVO Predict API — Sprint 3 DevOps

> **Java 17 · Spring Boot 3.5 · Oracle XE 21c · Docker · ACR + ACI · Azure**  
> FIAP Challenge 2026 — 2TDSPX Fevereiro  
> Disciplina: DevOps Tools & Cloud Computing

---

## 📋 Índice

1. [Descrição da Solução](#-descrição-da-solução)
2. [Benefícios para o Negócio](#-benefícios-para-o-negócio)
3. [Arquitetura da Solução](#-arquitetura-da-solução)
4. [Rotas da API (CRUD)](#-rotas-da-api-crud)
5. [Banco de Dados](#-banco-de-dados)
6. [Instalação e Deploy (How To)](#-instalação-e-deploy-how-to)
7. [Comandos Docker e Azure CLI](#-comandos-docker-e-azure-cli)
8. [Equipe](#-equipe)

---

## 📖 Descrição da Solução

O **CLYVO Predict** é uma plataforma SaaS veterinária que centraliza a gestão de pets, prontuários, vacinas e agendamentos, com um algoritmo de **Health Score** (0–100) que detecta riscos de saúde de forma preditiva.

**Stack:** Java 17 + Spring Boot 3.5 + Oracle XE 21c + Docker  
**Deploy:** Azure Container Registry (ACR) + Azure Container Instance (ACI)

---

## 💼 Benefícios para o Negócio

| # | Benefício | Impacto |
|---|-----------|---------|
| 1 | Health Score preditivo | Detecta riscos antes de doenças se manifestarem |
| 2 | Alertas automáticos | Lembretes de vacinas reduzem faltas em 40% |
| 3 | Gestão centralizada | Elimina fichas físicas e planilhas |
| 4 | App do tutor | Fideliza donos com transparência do histórico |
| 5 | Deploy containerizado | Escalabilidade com custo reduzido |
| 6 | Conformidade LGPD | Dados sensíveis protegidos |

---

## 🏗️ Arquitetura da Solução


![Arquitetura CLYVO Predict](documentos/arquitetura.png)

Usuário/Vet ──HTTP:8080──► clyvo-predict-api.<region>.azurecontainer.io

Legenda:
  ──► Requisição HTTP pública (porta 8080)
  ◄── Comunicação interna via localhost (containers no mesmo grupo ACI)
  [▼] Dados do Oracle persistidos em Azure Files (volume nomeado)


**Componentes:**
- **ACR** (Azure Container Registry) — Armazena a imagem Docker da API
- **ACI** (Azure Container Instance) — Executa os containers em nuvem
- **Container Group** — Agrupa Oracle + API compartilhando `localhost`
- **Azure Files** — Provê volume nomeado persistente para o Oracle

---

## 🛣️ Rotas da API (CRUD)

**Base URL:** `http://clyvo-predict-api.eastus.azurecontainer.io:8080`  
**Swagger UI:** `http://clyvo-predict-api.eastus.azurecontainer.io:8080/swagger-ui.html`

### 🐾 Pets — `/api/pets`

| Método | Rota | Descrição | HTTP |
|--------|------|-----------|------|
| `GET` | `/api/pets` | Lista todos os pets | 200 |
| `GET` | `/api/pets/{id}` | Busca pet por ID | 200 / 404 |
| `POST` | `/api/pets` | Cadastra novo pet | 201 |
| `PUT` | `/api/pets/{id}` | Atualiza pet | 200 / 404 |
| `DELETE` | `/api/pets/{id}` | Remove pet | 204 / 404 |

### 👤 Tutores — `/api/tutores`

| Método | Rota | Descrição | HTTP |
|--------|------|-----------|------|
| `GET` | `/api/tutores` | Lista tutores | 200 |
| `GET` | `/api/tutores/{id}` | Busca por ID | 200 / 404 |
| `POST` | `/api/tutores` | Cadastra tutor | 201 |
| `PUT` | `/api/tutores/{id}` | Atualiza tutor | 200 / 404 |
| `DELETE` | `/api/tutores/{id}` | Remove tutor | 204 / 404 |

---

## 🗄️ Banco de Dados

**Banco:** Oracle XE 21c (containerizado no ACI)  
**DDL completo:** [`script_bd.sql`](./script_bd.sql)  
**Tabelas core:** `PET` e `TUTOR` (relacionadas por FK)

```sql
-- Tutor (dono do pet)
CREATE TABLE TUTOR (
    id_tutor NUMBER NOT NULL,
    nome     VARCHAR2(100) NOT NULL,
    email    VARCHAR2(100),
    telefone VARCHAR2(20),
    CONSTRAINT TUTOR_PK PRIMARY KEY (id_tutor)
);

-- Pet (paciente com Health Score e FK para Tutor)
CREATE TABLE PET (
    id_pet       NUMBER NOT NULL,
    nome         VARCHAR2(100) NOT NULL,
    especie      VARCHAR2(50),
    score_saude  NUMBER(5,2),
    status_risco VARCHAR2(20),
    id_tutor     NUMBER NOT NULL,
    CONSTRAINT PET_PK PRIMARY KEY (id_pet),
    CONSTRAINT PET_TUTOR_FK FOREIGN KEY (id_tutor) REFERENCES TUTOR(id_tutor)
);
```

---

## 🚀 Instalação e Deploy (How To)

### Pré-requisitos

| Ferramenta | Versão |
|------------|--------|
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | 2.50+ |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 24+ |
| Conta Azure ativa | — |

---

### Deploy completo na nuvem (do zero)

```bash
# 1. Clone o repositório
git clone https://github.com/gabrielalandim/clyvo-predict.git
cd clyvo-predict

# 2. Copie o application-prod.properties
cp devops/application-prod.properties src/main/resources/

# 3. Autentique no Azure
az login

# 4. Execute o script completo
chmod +x devops/azure-setup-sprint3.sh
./devops/azure-setup-sprint3.sh

# ✅ O script irá:
#   - Criar Resource Group
#   - Criar ACR (Container Registry)
#   - Build + push da imagem
#   - Criar Storage Account + Azure Files (volume nomeado)
#   - Criar ACI multi-container (Oracle + API)
#
# Acesse: http://clyvo-predict-api.eastus.azurecontainer.io:8080/swagger-ui.html
```

---

### Verificar status e logs

```bash
# Status do Container Group
az container show \
  --resource-group rg-clyvo-predict-s3 \
  --name clyvo-predict-group \
  --output table

# Logs da API Java
az container logs \
  --resource-group rg-clyvo-predict-s3 \
  --name clyvo-predict-group \
  --container-name clyvo-api

# Logs do Oracle
az container logs \
  --resource-group rg-clyvo-predict-s3 \
  --name clyvo-predict-group \
  --container-name oracle-db
```

---

### Deletar recursos ao final (obrigatório)

```bash
chmod +x devops/azure-destroy-sprint3.sh
./devops/azure-destroy-sprint3.sh

# Ou diretamente:
az group delete --name rg-clyvo-predict-s3 --yes --no-wait
```

---

## 🐳 Comandos Docker e Azure CLI

```bash
# ── Build da imagem ──────────────────────────────────────────
docker build -t clyvopredictacr.azurecr.io/clyvo-predict:latest .

# ── Login no ACR ─────────────────────────────────────────────
az acr login --name clyvopredictacr

# ── Push para o ACR ──────────────────────────────────────────
docker push clyvopredictacr.azurecr.io/clyvo-predict:latest

# ── Listar imagens no ACR ────────────────────────────────────
az acr repository list --name clyvopredictacr --output table

# ── Deploy ACI via YAML ──────────────────────────────────────
az container create \
  --resource-group rg-clyvo-predict-s3 \
  --file devops/aci-deploy.yaml

# ── Restart do container group ───────────────────────────────
az container restart \
  --resource-group rg-clyvo-predict-s3 \
  --name clyvo-predict-group
```

---

## 👥 Equipe

| Nome Completo | RM |
|---------------|----|
| Eduarda Weiss Ventura | RM: 564434 |
| Maria Gabriela Landim Severo | RM: 565146 |
| Samara Porto Souza | RM: 559072 |
| Lucas Nunes Soares | RM: 566503 |
| Camily Vitoria Pereira Maciel | RM: 566520 |

**Turma:** 2TDSPX — Fevereiro 2026  
**Disciplina:** DevOps Tools & Cloud Computing  
**Sprint:** 3

---

<p align="center">Feito com ❤️ pela equipe CLYVO Predict · FIAP 2026</p>
