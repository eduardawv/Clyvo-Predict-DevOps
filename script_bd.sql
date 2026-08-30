-- =================================================================
-- CLYVO Predict — script_bd.sql (MySQL 8)
-- DDL das tabelas core + inserts significativos
-- =================================================================

CREATE TABLE IF NOT EXISTS tb_tutor (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome     VARCHAR(100) NOT NULL,
    email    VARCHAR(100) UNIQUE,
    telefone VARCHAR(20),
    senha    VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tb_pet (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL,
    especie      VARCHAR(50),
    raca         VARCHAR(50),
    idade        INT,
    peso         DECIMAL(5,2),
    health_score INT DEFAULT 100,
    tutor_id     BIGINT NOT NULL,
    CONSTRAINT fk_pet_tutor FOREIGN KEY (tutor_id) REFERENCES tb_tutor(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tb_evento_saude (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    tipo_evento  VARCHAR(50) NOT NULL,
    descricao    VARCHAR(300),
    data_evento  DATETIME DEFAULT CURRENT_TIMESTAMP,
    pet_id       BIGINT NOT NULL,
    CONSTRAINT fk_evento_pet FOREIGN KEY (pet_id) REFERENCES tb_pet(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inserts significativos (mínimo 2 por tabela)
INSERT INTO tb_tutor (nome, email, telefone, senha) VALUES
    ('Carlos Silva', 'carlos@email.com', '11999990001', '$2a$10$dummyhashvalue'),
    ('Ana Souza', 'ana@email.com', '11999990002', '$2a$10$dummyhashvalue'),
    ('Fernanda Lima', 'fernanda@email.com', '11999990003', '$2a$10$dummyhashvalue');

INSERT INTO tb_pet (nome, especie, raca, idade, peso, health_score, tutor_id) VALUES
    ('Thor', 'Cachorro', 'Golden Retriever', 5, 32.50, 85, 1),
    ('Luna', 'Gato', 'Siames', 3, 4.20, 92, 2),
    ('Mel', 'Cachorro', 'Poodle', 7, 8.50, 68, 3);

INSERT INTO tb_evento_saude (tipo_evento, descricao, data_evento, pet_id) VALUES
    ('VACINA', 'Vacina V10 polivalente aplicada', '2026-03-10', 1),
    ('CONSULTA_ROTINA', 'Check-up anual. Saude em dia.', '2026-01-15', 2);
