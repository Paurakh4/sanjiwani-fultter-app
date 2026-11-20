#!/bin/bash
# Flip the running emulator between the two phone widths that cover the Android
# market, so a layout check here stands in for testing on many handsets.
#   ref    432x960dp  (1080x2400 @400dpi) - large mainstream phones, matches the Redmi test device
#   small  360x800dp  (720x1560  @320dpi) - narrowest phones still in use; the overflow risk lives here
#   status print what the emulator is showing now
set -euo pipefail
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
SERIAL="${ANDROID_SERIAL:-emulator-5554}"

case "${1:-status}" in
  ref)   $ADB -s "$SERIAL" shell wm size 1080x2400; $ADB -s "$SERIAL" shell wm density 400 ;;
  small) $ADB -s "$SERIAL" shell wm size 720x1560;  $ADB -s "$SERIAL" shell wm density 320 ;;
  status) ;;
  *) echo "usage: $0 {ref|small|status}" >&2; exit 2 ;;
esac
effective() {
  $ADB -s "$SERIAL" shell "$1" | tr -d '\r' \
    | awk -F': ' '/Override/{o=$2} /Physical/{p=$2} END{print (o ? o : p)}'
}
echo "size:    $(effective 'wm size')"
echo "density: $(effective 'wm density')"
