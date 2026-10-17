#!/bin/bash
# Telegram-Alert-Skript - wiederverwendbar
#
# Rate-Limit / Deduplizierung (ab 2026-10-17):
#   - Gleicher Alert (gleiche SEVERITY + TITLE) wird innerhalb COOLDOWN_SEC
#     nur einmal gesendet. Verhindert Falsch-Alarm-Spam bei transienten Checks.
#   - SEVERITY=CRITICAL umgeht den Cooldown (echte Notfaelle muessen durch).
#   - State-Eintrag wird NUR nach erfolgreichem curl geschrieben, damit
#     fehlgeschlagene Versuche nicht den Retry blocken.
#   - State-File: $TELEGRAM_ALERT_COOLDOWN_DB
#     (Default: $HOME/hermes/logs/.telegram_alert_cooldown)
#
SEVERITY="$1"
TITLE="$2"
BODY="$3"

if [ -z "$TITLE" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 SEVERITY TITLE BODY"
    exit 1
fi

COOLDOWN_SEC="${TELEGRAM_ALERT_COOLDOWN_SEC:-21600}"   # Default 6h
COOLDOWN_DB="${TELEGRAM_ALERT_COOLDOWN_DB:-$HOME/hermes/logs/.telegram_alert_cooldown}"

# CRITICAL-Alerts immer sofort senden (Notfall).
# Alles andere: Deduplizierung pruefen.
if [ "$SEVERITY" != "CRITICAL" ]; then
    ALERT_KEY="${SEVERITY}|${TITLE}"
    ALERT_HASH=$(printf '%s' "$ALERT_KEY" | md5sum | cut -d' ' -f1)
    NOW=$(date +%s)

    # State-File-Verzeichnis vorbereiten. Bei Fehlschlag: mktemp-Fallback
    # (sicher gegen symlink-attack, weil mktemp atomar und O_EXCL nutzt).
    if ! mkdir -p "$(dirname "$COOLDOWN_DB")" 2>/dev/null \
        || ! { : >> "$COOLDOWN_DB"; } 2>/dev/null; then
        COOLDOWN_DB=$(mktemp -t telegram_alert_cooldown.XXXXXX) || {
            echo "[$(date +'%Y-%m-%d %H:%M:%S %Z')] Alert FEHLGESCHLAGEN: ${TITLE} (kein State-File schreibbar)" >&2
            exit 1
        }
    fi

    # Lock-File an finale COOLDOWN_DB binden (nach moeglichem Fallback).
    LOCK_FILE="${COOLDOWN_DB}.lock"

    # Lock gegen parallele Aufrufe (verhindert Race im selben Sekundenfenster).
    USE_LOCK=0
    if command -v flock >/dev/null 2>&1; then
        exec 9>"$LOCK_FILE"
        if flock -w 2 9; then
            USE_LOCK=1
        fi
        # Lock nicht bekommen: sende Alert (lieber einmal zu viel als verpasst)
    fi

    # Dedup-Check: nur wenn COOLDOWN_SEC > 0. Bei 0: kein Dedupe.
    if [ "${COOLDOWN_SEC}" -gt 0 ]; then
        LAST_SENT=$(grep -F "$ALERT_HASH" "$COOLDOWN_DB" 2>/dev/null | tail -1 | cut -d'|' -f1)
        if [ -n "$LAST_SENT" ]; then
            AGE=$((NOW - LAST_SENT))
            # Schutz gegen Clock-Skew (negative AGE) + Cooldown aktiv
            if [ "$AGE" -ge 0 ] && [ "$AGE" -lt "$COOLDOWN_SEC" ]; then
                TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S %Z')
                echo "[${TIMESTAMP}] Alert DEDUPLIZIERT (${AGE}s < ${COOLDOWN_SEC}s): ${TITLE}"
                [ "$USE_LOCK" -eq 1 ] && flock -u 9
                exit 0
            fi
        fi
    fi
fi

TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S %Z')
TELEGRAM_BOT_TOKEN=$(sudo -S -p '' docker exec hermes-agent-ekgx-hermes-agent-1 bash -c 'grep ^TELEGRAM_BOT_TOKEN /opt/data/.env | cut -d= -f2' 2>/dev/null | tr -d "'"'\''\r')
CHAT_ID="858968389"

MESSAGE="${SEVERITY} *${TITLE}*

${BODY}

VPS Hermes-Monitor"

URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
curl -s -X POST "$URL" \
    -d chat_id="$CHAT_ID" \
    -d parse_mode="Markdown" \
    -d text="$MESSAGE" > /dev/null

CURL_RC=$?

# Lock freigeben bevor ggf. State geschrieben wird
[ "${USE_LOCK:-0}" -eq 1 ] && flock -u 9

# State-Eintrag NUR nach erfolgreichem Senden schreiben.
# Damit ueberlebt ein transienter Telegram-Outage und ein Retry
# innerhalb COOLDOWN_SEC kommt durch.
if [ "$CURL_RC" -eq 0 ] && [ "$SEVERITY" != "CRITICAL" ]; then
    NOW_AFTER=$(date +%s)
    # State bereinigen (nur letzte 24h behalten)
    if [ -f "$COOLDOWN_DB" ]; then
        CUTOFF=$((NOW_AFTER - 86400))
        awk -F'|' -v c="$CUTOFF" '$1 >= c' "$COOLDOWN_DB" > "${COOLDOWN_DB}.tmp" 2>/dev/null \
            && mv "${COOLDOWN_DB}.tmp" "$COOLDOWN_DB"
    fi
    # Anker mit '|' damit HASH-Substrings nicht false-matchen beim Lookup.
    echo "${NOW_AFTER}|${ALERT_HASH}|${SEVERITY}|${TITLE}" >> "$COOLDOWN_DB"
fi

if [ $CURL_RC -eq 0 ]; then
    echo "[${TIMESTAMP}] Alert gesendet: ${TITLE}"
else
    echo "[${TIMESTAMP}] Alert FEHLGESCHLAGEN: ${TITLE}" >&2
    exit 1
fi
