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

# Kontrola shody id v plugin.json s názvem adresáře
PLUGIN_ID_JSON="$(jq -r '.id' "$PLUGIN_JSON")"
PLUGIN_DIR_NAME="$(basename "$PLUGIN_DIR")"
if [[ "$PLUGIN_ID_JSON" != "$PLUGIN_DIR_NAME" ]]; then
  echo "ID v plugin.json ('${PLUGIN_ID_JSON}') neodpovídá názvu adresáře ('${PLUGIN_DIR_NAME}')" >&2
  exit 1
fi

# Kontrola existence skill souborů
SKILL_COUNT="$(jq '.skills // [] | length' "$PLUGIN_JSON")"
if [[ "$SKILL_COUNT" -gt 0 ]]; then
  echo "Kontroluji cesty ke skills..."
  while IFS= read -r skill_path; do
    skill_path="${skill_path//$'\r'/}"
    skill_file="${PLUGIN_DIR}/${skill_path}"
    if [[ ! -f "$skill_file" ]]; then
      echo "Skill soubor neexistuje: ${skill_file}" >&2
      exit 1
    fi

    # Kontrola YAML frontmatter v SKILL.md (tolerantní k CRLF)
    if ! head -n 1 "$skill_file" | tr -d '\r' | grep -q '^---$'; then
      echo "SKILL.md musí začínat YAML frontmatterem (---): ${skill_file}" >&2
      exit 1
    fi

    # Frontmatter musí obsahovat povinná pole name a description
    frontmatter="$(awk 'NR==1 && /^---[[:space:]]*$/{f=1; next} f && /^---[[:space:]]*$/{exit} f' "$skill_file" | tr -d '\r')"
    for field in name description; do
      if ! grep -qE "^${field}:" <<<"$frontmatter"; then
        echo "SKILL.md frontmatter postrádá povinné pole '${field}': ${skill_file}" >&2
        exit 1
      fi
    done
  done < <(jq -r '.skills[].path' "$PLUGIN_JSON")
fi

# Kontrola existence a validity MCP konfigurací
MCP_COUNT="$(jq '.mcpServers // [] | length' "$PLUGIN_JSON")"
if [[ "$MCP_COUNT" -gt 0 ]]; then
  echo "Kontroluji MCP servery..."
  while IFS= read -r config_path; do
    config_path="${config_path//$'\r'/}"
    [[ -z "$config_path" || "$config_path" == "null" ]] && continue
    config_file="${PLUGIN_DIR}/${config_path}"
    if [[ ! -f "$config_file" ]]; then
      echo "MCP konfigurační soubor neexistuje: ${config_file}" >&2
      exit 1
    fi
    if ! jq empty "$config_file" >/dev/null 2>&1; then
      echo "MCP konfigurační soubor není validní JSON: ${config_file}" >&2
      exit 1
    fi
  done < <(jq -r '.mcpServers[] | .config // ""' "$PLUGIN_JSON")
fi

# Kontrola konzistence pole types s obsahem pluginu
TYPES="$(jq -r '.types[]' "$PLUGIN_JSON")"
has_type() { grep -qx "$1" <<<"$TYPES"; }

if [[ "$SKILL_COUNT" -gt 0 ]] && ! has_type skill && ! has_type mixed; then
  echo "Plugin obsahuje skills, ale 'types' neobsahuje 'skill' ani 'mixed'." >&2
  exit 1
fi
if [[ "$MCP_COUNT" -gt 0 ]] && ! has_type mcp && ! has_type mixed; then
  echo "Plugin obsahuje MCP servery, ale 'types' neobsahuje 'mcp' ani 'mixed'." >&2
  exit 1
fi

echo "Plugin ${PLUGIN_DIR} prošel validací."
