#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [--check]" >&2
  exit 2
fi

case "${1:---inplace}" in
  --inplace|--check) mode="${1:---inplace}" ;;
  *) echo "Usage: $0 [--check]" >&2; exit 2 ;;
esac

cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
git ls-files -z --cached --others --exclude-standard -- \
  '*.typ' ':!:old_template/**' ':!:tmp/**' ':!:target/**' \
  | while IFS= read -r -d '' file; do
      if [[ -f "$file" ]]; then
        printf '%s\0' "$file"
      fi
    done \
  | xargs -0 -r typstyle "$mode"
