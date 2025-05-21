-- phpMyAdmin SQL Dump
-- version 5.2.1deb1+deb12u1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 20, 2025 at 06:02 PM
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
-- Table structure for table `server_hdd_inventory`
--

CREATE TABLE `server_hdd_inventory` (
  `id` int(11) NOT NULL,
  `server_name` varchar(255) NOT NULL COMMENT 'Server hostname or identifier',
  `storage_device` varchar(255) NOT NULL COMMENT 'Device path (e.g., /dev/sdc)',
  `storage_model_id` varchar(255) DEFAULT NULL COMMENT 'HDD model identifier',
  `storage_serial_no` varchar(255) NOT NULL COMMENT 'Serial number (e.g., 2204E6018FA2)',
  `storage_size_mb` int(11) DEFAULT NULL COMMENT 'Size in megabytes',
  `added_date` datetime DEFAULT current_timestamp() COMMENT 'When this record was added',
  `last_checked` datetime DEFAULT NULL COMMENT 'Last time this storage device was verified'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Inventory of storage devices across servers';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `server_hdd_inventory`
--
ALTER TABLE `server_hdd_inventory`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `storage_serial_no` (`storage_serial_no`),
  ADD KEY `storage_serial_no_2` (`storage_serial_no`),
  ADD KEY `server_name` (`server_name`),
  ADD KEY `storage_device` (`storage_device`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `server_hdd_inventory`
--
ALTER TABLE `server_hdd_inventory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=80;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
