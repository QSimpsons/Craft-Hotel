-- ============================================================
-- Mallorca Takel — SQL installatie
-- Eenmalig uitvoeren in HeidiSQL / phpMyAdmin (ESX Legacy)
-- ============================================================

INSERT INTO `jobs` (`name`, `label`)
SELECT 'takel', 'Mallorca Takel'
WHERE NOT EXISTS (SELECT 1 FROM `jobs` WHERE `name` = 'takel');

DELETE FROM `job_grades` WHERE `job_name` = 'takel';

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('takel', 0, 'stagiair', 'Stagiair', 250, '{}', '{}'),
('takel', 1, 'takelaar', 'Takelaar', 400, '{}', '{}'),
('takel', 2, 'senior', 'Senior', 550, '{}', '{}'),
('takel', 3, 'baas', 'Baas', 750, '{}', '{}');

CREATE TABLE IF NOT EXISTS `mallorca_impound` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(12) NOT NULL,
    `owner` VARCHAR(64) DEFAULT NULL,
    `props` LONGTEXT NOT NULL,
    `reason` VARCHAR(128) NOT NULL DEFAULT 'Getakeld',
    `officer` VARCHAR(64) DEFAULT NULL,
    `officer_name` VARCHAR(80) DEFAULT NULL,
    `price` INT NOT NULL DEFAULT 1500,
    `model` VARCHAR(64) DEFAULT NULL,
    `impounded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `plate` (`plate`),
    KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mallorca_takel_calls` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `caller` VARCHAR(64) DEFAULT NULL,
    `caller_name` VARCHAR(80) DEFAULT NULL,
    `pos_x` FLOAT NOT NULL DEFAULT 0,
    `pos_y` FLOAT NOT NULL DEFAULT 0,
    `pos_z` FLOAT NOT NULL DEFAULT 0,
    `message` VARCHAR(180) DEFAULT NULL,
    `kind` VARCHAR(16) NOT NULL DEFAULT 'player',
    `status` VARCHAR(16) NOT NULL DEFAULT 'open',
    `taker` VARCHAR(64) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optioneel: maatschappijrekening (alleen als esx_addonaccount geïnstalleerd is)
-- Fout negeren als de tabellen niet bestaan.

INSERT INTO `addon_account` (`name`, `label`, `shared`)
SELECT 'society_takel', 'Mallorca Takel', 1
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'addon_account')
  AND NOT EXISTS (SELECT 1 FROM `addon_account` WHERE `name` = 'society_takel');

INSERT INTO `addon_account_data` (`account_name`, `money`)
SELECT 'society_takel', 0
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'addon_account_data')
  AND NOT EXISTS (SELECT 1 FROM `addon_account_data` WHERE `account_name` = 'society_takel');
