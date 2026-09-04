-- ESX 1.15.0 users table does not include status by default.
ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `status` LONGTEXT DEFAULT NULL;
