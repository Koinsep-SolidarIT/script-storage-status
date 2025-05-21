-- phpMyAdmin SQL Dump
-- version 5.2.1deb1+deb12u1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 20, 2025 at 06:01 PM
-- Server version: 10.11.11-MariaDB-0+deb12u1
-- PHP Version: 8.2.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sentinel`
--

-- --------------------------------------------------------

--
-- Table structure for table `server_hdd_health`
--

CREATE TABLE `server_hdd_health` (
  `id` int(11) NOT NULL,
  `storage_serial_no` varchar(255) NOT NULL COMMENT 'Serial number (e.g., 2204E6018FA2)',
  `storage_device` varchar(255) NOT NULL COMMENT 'HDD Device (e.g., 0: /dev/sda)',
  `storage_model_id` varchar(255) DEFAULT NULL COMMENT 'Model (e.g., CT500MX500SSD1)',
  `storage_revision` varchar(255) DEFAULT NULL COMMENT 'Revision (e.g., M3CR043)',
  `storage_size_mb` int(11) DEFAULT NULL COMMENT 'Size in MB (e.g., 476940 MB)',
  `storage_interface` varchar(255) DEFAULT NULL COMMENT 'Interface type (e.g., S-ATA Gen3, 6 Gbps)',
  `storage_temperature` varchar(50) DEFAULT NULL COMMENT 'Current temperature (e.g., 31 °C)',
  `storage_highest_temperature` varchar(50) DEFAULT NULL COMMENT 'Highest recorded temperature (e.g., 48 °C)',
  `storage_health` int(11) DEFAULT NULL COMMENT 'Health percentage (e.g., 65 %)',
  `storage_performance` int(11) DEFAULT NULL COMMENT 'Performance percentage (e.g., 100 %)',
  `storage_power_on_time` varchar(255) DEFAULT NULL COMMENT 'Power on time (e.g., 832 days, 7 hours)',
  `storage_est_lifetime` varchar(255) DEFAULT NULL COMMENT 'Estimated remaining lifetime (e.g., 419 days)',
  `storage_comment` text DEFAULT NULL COMMENT 'Status comment (e.g., The status of the solid state disk is PERFECT.)',
  `storage_action` text DEFAULT NULL COMMENT 'Recommended action (e.g., It is recommended to continuously monitor the hard disk status.)',
  `last_checked` datetime DEFAULT NULL COMMENT 'Last time this storage device was verified'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Health metrics for storage devices';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `server_hdd_health`
--
ALTER TABLE `server_hdd_health`
  ADD PRIMARY KEY (`id`),
  ADD KEY `storage_serial_no_2` (`storage_serial_no`),
  ADD KEY `storage_device` (`storage_device`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `server_hdd_health`
--
ALTER TABLE `server_hdd_health`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `server_hdd_health`
--
ALTER TABLE `server_hdd_health`
  ADD CONSTRAINT `server_hdd_health_ibfk_1` FOREIGN KEY (`storage_serial_no`) REFERENCES `server_hdd_inventory` (`storage_serial_no`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
