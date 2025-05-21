<?php
// Database connection settings
define('DB_HOST', 'localhost');
define('DB_NAME', 'sentinel');
define('DB_USER', 'sentinel');
define('DB_PASS', 'yourpassword');

// Create connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
