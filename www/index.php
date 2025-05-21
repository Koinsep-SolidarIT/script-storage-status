<?php
require_once 'header.php';
require_once 'db.php';

// Initialize variables
$server_filter = isset($_GET['server']) ? $_GET['server'] : '';
$search_term = isset($_GET['search']) ? $_GET['search'] : '';
$page = isset($_GET['page']) ? intval($_GET['page']) : 1;
$per_page = isset($_GET['per_page']) ? intval($_GET['per_page']) : 20;

// Validate per_page
$valid_per_page = [20, 50, 0];
if (!in_array($per_page, $valid_per_page)) {
    $per_page = 20;
}

// Build query to get latest data for each disk
$query = "SELECT hd.id, hd.server_name, hd.storage_device, hd.storage_model_id, hd.storage_size_mb, 
                 hh.storage_temperature, hh.storage_health, hh.storage_performance, hh.last_checked
          FROM (
            SELECT storage_serial_no, MAX(last_checked) as latest_check 
            FROM server_hdd_health 
            GROUP BY storage_serial_no
          ) as latest
          JOIN server_hdd_health hh ON latest.storage_serial_no = hh.storage_serial_no AND latest.latest_check = hh.last_checked
          JOIN server_hdd_inventory hd ON hh.storage_serial_no = hd.storage_serial_no
          WHERE 1=1";

$count_query = "SELECT COUNT(*) as total FROM (
                  SELECT storage_serial_no, MAX(last_checked) as latest_check 
                  FROM server_hdd_health 
                  GROUP BY storage_serial_no
                ) as latest
                JOIN server_hdd_health hh ON latest.storage_serial_no = hh.storage_serial_no AND latest.latest_check = hh.last_checked
                JOIN server_hdd_inventory hd ON hh.storage_serial_no = hd.storage_serial_no
                WHERE 1=1";

// Apply filters
if (!empty($server_filter)) {
    $query .= " AND hd.server_name = '" . $conn->real_escape_string($server_filter) . "'";
    $count_query .= " AND hd.server_name = '" . $conn->real_escape_string($server_filter) . "'";
}

if (!empty($search_term)) {
    $search_term = $conn->real_escape_string($search_term);
    $query .= " AND (hd.storage_model_id LIKE '%$search_term%' OR hd.storage_serial_no LIKE '%$search_term%')";
    $count_query .= " AND (hd.storage_model_id LIKE '%$search_term%' OR hd.storage_serial_no LIKE '%$search_term%')";
}

// Map sortable columns to their table references
$sort_columns = [
    'server_name' => 'hd.server_name',
    'storage_device' => 'hd.storage_device',
    'storage_size_mb' => 'hd.storage_size_mb',
    'storage_temperature' => 'hh.storage_temperature',
    'storage_health' => 'hh.storage_health',
    'storage_performance' => 'hh.storage_performance',
    'last_checked' => 'hh.last_checked'
];

// Add sorting
$sort = isset($_GET['sort']) ? $_GET['sort'] : 'last_checked';
$order = isset($_GET['order']) ? $_GET['order'] : 'DESC';

// Validate sort column
if (!array_key_exists($sort, $sort_columns)) {
    $sort = 'hh.last_checked';
} else {
    $sort = $sort_columns[$sort];
}

$query .= " ORDER BY $sort $order";

// Get total count
$result = $conn->query($count_query);
$total_rows = $result->fetch_assoc()['total'];

// Add pagination
if ($per_page > 0) {
    $offset = ($page - 1) * $per_page;
    $query .= " LIMIT $offset, $per_page";
}

// Execute main query
$result = $conn->query($query);

// Get server list for dropdown
$servers_query = "SELECT hd.server_name, COUNT(*) as disk_count 
                  FROM server_hdd_inventory hd
                  GROUP BY hd.server_name
                  ORDER BY hd.server_name";
$servers_result = $conn->query($servers_query);

