-- =====================================================
-- TABELA: player_suspension
-- Armazena as configurações de suspensão por veículo
-- =====================================================

CREATE TABLE IF NOT EXISTS `player_suspension` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL COMMENT 'Identifier do jogador (ESX)',
    `plate` VARCHAR(20) NOT NULL COMMENT 'Matrícula do veículo',
    `pressure` FLOAT NOT NULL DEFAULT 0 COMMENT 'Pressão atual das bolsas (PSI)',
    `cylinder` FLOAT NOT NULL DEFAULT 0 COMMENT 'Nível de ar no cilindro',
    `installed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0 = Não instalado, 1 = Instalado',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_vehicle` (`identifier`, `plate`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABELA: suspension_presets
-- Armazena os presets salvos (botões 1, 2, 3)
-- =====================================================

CREATE TABLE IF NOT EXISTS `suspension_presets` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL COMMENT 'Identifier do jogador (ESX)',
    `plate` VARCHAR(20) NOT NULL COMMENT 'Matrícula do veículo',
    `preset_slot` TINYINT(1) NOT NULL COMMENT 'Slot do preset (1, 2 ou 3)',
    `pressure` FLOAT NOT NULL COMMENT 'Pressão salva no preset',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_preset` (`identifier`, `plate`, `preset_slot`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- ITEM: controle_ar (Opcional - se usar requireItem)
-- Adiciona o item ao banco de dados do ESX
-- =====================================================

-- IMPORTANTE: Execute este INSERT apenas se você quer usar o sistema de item
-- Caso contrário, configure requireItem.active = false no config.lua

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) 
VALUES ('controle_ar', 'Controle de Suspensão AR', 1, 0, 1)
ON DUPLICATE KEY UPDATE 
    `label` = 'Controle de Suspensão AR',
    `weight` = 1;

-- =====================================================
-- ÍNDICES ADICIONAIS PARA PERFORMANCE
-- =====================================================

-- Otimiza buscas por veículo específico
ALTER TABLE `player_suspension` 
ADD INDEX `idx_vehicle_lookup` (`plate`, `identifier`);

-- Otimiza buscas de presets
ALTER TABLE `suspension_presets` 
ADD INDEX `idx_preset_lookup` (`identifier`, `plate`, `preset_slot`);

-- =====================================================
-- DADOS DE TESTE (OPCIONAL - REMOVER EM PRODUÇÃO)
-- =====================================================

-- Exemplo de veículo com suspensão instalada
-- INSERT INTO `player_suspension` (`identifier`, `plate`, `pressure`, `cylinder`, `installed`)
-- VALUES ('char1:123456789abcdef', 'ABC 1234', 15.0, 100.0, 1);

-- Exemplo de preset salvo
-- INSERT INTO `suspension_presets` (`identifier`, `plate`, `preset_slot`, `pressure`)
-- VALUES ('char1:123456789abcdef', 'ABC 1234', 1, 10.0);