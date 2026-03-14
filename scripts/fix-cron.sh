#!/bin/bash
set -e

OPENCLAW_BIN=$(which openclaw)
if [ -z "$OPENCLAW_BIN" ]; then
    echo "Error: openclaw binary not found."
    exit 1
fi

echo "Using openclaw binary at: $OPENCLAW_BIN"

# 1. Remove auto-generated internal cron jobs
echo "Removing conflicting internal cron jobs..."
# We filter for jobs starting with "antfarm/infra-ops"
# (Adjust output parsing as needed; this assumes --json format works)
JOBS_JSON=$($OPENCLAW_BIN cron list --json 2>/dev/null || echo "{}")
# Extract IDs using jq (if available) or basic grep/sed if not. 
# Assuming jq is available given the environment.
if command -v jq &> /dev/null; then
    echo "$JOBS_JSON" | jq -r '.jobs[]? | select(.name | startswith("antfarm/infra-ops")) | .id' | while read -r id; do
        if [ ! -z "$id" ]; then
            echo "Removing internal job $id..."
            $OPENCLAW_BIN cron rm "$id"
        fi
    done
else
    echo "Warning: jq not found. Please remove internal cron jobs manually using 'openclaw cron list' and 'openclaw cron rm'."
fi

# 2. Add to system crontab
echo "Adding system cron jobs..."

# Function to add cron line if not exists
add_cron_job() {
    local cmd="$1"
    local schedule="$2"
    # value to grep for to avoid duplicates
    local grep_key="$cmd"
    
    # Check if job exists
    if crontab -l 2>/dev/null | grep -Fq "$grep_key"; then
        echo "Cron job already exists: $grep_key"
    else
        echo "Adding cron job: $grep_key"
        (crontab -l 2>/dev/null; echo "$schedule $cmd") | crontab -
    fi
}

# The command to poll the agent
# We start a new session or use main? 'openclaw agent --agent ID --message "poll"'
# We redirect output to /tmp/openclaw-cron.log for debugging
LOG_FILE="/tmp/openclaw-infra-ops-cron.log"

add_cron_job "$OPENCLAW_BIN agent --agent infra-ops_planner --message 'poll' >> $LOG_FILE 2>&1" "*/5 * * * *"
add_cron_job "$OPENCLAW_BIN agent --agent infra-ops_operator --message 'poll' >> $LOG_FILE 2>&1" "*/5 * * * *"
add_cron_job "$OPENCLAW_BIN agent --agent infra-ops_verifier --message 'poll' >> $LOG_FILE 2>&1" "*/5 * * * *"
add_cron_job "$OPENCLAW_BIN agent --agent infra-ops_scribe --message 'poll' >> $LOG_FILE 2>&1" "*/5 * * * *"

echo "System crontab updated."
crontab -l