// Function to check if date is older than 2 days
function isOlderThanTwoDays($date) {
    if (empty($date)) return true;
    $dateTime = new DateTime($date);
    $now = new DateTime();
    $interval = $now->diff($dateTime);
    return $interval->days > 2;
}
?>

<div class="container">
    <div class="top-bar">
        <select id="server-select" onchange="filterByServer()">
            <option value="">All Servers</option>
            <?php while ($server = $servers_result->fetch_assoc()): ?>
                <option value="<?php echo htmlspecialchars($server['server_name']); ?>" <?php echo ($server_filter == $server['server_name']) ? 'selected' : ''; ?>>
                    <?php echo htmlspecialchars($server['server_name']); ?> (<?php echo $server['disk_count']; ?>)
                </option>
            <?php endwhile; ?>
        </select>
        
        <input type="text" id="search-input" placeholder="Search by model or serial" value="<?php echo htmlspecialchars($search_term); ?>">
        <button onclick="searchDisks()">Search</button>
        <button onclick="resetFilters()">Reset</button>
    </div>

    <table>
        <thead>
            <tr>
                <th onclick="sortTable('server_name')">Server Name</th>
                <th onclick="sortTable('storage_device')">Device</th>
                <th>Model</th>
                <th onclick="sortTable('storage_size_mb')">Size (MB)</th>
                <th onclick="sortTable('storage_temperature')">Temperature</th>
                <th onclick="sortTable('storage_health')">Health</th>
                <th onclick="sortTable('storage_performance')">Performance</th>
                <th onclick="sortTable('last_checked')">Last Checked</th>
            </tr>
        </thead>
        <tbody>
            <?php if ($result && $result->num_rows > 0): ?>
                <?php while ($row = $result->fetch_assoc()): ?>
                    <?php
                    // Determine cell classes with proper parentheses for ternary operators
                    $healthClass = '';
                    if (isset($row['storage_health'])) {
                        $healthClass = ($row['storage_health'] < 95) ? 'warning-cell' : 
                                      (($row['storage_health'] == 100) ? 'healthy-cell' : '');
                    }
                    
                    $performanceClass = '';
                    if (isset($row['storage_performance'])) {
                        $performanceClass = ($row['storage_performance'] == 100) ? 'healthy-cell' : 'warning-cell';
                    }
                    
                    $lastCheckedClass = isOlderThanTwoDays($row['last_checked'] ?? '') ? 'critical-cell' : '';
                    ?>
                    <tr>
                        <td><?php echo htmlspecialchars($row['server_name'] ?? 'N/A'); ?></td>
                        <td><?php echo htmlspecialchars($row['storage_device'] ?? 'N/A'); ?></td>
                        <td>
                            <a href="#" onclick="showDiskDetails('<?php echo htmlspecialchars($row['storage_model_id'] ?? ''); ?>')">
                                <?php echo htmlspecialchars($row['storage_model_id'] ?? 'N/A'); ?>
                            </a>
                        </td>
                        <td><?php echo isset($row['storage_size_mb']) ? number_format($row['storage_size_mb']) : 'N/A'; ?></td>
                        <td><?php echo htmlspecialchars($row['storage_temperature'] ?? 'N/A'); ?> °C</td>
                        <td class="<?php echo $healthClass; ?>"><?php echo isset($row['storage_health']) ? $row['storage_health'] . '%' : 'N/A'; ?></td>
                        <td class="<?php echo $performanceClass; ?>"><?php echo isset($row['storage_performance']) ? $row['storage_performance'] . '%' : 'N/A'; ?></td>
                        <td class="<?php echo $lastCheckedClass; ?>"><?php echo htmlspecialchars($row['last_checked'] ?? 'N/A'); ?></td>
                    </tr>
                <?php endwhile; ?>
            <?php else: ?>
                <tr>
                    <td colspan="8">No disks found</td>
                </tr>
            <?php endif; ?>
        </tbody>
    </table>

    <div class="pagination">
        <div>
            <select id="per-page-select" onchange="changePerPage()">
                <option value="20" <?php echo ($per_page == 20) ? 'selected' : ''; ?>>20 per page</option>
                <option value="50" <?php echo ($per_page == 50) ? 'selected' : ''; ?>>50 per page</option>
                <option value="0" <?php echo ($per_page == 0) ? 'selected' : ''; ?>>View all</option>
            </select>
        </div>
        <div class="pagination-controls">
            <?php if ($per_page > 0 && $total_rows > $per_page): ?>
                <?php $total_pages = ceil($total_rows / $per_page); ?>
                <?php if ($page > 1): ?>
                    <button onclick="goToPage(<?php echo $page - 1; ?>)">Previous</button>
                <?php endif; ?>
                
                <span>Page <?php echo $page; ?> of <?php echo $total_pages; ?></span>
                
                <?php if ($page < $total_pages): ?>
                    <button onclick="goToPage(<?php echo $page + 1; ?>)">Next</button>
                <?php endif; ?>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Modal for disk details -->
