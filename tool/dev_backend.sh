#!/bin/bash
# Local PocketBase running the same schema and hooks as the VPS, so the app can
# be developed against a real backend at 127.0.0.1:8090.
#
#   ./tool/dev_backend.sh start   # boot (creates the dev superuser on first run)
#   ./tool/dev_backend.sh stop
#   ./tool/dev_backend.sh reset   # wipe the local db and re-apply every migration
#   ./tool/dev_backend.sh token   # print a fresh superuser token
#
# The dev password is generated locally, stored 0600 outside git, and is never
# used for anything but this machine.
set -euo pipefail
cd "$(dirname "$0")/.."

PB=backend/.bin/pocketbase
DIR=backend/.local/pb_data
EMAIL=dev@clinic.local
PASSFILE=backend/.local/dev-superuser-pass
COMMON=(--dir="$DIR" --migrationsDir=backend/pb_migrations --hooksDir=backend/pb_hooks)
ADB_URL=http://127.0.0.1:8090

if [[ ! -x $PB ]]; then
  echo "PocketBase binary missing at $PB — see README (backend) for the pinned download." >&2
  exit 1
fi

password() {
  umask 077
  mkdir -p backend/.local
  [[ -f $PASSFILE ]] || openssl rand -hex 16 > "$PASSFILE"
  cat "$PASSFILE"
}

token() {
  curl --noproxy '*' -s -X POST "$ADB_URL/api/collections/_superusers/auth-with-password" \
    -H 'Content-Type: application/json' \
    -d "{\"identity\":\"$EMAIL\",\"password\":\"$(password)\"}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin).get("token",""))'
}

case "${1:-start}" in
  start)
    mkdir -p backend/.local
    nohup "$PB" "${COMMON[@]}" serve --http=127.0.0.1:8090 > /tmp/bsp-pb.log 2>&1 &
    sleep 3
    curl --noproxy '*' -s "$ADB_URL/api/health" >/dev/null
    echo "PocketBase on $ADB_URL (dashboard $ADB_URL/_/, log /tmp/bsp-pb.log)"
    ;;
  stop)
    pkill -f "pocketbase --dir=$DIR" 2>/dev/null || true
    echo "stopped"
    ;;
  reset)
    "$0" stop
    rm -rf "$DIR"
    "$PB" "${COMMON[@]}" migrate up
    "$PB" --dir="$DIR" superuser upsert "$EMAIL" "$(password)"
    "$0" start
    ;;
  token)
    token
    ;;
  *)
    echo "usage: $0 {start|stop|reset|token}" >&2
    exit 2
    ;;
esac
