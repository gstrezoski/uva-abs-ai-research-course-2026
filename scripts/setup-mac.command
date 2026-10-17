#!/bin/bash
# Double-click this file to run setup-mac.sh in Terminal.
# Keep it in the same folder as setup-mac.sh.
cd "$(dirname "$0")" || exit 1
bash ./setup-mac.sh
status=$?
echo
if [ "$status" -ne 0 ]; then
    echo "Setup stopped with an error. Read the messages above."
else
    echo "Setup is done."
fi
echo
read -n 1 -s -r -p "Press any key to close this window."
echo
exit "$status"
