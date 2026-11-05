#!/usr/bin/env bash
#
# Run one tier of the update logic that lives in update.sh, without
# modifying update.sh itself.
#
# update.sh is split in two parts:
#   - variable definitions and functions (safe to source)
#   - the actual update actions at the bottom (must NOT run here)
#
# We therefore extract the first part, source it, and call only the
# functions we need. If upstream ever restructures the file, the guards
# below make this fail loudly instead of silently running a full update.
#
# Tiers:
#   daily  : CSSI space weather, JB2008 indices  (sources updated every day)
#   weekly : IERS earth orientation parameters, MSAFE
#   all    : everything above + tai-utc.dat
#
# tai-utc.dat is only fetched in the "all" tier on purpose. The CGPM decided
# in October 2026 that UTC stops using leap seconds on 2027-05-20, and the
# last possible leap second (end of 2026) had already been announced as
# "none". The file is therefore frozen at TAI-UTC = 37 s.
#
# A failing source only prints "FAILED <label>": the job stays green so the
# other sources still get committed. The workflow turns those lines into a
# warning and a job summary.

set -o pipefail

tier=${1:-all}
case $tier in daily|weekly|all) ;; *) echo "unknown tier: $tier" >&2; exit 2 ;; esac

[ -f update.sh ] || { echo "update.sh not found (run from repo root)" >&2; exit 3; }

defs=$(mktemp)
trap 'rm -f "$defs"' EXIT
awk '/^# update \(/{exit} {print}' update.sh > "$defs"

for fn in fetch_URL fetch_MSAFE month_name next_date previous_date \
          MSAFE_attempt_urls MSAFE_attempt_names first_missing_MSAFE; do
    if ! grep -q "^${fn}()" "$defs"; then
        echo "FAILED extraction: function $fn not found in update.sh" >&2
        exit 3
    fi
done
if grep -q '^fetch_URL \$usno_ser7_url' "$defs"; then
    echo "FAILED extraction: update actions leaked into the sourced part" >&2
    exit 3
fi

# shellcheck disable=SC1090
source "$defs"

# try_fetch <label> <url> <repo-relative-path>
try_fetch() {
    local label=$1 url=$2 path=$3
    if ( cd "$(dirname "$path")" && fetch_URL "$url" "$(basename "$path")" ); then
        echo "OK $label"
    else
        echo "FAILED $label"
    fi
}

# Fetch every MSAFE month that is still missing, stopping at the first one
# that is not published yet. Not being published is the normal case most of
# the time, so it is reported as SKIP rather than FAILED.
run_msafe() {
    local y m
    while :; do
        read -r y m <<< "$(cd MSAFE && first_missing_MSAFE)"
        [ -n "${y:-}" ] || break
        if ( cd MSAFE && fetch_MSAFE "$y" "$m" ); then
            echo "OK MSAFE $y-$m"
        else
            echo "SKIP MSAFE $y-$m (not published yet)"
            break
        fi
    done
}

do_daily() {
    echo "--- daily: space weather ---"
    try_fetch "CSSI space weather" "$cssi_url" "CSSI-Space-Weather-Data/SpaceWeather-All-v1.2.txt"
    try_fetch "JB2008 SOLFSMY"     "$spacenvironment_url" "Space-Environment-Data/SOLFSMY.TXT"
    try_fetch "JB2008 DTCFILE"     "$spacenvironment_url" "Space-Environment-Data/DTCFILE.TXT"
}

do_weekly() {
    echo "--- weekly: earth orientation + MSAFE ---"
    try_fetch "IERS finals2000A" "$iers_rapid_url/9" "Earth-Orientation-Parameters/IAU-2000/finals2000A.all"
    try_fetch "IERS finals"      "$iers_rapid_url/7" "Earth-Orientation-Parameters/IAU-1980/finals.all"
    run_msafe
}

do_leapseconds() {
    echo "--- leap seconds (static since 2017) ---"
    try_fetch "USNO tai-utc" "$usno_ser7_url" "tai-utc.dat"
}

case $tier in
    daily)  do_daily ;;
    weekly) do_weekly ;;
    all)    do_leapseconds; do_weekly; do_daily ;;
esac