<div id="disk-modal" class="modal">
    <div class="modal-content">
        <span class="close" onclick="closeModal()">&times;</span>
        <div id="disk-details" class="disk-details">
            <!-- Disk details will be loaded here -->
        </div>
    </div>
</div>

<style>
    .warning-cell {
        background-color: #ffdddd; /* Light red */
        font-weight: bold;
    }
    
    .critical-cell {
        background-color: #ff9999; /* Stronger red */
        font-weight: bold;
        color: #800000;
    }
    
    .healthy-cell {
        background-color: #ddffdd; /* Light green */
        font-weight: bold;
    }
</style>

<script>
    function filterByServer() {
        const server = document.getElementById('server-select').value;
        updateUrl({ server: server, page: 1 });
    }

    function searchDisks() {
        const search = document.getElementById('search-input').value;
        updateUrl({ search: search, page: 1 });
    }

    function resetFilters() {
        updateUrl({ server: '', search: '', page: 1 });
    }

    function sortTable(column) {
        const urlParams = new URLSearchParams(window.location.search);
        let order = 'ASC';
        
        if (urlParams.get('sort') === column) {
            order = urlParams.get('order') === 'ASC' ? 'DESC' : 'ASC';
        }
        
        updateUrl({ sort: column, order: order });
    }

    function changePerPage() {
        const perPage = document.getElementById('per-page-select').value;
        updateUrl({ per_page: perPage, page: 1 });
    }

    function goToPage(page) {
        updateUrl({ page: page });
    }

    function updateUrl(params) {
        const urlParams = new URLSearchParams(window.location.search);
        
        // Update parameters
        for (const key in params) {
            if (params[key] === '' || params[key] === null) {
                urlParams.delete(key);
            } else {
                urlParams.set(key, params[key]);
            }
        }
        
        // Reload page with new parameters
        window.location.search = urlParams.toString();
    }

    function showDiskDetails(modelId) {
        const modal = document.getElementById('disk-modal');
        const detailsDiv = document.getElementById('disk-details');
        
        // Show loading message
        detailsDiv.innerHTML = '<p>Loading disk details...</p>';
        modal.style.display = 'block';
        
        // Fetch disk details via AJAX
        fetch(`get_disk_details.php?model_id=${encodeURIComponent(modelId)}`)
            .then(response => response.text())
            .then(data => {
                detailsDiv.innerHTML = data;
            })
            .catch(error => {
                detailsDiv.innerHTML = `<p>Error loading disk details: ${error}</p>`;
            });
    }

    function closeModal() {
        document.getElementById('disk-modal').style.display = 'none';
    }

    // Close modal when clicking outside of it
    window.onclick = function(event) {
        const modal = document.getElementById('disk-modal');
        if (event.target == modal) {
            closeModal();
        }
    }
</script>

<?php require_once 'footer.php'; ?>
