-- =============================================
-- O2C DATABASE CREATION SCRIPT
-- Creates the database with proper settings
-- =============================================

-- Set connection parameters
SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

-- Drop and create database
DROP DATABASE IF EXISTS `o2c`;
CREATE DATABASE `o2c` 
    DEFAULT CHARACTER SET utf8mb4 
    COLLATE utf8mb4_0900_ai_ci 
    DEFAULT ENCRYPTION='N';

-- Use the database
USE `o2c`;

-- Create database info table for tracking
CREATE TABLE `db_info` (
    `info_key` VARCHAR(50) PRIMARY KEY,
    `info_value` VARCHAR(200),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Insert database metadata
INSERT INTO `db_info` (`info_key`, `info_value`) VALUES
('database_name', 'Order-to-Cash Analytics Database'),
('version', '1.0'),
('created_by', 'O2C Analytics Project'),
('description', 'Complete order-to-cash business process database'),
('last_data_refresh', NOW());

-- Display creation confirmation
SELECT 'Database created successfully!' as Status;
SELECT DATABASE() as Current_Database;
SELECT * FROM db_info;
