#!/usr/bin/env bash
# Installs the privileged helper. The plugin itself is installed by
# `omarchy plugin add`, which cannot place a root-owned file.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
sudo install -m 0755 -o root -g root "$here/bin/omarchy-charge-hold" /usr/local/bin/omarchy-charge-hold
echo "installed /usr/local/bin/omarchy-charge-hold"
/usr/local/bin/omarchy-charge-hold status
