#!/bin/bash

# Check if server and port are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <server> <port>"
    exit 1
fi

SERVER=$1
PORT=$2

# MySQL connection parameters
MYSQL_USER="sentinel"
MYSQL_PASS="yourpassword"
MYSQL_DB="sentinel"

# Log file
LOG_FILE="/usr/local/bin/results.log"

# Temporary file for HDSentinel output
TEMP_FILE=$(mktemp)

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to clean up temp file
cleanup() {
    rm -f "$TEMP_FILE"
    log "Temporary file $TEMP_FILE removed"
}

trap cleanup EXIT

log "Starting storage data import for server $SERVER on port $PORT"

# Connect to remote server and execute HDSentinel command
log "Connecting to $SERVER:$PORT and executing HDSentinel command"
ssh -p "$PORT" root@"$SERVER" "/usr/local/bin/HDSentinel" > "$TEMP_FILE" 2>&1

if [ $? -ne 0 ]; then
    log "Error: Failed to execute HDSentinel command on $SERVER"
    exit 1
fi

log "HDSentinel output saved to $TEMP_FILE"

# Function to properly escape and quote SQL values
sql_escape() {
    local value="$1"
    if [ -z "$value" ]; then
        echo "NULL"
    else
        # Escape single quotes and wrap in quotes
        echo "'$(echo "$value" | sed "s/'/''/g")'"
    fi
}

# Function to process integer values
sql_int() {
    local value="$1"
    if [ -z "$value" ] || [[ "$value" =~ [^0-9] ]]; then
        echo "NULL"
    else
        echo "$value"
    fi
}

# Process each disk in the output
process_disk() {
    local disk_data="$1"
    
    # Initialize all variables as empty
    storage_device=""
    storage_model_id=""
    storage_serial_no=""
    storage_revision=""
    storage_size_mb=""
    storage_interface=""
    storage_temperature=""
    storage_highest_temperature=""
    storage_health=""
    storage_performance=""
    storage_power_on_time=""
    storage_est_lifetime=""
    storage_comment=""
    storage_action=""

    # Extract fields with precise parsing
    storage_device=$(echo "$disk_data" | awk -F': ' '/HDD Device/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_model_id=$(echo "$disk_data" | awk -F': ' '/HDD Model ID/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_serial_no=$(echo "$disk_data" | awk -F': ' '/HDD Serial No/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_revision=$(echo "$disk_data" | awk -F': ' '/HDD Revision/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_size_mb=$(echo "$disk_data" | awk -F': | MB' '/HDD Size/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_interface=$(echo "$disk_data" | awk -F': ' '/Interface/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_temperature=$(echo "$disk_data" | awk -F': | °C' '/Temperature/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_highest_temperature=$(echo "$disk_data" | awk -F': | °C' '/Highest Temp/{print $2}' | awk '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_health=$(echo "$disk_data" | awk -F': | %' '/Health/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_performance=$(echo "$disk_data" | awk -F': | %' '/Performance/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_power_on_time=$(echo "$disk_data" | awk -F': ' '/Power on time/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    storage_est_lifetime=$(echo "$disk_data" | awk -F': ' '/Est. lifetime/{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Extract action (last non-empty line)
    storage_action=$(echo "$disk_data" | awk '/./{line=$0} END{print line}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Extract comment (all lines between Est. lifetime and before the action line)
    storage_comment=$(echo "$disk_data" | sed -n "/Est. lifetime:/,/$storage_action/{/Est. lifetime:/!{/$storage_action/!p;}}" | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    current_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Skip if we don't have a serial number or device (required fields)
    if [ -z "$storage_serial_no" ] || [ -z "$storage_device" ]; then
        log "Skipping invalid disk section (missing serial number or device)"
        log "Disk section content: $disk_data"
        return
    fi

    # Skip disks with invalid data
    if [ "$storage_serial_no" = "Unknown" ] || [ "$storage_device" = "Unknown" ]; then
        log "Skipping disk with invalid serial or device"
        return
    fi

    log "Processing disk $storage_serial_no ($storage_device) on $SERVER"
    log "Comment: $storage_comment"
    log "Action: $storage_action"
    
    # Check if disk exists in inventory
    existing_inventory=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -N -e "SELECT COUNT(*) FROM server_hdd_inventory WHERE storage_serial_no = '$(echo "$storage_serial_no" | sed "s/'/''/g")'")
    
    if [ "$existing_inventory" -eq 0 ]; then
        # Insert into inventory table
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e \
        "INSERT INTO server_hdd_inventory 
        (server_name, storage_device, storage_model_id, storage_serial_no, storage_size_mb, added_date, last_checked) 
        VALUES 
        ($(sql_escape "$SERVER"), $(sql_escape "$storage_device"), $(sql_escape "$storage_model_id"), 
         $(sql_escape "$storage_serial_no"), $(sql_int "$storage_size_mb"), '$current_time', '$current_time')"
        
        if [ $? -ne 0 ]; then
            log "Error: Failed to insert disk $storage_serial_no into inventory"
            return
        fi
        
        log "Inserted new disk $storage_serial_no into inventory"
    else
        # Update last_checked in inventory table
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e \
        "UPDATE server_hdd_inventory SET last_checked = '$current_time' WHERE storage_serial_no = '$(echo "$storage_serial_no" | sed "s/'/''/g")'"
        
        if [ $? -ne 0 ]; then
            log "Error: Failed to update disk $storage_serial_no in inventory"
            return
        fi
        
        log "Updated last_checked for disk $storage_serial_no in inventory"
    fi
    
    # Insert into health table (always insert new record, not replace)
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e \
    "INSERT INTO server_hdd_health 
    (storage_serial_no, storage_device, storage_model_id, storage_revision, storage_size_mb, storage_interface, 
     storage_temperature, storage_highest_temperature, storage_health, storage_performance, 
     storage_power_on_time, storage_est_lifetime, storage_comment, storage_action, last_checked) 
    VALUES 
    ($(sql_escape "$storage_serial_no"), $(sql_escape "$storage_device"), $(sql_escape "$storage_model_id"), 
     $(sql_escape "$storage_revision"), $(sql_int "$storage_size_mb"), $(sql_escape "$storage_interface"), 
     $(sql_escape "$storage_temperature"), $(sql_escape "$storage_highest_temperature"), $(sql_int "$storage_health"), 
     $(sql_int "$storage_performance"), $(sql_escape "$storage_power_on_time"), $(sql_escape "$storage_est_lifetime"), 
     $(sql_escape "$storage_comment"), $(sql_escape "$storage_action"), '$current_time')"
    
    if [ $? -ne 0 ]; then
        log "Error: Failed to insert health data for disk $storage_serial_no"
    else
        log "Inserted health data for disk $storage_serial_no"
    fi
}

# Process the HDSentinel output
log "Processing HDSentinel output"

# Read the file and process each disk section
disk_section=""
while IFS= read -r line; do
    # Skip header lines
    if [[ "$line" == *"Hard Disk Sentinel"* ]] || [[ "$line" == *"Examining hard disk configuration"* ]] || [[ "$line" == *"Start with -r"* ]]; then
        continue
    fi
    
    # If we hit a blank line, process the accumulated disk section
    if [[ -z "$line" ]]; then
        if [[ -n "$disk_section" ]]; then
            process_disk "$disk_section"
            disk_section=""
        fi
    else
        # Accumulate the disk section
        disk_section+="$line"$'\n'
    fi
done < "$TEMP_FILE"

# Process the last disk section if there wasn't a blank line at the end
if [[ -n "$disk_section" ]]; then
    process_disk "$disk_section"
fi

log "Storage data import completed for server $SERVER"
