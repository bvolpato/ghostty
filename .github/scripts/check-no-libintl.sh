#!/usr/bin/env bash
# Fail when any Mach-O file or static archive under the given paths carries
# GNU libintl (LGPL-2.1-or-later) object code. cmux ships -Di18n=false
# GhosttyKit and the ghostty CLI helper; neither may contain libintl.
# Usage: check-no-libintl.sh <path>...
set -euo pipefail
[[ $# -gt 0 ]] || { echo "usage: $0 <path>..." >&2; exit 2; }
checked=0
found=0
while IFS= read -r -d '' f; do
  kind="$(file -b "$f")"
  case "$kind" in
    *Mach-O*|*"ar archive"*|*"current ar archive"*) ;;
    *) continue ;;
  esac
  checked=$((checked + 1))
  hits="$(nm -A -arch all "$f" 2>/dev/null \
    | grep -E ' [TDSBC] _?_libintl_|[:(](dcigettext|loadmsgcat|bindtextdom)\.o[):]' || true)"
  if [[ -n "$hits" ]]; then
    found=1
    echo "::error file=$f::libintl object code found"
    printf '%s\n' "$hits" | head -10
  fi
done < <(find "$@" -type f -print0)
echo "checked $checked Mach-O/archive files"
[[ $checked -gt 0 ]] || { echo "error: no Mach-O or archive files found under: $*" >&2; exit 1; }
exit "$found"
