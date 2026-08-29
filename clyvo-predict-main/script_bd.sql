-- =================================================================
-- CLYVO Predict — script_bd.sql
-- DDL das tabelas core da aplicação
-- Disciplina: DevOps Tools & Cloud Computing — Sprint 3
-- FIAP 2026 — 2TDS Fevereiro
-- =================================================================
-- TABELAS CORE: PET e TUTOR (relacionadas entre si)
-- CRUD completo implementado na API Java Spring Boot
-- =================================================================

-- ── TUTOR ─────────────────────────────────────────────────────
CREATE TABLE TUTOR (
    id_tutor  NUMBER        NOT NULL,
    nome      VARCHAR2(100) NOT NULL,
    email     VARCHAR2(100),
    telefone  VARCHAR2(20)
);

ALTER TABLE TUTOR
    ADD CONSTRAINT TUTOR_PK PRIMARY KEY (id_tutor);

ALTER TABLE TUTOR
    ADD CONSTRAINT TUTOR_EMAIL_UK UNIQUE (email);

COMMENT ON TABLE  TUTOR           IS 'Donos dos pets cadastrados no sistema';
COMMENT ON COLUMN TUTOR.id_tutor  IS 'Identificador único do tutor';
COMMENT ON COLUMN TUTOR.nome      IS 'Nome completo do tutor';
COMMENT ON COLUMN TUTOR.email     IS 'E-mail único para login e alertas';
COMMENT ON COLUMN TUTOR.telefone  IS 'Telefone para contato via WhatsApp';

-- ── PET ───────────────────────────────────────────────────────
CREATE TABLE PET (
    id_pet       NUMBER        NOT NULL,
    nome         VARCHAR2(100) NOT NULL,
    especie      VARCHAR2(50),
    raca         VARCHAR2(50),
    idade        NUMBER,
    peso         NUMBER(5,2),
    score_saude  NUMBER(5,2),
    status_risco VARCHAR2(20),
    id_tutor     NUMBER        NOT NULL
);

ALTER TABLE PET
    ADD CONSTRAINT PET_PK PRIMARY KEY (id_pet);

ALTER TABLE PET
    ADD CONSTRAINT PET_TUTOR_FK FOREIGN KEY (id_tutor)
    REFERENCES TUTOR (id_tutor);

ALTER TABLE PET
    ADD CONSTRAINT PET_SCORE_CHK
    CHECK (score_saude BETWEEN 0 AND 100);

ALTER TABLE PET
    ADD CONSTRAINT PET_RISCO_CHK
    CHECK (status_risco IN ('BAIXO', 'MODERADO', 'ALTO', 'CRITICO'));

COMMENT ON TABLE  PET              IS 'Pacientes veterinários com Health Score';
COMMENT ON COLUMN PET.id_pet       IS 'Identificador único do pet';
COMMENT ON COLUMN PET.nome         IS 'Nome do pet';
COMMENT ON COLUMN PET.especie      IS 'Espécie (Cachorro, Gato, etc.)';
COMMENT ON COLUMN PET.raca         IS 'Raça do animal';
COMMENT ON COLUMN PET.score_saude  IS 'Health Score de 0 a 100 (algorítmo proprietário)';
COMMENT ON COLUMN PET.status_risco IS 'Classificação de risco: BAIXO, MODERADO, ALTO, CRITICO';
COMMENT ON COLUMN PET.id_tutor     IS 'FK para o dono do pet';

-- ── INSERTS SIGNIFICATIVOS ────────────────────────────────────

-- Tutores (mínimo 2 inserts com conteúdo significativo)
INSERT INTO TUTOR VALUES (1, 'Carlos Silva',   'carlos@email.com',   '11999990001');
INSERT INTO TUTOR VALUES (2, 'Ana Souza',       'ana@email.com',       '11999990002');
INSERT INTO TUTOR VALUES (3, 'Fernanda Lima',   'fernanda@email.com',  '11999990003');

-- Pets (com relacionamento ao tutor via FK)
INSERT INTO PET VALUES (1, 'Thor', 'Cachorro', 'Golden Retriever', 5, 32.5, 85, 'MODERADO', 1);
INSERT INTO PET VALUES (2, 'Luna', 'Gato',     'Siames',           3,  4.2, 92, 'BAIXO',    2);
INSERT INTO PET VALUES (3, 'Mel',  'Cachorro', 'Poodle',           7,  8.5, 68, 'ALTO',     3);

COMMIT;
