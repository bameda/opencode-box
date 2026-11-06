#!/usr/bin/env bash
# Symlink bin/roke into ~/.local/bin and create the configuration directory.
#
# Usage: ./install.sh [GIT_URL]
#   GIT_URL  your private configuration repository, cloned into
#            ~/.config/roke (or $ROKE_CONFIG_DIR) if it does not exist yet.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

mkdir -p "$HOME/.local/bin"
ln -sfn "$here/bin/roke" "$HOME/.local/bin/roke"
echo "Linked: ~/.local/bin/roke -> $here/bin/roke"

"$here/bin/roke" --init "$@"

if ! docker compose version >/dev/null 2>&1; then
  echo "WARNING: 'docker compose' not found. On CachyOS: sudo pacman -S docker docker-compose docker-buildx" >&2
fi

case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *)
  echo "WARNING: ~/.local/bin is not in your PATH (fish: fish_add_path ~/.local/bin)" >&2 ;;
esac
