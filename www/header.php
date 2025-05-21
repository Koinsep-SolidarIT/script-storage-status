<?php
require_once 'db.php';

// Get counts for header
$server_count = 0;
$disk_count = 0;

$server_query = "SELECT COUNT(DISTINCT server_name) as count FROM server_hdd_inventory";
$result = $conn->query($server_query);
if ($result) {
    $row = $result->fetch_assoc();
    $server_count = $row['count'];
}

$disk_query = "SELECT COUNT(storage_model_id) as count FROM server_hdd_inventory";
$result = $conn->query($disk_query);
if ($result) {
    $row = $result->fetch_assoc();
    $disk_count = $row['count'];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My storage disks status</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <div class="header-container">
            <div class="header-logo">
                <img src="logo.png" alt="Logo" width="150" height="150">
            </div>
            <div class="header-title">
                <h1>My storage disks status</h1>
            </div>
            <div class="header-stats">
                <div class="stat-item">
                    <span class="stat-number"><?php echo $server_count; ?></span>
                    <span class="stat-label">Servers</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number"><?php echo $disk_count; ?></span>
                    <span class="stat-label">Hard Disks</span>
                </div>
            </div>
        </div>
    </header>
