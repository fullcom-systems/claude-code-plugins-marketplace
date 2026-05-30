#!/usr/bin/env bash
# Validuje strukturu a metadata pluginu proti JSON schématu.
set -euo pipefail

usage() {
  echo "Použití: $0 <cesta-k-pluginu>" >&2
  echo "Příklad: $0 plugins/example-hello-world" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCHEMA_FILE="${REPO_ROOT}/schema/plugin.schema.json"

check_dependencies() {
  local missing=()
  for cmd in jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if command -v check-jsonschema >/dev/null 2>&1; then
    VALIDATOR="check-jsonschema"
  elif command -v ajv >/dev/null 2>&1; then
    VALIDATOR="ajv"
  else
    missing+=("check-jsonschema nebo ajv-cli")
  fi

  if ((${#missing[@]} > 0)); then
    echo "Chybí požadované nástroje: ${missing[*]}" >&2
    exit 1
  fi
}

validate_json_schema() {
  local data_file="$1"
  local schema_file="$2"

  if [[ "$VALIDATOR" == "check-jsonschema" ]]; then
    check-jsonschema --schemafile "$schema_file" "$data_file"
  else
    ajv validate -s "$schema_file" -d "$data_file" --strict=false
  fi
}

if [[ $# -ne 1 ]]; then
  usage
fi

PLUGIN_DIR="${1%/}"
PLUGIN_JSON="${PLUGIN_DIR}/plugin.json"

check_dependencies

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Adresář pluginu neexistuje: ${PLUGIN_DIR}" >&2
  exit 1
fi

# Kontrola povinných souborů
for required_file in plugin.json README.md CHANGELOG.md; do
  if [[ ! -f "${PLUGIN_DIR}/${required_file}" ]]; then
    echo "Chybí povinný soubor: ${PLUGIN_DIR}/${required_file}" >&2
    exit 1
  fi
done

echo "Validuji plugin.json proti schématu..."
validate_json_schema "$PLUGIN_JSON" "$SCHEMA_FILE"

# Kontrola existence skill souborů
SKILL_COUNT="$(jq '.skills // [] | length' "$PLUGIN_JSON")"
if [[ "$SKILL_COUNT" -gt 0 ]]; then
  echo "Kontroluji cesty ke skills..."
  while IFS= read -r skill_path; do
    skill_path="${skill_path//$'\r'/}"
    if [[ ! -f "${PLUGIN_DIR}/${skill_path}" ]]; then
      echo "Skill soubor neexistuje: ${PLUGIN_DIR}/${skill_path}" >&2
      exit 1
    fi

    # Kontrola YAML frontmatter v SKILL.md
    if ! head -n 1 "${PLUGIN_DIR}/${skill_path}" | grep -q '^---$'; then
      echo "SKILL.md musí obsahovat YAML frontmatter: ${PLUGIN_DIR}/${skill_path}" >&2
      exit 1
    fi
  done < <(jq -r '.skills[].path' "$PLUGIN_JSON")
fi

echo "Plugin ${PLUGIN_DIR} prošel validací."
