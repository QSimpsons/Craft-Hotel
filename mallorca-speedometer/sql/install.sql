-- ============================================================
-- Mallorca Speedometer - SQL installatie
-- Eenmalig uitvoeren in MySQL / MariaDB (HeidiSQL, phpMyAdmin…)
-- ============================================================

-- Voeg brandstofkolom toe aan ESX owned_vehicles
-- Als de kolom al bestaat: foutmelding negeren / statement overslaan.
ALTER TABLE `owned_vehicles`
    ADD COLUMN `fuel` FLOAT NOT NULL DEFAULT 100.0;

-- Bestaande voertuigen op volle tank zetten waar nodig
UPDATE `owned_vehicles`
SET `fuel` = 100.0
WHERE `fuel` IS NULL OR `fuel` < 0 OR `fuel` > 100;
