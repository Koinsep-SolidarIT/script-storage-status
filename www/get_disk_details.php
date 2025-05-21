<?php
require_once 'db.php';

if (isset($_GET['model_id'])) {
    $model_id = $conn->real_escape_string($_GET['model_id']);
    
    $query = "SELECT * FROM server_hdd_health WHERE storage_model_id = '$model_id'";
    $result = $conn->query($query);
    
    if ($result && $result->num_rows > 0) {
        $disk = $result->fetch_assoc();
        
        echo '<h3>Disk Details: ' . htmlspecialchars($disk['storage_model_id']) . '</h3>';
        echo '<table>';
        
        // Display all disk details
        $details = [
            'Server Name' => $disk['server_name'] ?? 'N/A',
            'Device' => $disk['storage_device'],
            'Model' => $disk['storage_model_id'],
            'Revision' => $disk['storage_revision'] ?? 'N/A',
            'Size (MB)' => number_format($disk['storage_size_mb'] ?? 0),
            'Interface' => $disk['storage_interface'] ?? 'N/A',
            'Current Temperature' => $disk['storage_temperature'] ?? 'N/A',
            'Highest Temperature' => $disk['storage_highest_temperature'] ?? 'N/A',
            'Health' => ($disk['storage_health'] ?? 'N/A') . '%',
            'Performance' => ($disk['storage_performance'] ?? 'N/A') . '%',
            'Power On Time' => $disk['storage_power_on_time'] ?? 'N/A',
            'Estimated Lifetime' => $disk['storage_est_lifetime'] ?? 'N/A',
            'Status Comment' => $disk['storage_comment'] ?? 'N/A',
            'Recommended Action' => $disk['storage_action'] ?? 'N/A',
            'Last Checked' => $disk['last_checked'] ?? 'N/A'
        ];
        
        foreach ($details as $label => $value) {
            echo '<tr>';
            echo '<th>' . $label . '</th>';
            echo '<td>' . htmlspecialchars($value) . '</td>';
            echo '</tr>';
        }
        
        echo '</table>';
    } else {
        echo '<p>No details found for this disk model.</p>';
    }
} else {
    echo '<p>No disk model specified.</p>';
}
?>
