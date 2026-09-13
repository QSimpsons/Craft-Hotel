-- ============================================================
-- Mallorca FPS - SQL installatie
-- Eenmalig uitvoeren in MySQL / MariaDB (HeidiSQL, phpMyAdmin…)
-- ============================================================

CREATE TABLE IF NOT EXISTS `mallorca_fps_settings` (
    `identifier` VARCHAR(72) NOT NULL,
    `btn_laag` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_boost` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_texturen` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_nogpu` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_grafics` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_vignette` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_zwartwit` TINYINT(1) NOT NULL DEFAULT 0,
    `btn_schaduwen` TINYINT(1) NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
