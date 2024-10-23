#!/bin/bash
# Insert your rated.network API key here:
RATED_API_KEY=""

# You should not need to edit below here, but please read to see what this does.
function fail {
  printf "ERROR: $@\n" >&2
  exit 1
}

function usage {
    printf "usage: %s hourly|daily|weekly|monthly 0x2A906f92B0378Bb19a3619E2751b1e0b8cab6B29\nWhere 0x2A..29 is your node deposit address to get your rated.network's raver score.\n" "$0" 2>&1
    exit 1
}

ACTION="$1"
DEPOSIT_ADDRESS="$2"

# Sanity checks
[[ "${BASH_VERSION%%.*}" -lt 4 ]] && fail "This script requires Bash version 4.0 or higher."
[ -z "$RATED_API_KEY" ] && fail "No rated.network API key set. Please edit this script and insert your key."
[ -z "$ACTION" ] && usage
[ -z "$DEPOSIT_ADDRESS" ] && usage
[[ ! $DEPOSIT_ADDRESS =~ ^0x[a-fA-F0-9]{40,} ]] && fail "Address should start with 0x and have at least 40 hex chars."

# Lower case the deposit address, upper case will return no answer, also this is more consistent.
DEPOSIT_ADDRESS=$(echo $DEPOSIT_ADDRESS | tr '[:upper:]' '[:lower:]')

# Get the raver scores from Rated Network API
AUTH_HEADER="Authorization: Bearer $RATED_API_KEY"
BASE_URL="https://api.rated.network/v1/eth/entities/${DEPOSIT_ADDRESS}/effectiveness?entityType=depositAddress"
TO_DATE=$(date +%Y-%m-%d)

# Function to query API and extract effectiveness data
function fetch_effectiveness {
  local from_date=$1
  local to_date=$2
  local granularity=$3
  local range_label=$4

  response=$(curl -f -sS -G \
    -H "$AUTH_HEADER" \
    --data-urlencode "fromDate=$from_date" \
    --data-urlencode "toDate=$to_date" \
    --data-urlencode "granularity=$granularity" \
    --data-urlencode "sortOrder=desc" \
    --data-urlencode "limit=1" \
    "$BASE_URL")

  if [[ $(echo "$response" | jq '.results | length') -eq 0 ]]; then
    printf "Error: No data received from rated.network API call to %s for %s - please check your API key and provided address.\n" "$BASE_URL" "$DEPOSIT_ADDRESS" >&2
    exit 1
  fi

  # Extract and format metrics
  avg_inclusion_delay=$(echo "$response" | jq -r '.results[0].avgInclusionDelay')
  avg_uptime=$(echo "$response" | jq -r '.results[0].avgUptime')
  avg_correctness=$(echo "$response" | jq -r '.results[0].avgCorrectness')
  avg_validator_effectiveness=$(echo "$response" | jq -r '.results[0].avgValidatorEffectiveness')
  avg_attester_effectiveness=$(echo "$response" | jq -r '.results[0].avgAttesterEffectiveness')
  startslot=$(echo "$response" | jq -r '.results[0].endSlot')
  endslot=$(echo "$response" | jq -r '.results[0].startSlot')

  # Swap start/end, they sometimes come in the wrong order.
  if [ "$startslot" -gt "$endslot" ]; then
    temp=$startslot
    startslot=$endslot
    endslot=$temp
  fi

  # Output in Prometheus format with label descriptions
  printf "# TYPE rated_avg_inclusion_delay gauge\n"
  printf "# HELP rated_avg_inclusion_delay Average inclusion delay for validators\n"
  printf "rated_avg_inclusion_delay{deposit_address=\"%s\",range=\"%s\"} %.5f\n" "$DEPOSIT_ADDRESS" "$range_label" "$avg_inclusion_delay"

  printf "# TYPE rated_avg_uptime gauge\n"
  printf "# HELP rated_avg_uptime Average validator uptime\n"
  printf "rated_avg_uptime{deposit_address=\"%s\",range=\"%s\"} %.5f\n" "$DEPOSIT_ADDRESS" "$range_label" "$avg_uptime"

  printf "# TYPE rated_avg_correctness gauge\n"
  printf "# HELP rated_avg_correctness Average correctness in attestations\n"
  printf "rated_avg_correctness{deposit_address=\"%s\",range=\"%s\"} %.5f\n" "$DEPOSIT_ADDRESS" "$range_label" "$avg_correctness"

  printf "# TYPE rated_avg_validator_effectiveness gauge\n"
  printf "# HELP rated_avg_validator_effectiveness Average validator effectiveness\n"
  printf "rated_avg_validator_effectiveness{deposit_address=\"%s\",range=\"%s\"} %.5f\n" "$DEPOSIT_ADDRESS" "$range_label" "$avg_validator_effectiveness"

  printf "# TYPE rated_avg_attester_effectiveness gauge\n"
  printf "# HELP rated_avg_attester_effectiveness Average attester effectiveness\n"
  printf "rated_avg_attester_effectiveness{deposit_address=\"%s\",range=\"%s\"} %.5f\n" "$DEPOSIT_ADDRESS" "$range_label" "$avg_attester_effectiveness"

  printf "# TYPE rated_startslot gauge\n"
  printf "# HELP rated_startslot Start slot of the time period\n"
  printf "rated_startslot{deposit_address=\"%s\",range=\"%s\"} %d\n" "$DEPOSIT_ADDRESS" "$range_label" "$startslot"

  printf "# TYPE rated_endslot gauge\n"
  printf "# HELP rated_endslot End slot of the time period\n"
  printf "rated_endslot{deposit_address=\"%s\",range=\"%s\"} %d\n" "$DEPOSIT_ADDRESS" "$range_label" "$endslot"
}

case "$ACTION" in
  'hourly')
    FROM_DATE=$(date -d "1 day ago" +%Y-%m-%d)
    fetch_effectiveness "$FROM_DATE" "$TO_DATE" "hour" "1h"
  ;;
  'daily')
    FROM_DATE=$(date -d "2 days ago" +%Y-%m-%d)
    fetch_effectiveness "$FROM_DATE" "$TO_DATE" "day" "1d"
  ;;
  'weekly')
    FROM_DATE=$(date -d "8 days ago" +%Y-%m-%d)
    fetch_effectiveness "$FROM_DATE" "$TO_DATE" "week" "7d"
  ;;
  'monthly')
    FROM_DATE=$(date -d "31 days ago" +%Y-%m-%d)
    fetch_effectiveness "$FROM_DATE" "$TO_DATE" "month" "30d"
  ;;
  *)
    usage
  ;;
esac
