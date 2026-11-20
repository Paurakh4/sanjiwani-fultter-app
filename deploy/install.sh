#!/bin/bash
# Installs the clinic backend on the VPS from what has been staged to
# /home/px/bsp-staging. Run it as root, in your own terminal, so the admin
# password you type is never passed to any tool but this script:
#
#   sudo bash /home/px/bsp-staging/deploy/install.sh
#
# Safe to re-run: it updates code and units without touching pb_data.
set -euo pipefail

PB_VERSION=0.40.6
SHA256=0e1f609158ed945f809f8a02ae012aa0427129c66ebb63c1aee76f2c0309373f
DOMAIN=app.api.sanjiwani.com.np
STAGE=/home/px/bsp-staging
BASE=/opt/bsp
LOCAL=http://127.0.0.1:8090

if [[ $EUID -ne 0 ]]; then
  echo "run with sudo — this writes /opt, systemd units and an nginx site" >&2
  exit 1
fi
[[ -d $STAGE ]] || { echo "staging dir $STAGE is missing" >&2; exit 1; }

echo "==> service account"
id -u bsp >/dev/null 2>&1 ||
  useradd --system --home-dir "$BASE" --shell /usr/sbin/nologin --create-home bsp
# The data directory has to exist before the unit starts: ReadWritePaths under
# ProtectSystem=strict cannot create it, and systemd fails with 226/NAMESPACE.
mkdir -p "$BASE/pocketbase/pb_data/backups" "$BASE/push-sender"
chown -R bsp:bsp "$BASE"

echo "==> PocketBase $PB_VERSION (checksum verified)"
if [[ ! -f $BASE/pocketbase/pocketbase ]]; then
  echo "$SHA256  $STAGE/pocketbase_${PB_VERSION}_linux_amd64.zip" | sha256sum -c -
  tmp=$(mktemp -d)
  unzip -q "$STAGE/pocketbase_${PB_VERSION}_linux_amd64.zip" -d "$tmp"
  install -m 750 -o bsp -g bsp "$tmp/pocketbase" "$BASE/pocketbase/pocketbase"
  rm -rf "$tmp"
fi

echo "==> schema, hooks and sender code"
rsync -a --delete "$STAGE/backend/pb_migrations/" "$BASE/pocketbase/pb_migrations/"
rsync -a --delete "$STAGE/backend/pb_hooks/" "$BASE/pocketbase/pb_hooks/"
# The sender's node_modules is installed in staging as px, because sudo looks
# commands up in its own secure_path and would not find linuxbrew's npm. The env
# file and the Google key are never overwritten by a re-deploy.
rsync -a --delete --exclude env --exclude sa.json \
  "$STAGE/backend/push-sender/" "$BASE/push-sender/"
chown -R bsp:bsp "$BASE"

echo "==> node for the sender"
NODE_BIN=""
for candidate in /home/linuxbrew/.linuxbrew/bin/node /usr/local/bin/node /usr/bin/node; do
  [[ -x $candidate ]] && { NODE_BIN=$candidate; break; }
done
if [[ -z $NODE_BIN ]]; then
  echo "no node found; the sender unit will not be installed (PocketBase is unaffected)" >&2
elif [[ ! -d $BASE/push-sender/node_modules/firebase-admin ]]; then
  echo "the sender's node_modules is missing — run this first, as px, without sudo:" >&2
  echo "  cd /home/px/bsp-staging/backend/push-sender && PATH=/home/linuxbrew/.linuxbrew/bin:\$PATH npm install --omit=dev" >&2
  echo "then re-run this script." >&2
  exit 1
fi

echo "==> systemd units"
install -m 644 "$STAGE/deploy/pocketbase.service" /etc/systemd/system/bsp-pocketbase.service
if [[ -n $NODE_BIN ]]; then
  sed "s|/usr/bin/env node|$NODE_BIN|" "$STAGE/deploy/bsp-push-sender.service" \
    > /etc/systemd/system/bsp-push-sender.service
fi
systemctl daemon-reload
# restart, not --now: a previous failed run may have left the unit enabled and
# crash-looping, and --now would not re-read the fixed data directory.
systemctl enable bsp-pocketbase
systemctl restart bsp-pocketbase

echo "==> waiting for the API"
for _ in $(seq 1 20); do
  curl -sf "$LOCAL/api/health" >/dev/null && break
  sleep 1
done
curl -sf "$LOCAL/api/health" >/dev/null || {
  echo "PocketBase did not answer on $LOCAL — check: journalctl -u bsp-pocketbase -n 50" >&2
  exit 1
}

echo "==> admin account"
read -r -p "admin email [admin@sanjiwani.com.np]: " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@sanjiwani.com.np}
read -r -s -p "admin password (stored hashed in pb_data): " ADMIN_PASS
echo
# The password is a process argument for the moment this command runs, so it is
# read interactively rather than appearing in any log or shell history.
sudo -u bsp "$BASE/pocketbase/pocketbase" --dir="$BASE/pocketbase/pb_data" \
  superuser upsert "$ADMIN_EMAIL" "$ADMIN_PASS"

echo "==> nightly backups (23:45 Nepal time, 7 kept)"
TOKEN=$(curl -sf -X POST "$LOCAL/api/collections/_superusers/auth-with-password" \
  -H 'Content-Type: application/json' \
  -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')
curl -sf -X PATCH "$LOCAL/api/settings" \
  -H "Authorization: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"backups":{"cron":"0 18 * * *","cronMaxKeep":7}}' >/dev/null

echo "==> nginx site"
install -m 644 "$STAGE/deploy/nginx-$DOMAIN.conf" /etc/nginx/sites-available/bsp-app-api.conf
ln -sf /etc/nginx/sites-available/bsp-app-api.conf /etc/nginx/sites-enabled/bsp-app-api.conf
nginx -t
systemctl reload nginx

echo "==> certificate"
if certbot certificates 2>/dev/null | grep -q "Name: $DOMAIN"; then
  # Issued on an earlier run but never installed, because the nginx site did not
  # exist yet. Now it does, so reuse it instead of asking for another.
  echo "using the existing certificate for $DOMAIN"
  certbot install --cert-name "$DOMAIN" --nginx
elif ! certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL" --redirect; then
  echo
  echo "certificate failed. This is almost always DNS not having propagated yet." >&2
  echo "Check with:  getent hosts $DOMAIN   (it must return 85.121.122.88)" >&2
  echo "Then re-run: sudo certbot --nginx -d $DOMAIN --redirect" >&2
  exit 1
fi

echo
echo "Done. Admin dashboard: https://$DOMAIN/_/"
echo
echo "Still to do, in this order:"
echo "  1. Settings > Mail — put in the clinic mailbox SMTP, then send a test email."
echo "     Password reset and admin MFA both need this."
echo "  2. Confirm the doctor roster is correct before telling anyone the app is live."
echo "     (Departments and doctors were seeded from the app; notices were not, because"
echo "      the three in the app are dated and out of date.)"
echo "  3. Publish one notice from the dashboard so the app has something to show."
echo "  4. Push delivery, once you have the Firebase project:"
echo "       sudo -u bsp sh -c 'umask 077; cp /path/to/keyfile /opt/bsp/push-sender/sa.json'"
echo "       sudoedit /opt/bsp/push-sender/env   # from $STAGE/backend/push-sender/env.example"
echo "       sudo chown bsp:bsp /opt/bsp/push-sender/env && sudo chmod 600 /opt/bsp/push-sender/env"
echo "       sudo systemctl enable --now bsp-push-sender"
echo "  5. Settings > Security > Rate limiting — start with 10/min per IP on /auth."
