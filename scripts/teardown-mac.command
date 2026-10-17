#!/bin/bash
# Double-click this file to run teardown-mac.sh in Terminal. It asks you to type
# YES before it deletes anything. Keep it in the same folder as teardown-mac.sh.
cd "$(dirname "$0")" || exit 1
bash ./teardown-mac.sh
status=$?
echo
read -n 1 -s -r -p "Press any key to close this window."
echo
exit "$status"
