#!/usr/bin/env bash
# Sestaví .plugin soubor (ZIP archiv) z adresáře pluginu.
set -euo pipefail

usage() {
  echo "Použití: $0 <cesta-k-pluginu>" >&2
  echo "Příklad: $0 plugins/example-hello-world" >&2
  exit 1
}

check_dependencies() {
  local missing=()
  for cmd in jq zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if ((${#missing[@]} > 0)); then
    echo "Chybí požadované nástroje: ${missing[*]}" >&2
    exit 1
  fi
}

if [[ $# -ne 1 ]]; then
  usage
fi

PLUGIN_DIR="${1%/}"
PLUGIN_JSON="${PLUGIN_DIR}/plugin.json"
DIST_DIR="${PLUGIN_DIR}/dist"

check_dependencies

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Adresář pluginu neexistuje: ${PLUGIN_DIR}" >&2
  exit 1
fi

if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "Chybí soubor plugin.json: ${PLUGIN_JSON}" >&2
  exit 1
fi

PLUGIN_ID="$(jq -r '.id' "$PLUGIN_JSON")"
PLUGIN_VERSION="$(jq -r '.version' "$PLUGIN_JSON")"

if [[ -z "$PLUGIN_ID" || "$PLUGIN_ID" == "null" ]]; then
  echo "plugin.json neobsahuje platné pole 'id'" >&2
  exit 1
fi

if [[ -z "$PLUGIN_VERSION" || "$PLUGIN_VERSION" == "null" ]]; then
  echo "plugin.json neobsahuje platné pole 'version'" >&2
  exit 1
fi

OUTPUT_FILE="${DIST_DIR}/${PLUGIN_ID}-${PLUGIN_VERSION}.plugin"

mkdir -p "$DIST_DIR"

# ZIP ze všech souborů pluginu kromě dist/
(
  cd "$PLUGIN_DIR"
  zip -r -q "$OLDPWD/$OUTPUT_FILE" . -x "dist/*" -x "dist"
)

FILE_SIZE="$(wc -c < "$OUTPUT_FILE" | tr -d ' ')"
echo "Plugin sestaven: ${OUTPUT_FILE} (${FILE_SIZE} bajtů)"
