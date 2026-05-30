#!/usr/bin/env bash
# Validuje nativní Claude Code marketplace (.claude-plugin/marketplace.json)
# a všechny pluginy, na které odkazuje.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MARKETPLACE="${REPO_ROOT}/.claude-plugin/marketplace.json"

err() { echo "CHYBA: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || err "Chybí požadovaný nástroj: jq"

[[ -f "$MARKETPLACE" ]] || err "Nenalezen soubor: ${MARKETPLACE}"
jq empty "$MARKETPLACE" 2>/dev/null || err "marketplace.json není validní JSON"

# Povinná top-level pole
jq -e '.name | type == "string" and (length > 0)' "$MARKETPLACE" >/dev/null \
  || err "marketplace.json: chybí povinné pole 'name'"
jq -e '.owner.name | type == "string" and (length > 0)' "$MARKETPLACE" >/dev/null \
  || err "marketplace.json: chybí povinné pole 'owner.name'"
jq -e '.plugins | type == "array"' "$MARKETPLACE" >/dev/null \
  || err "marketplace.json: 'plugins' musí být pole"

echo "Marketplace '$(jq -r .name "$MARKETPLACE")' — $(jq '.plugins | length' "$MARKETPLACE") plugin(ů)"

# Iterace přes pluginy
while IFS=$'\t' read -r p_name p_source; do
  echo "Validuji plugin '${p_name}' (${p_source})..."

  [[ "$p_name" =~ ^[a-z0-9-]+$ ]] || err "[$p_name] název pluginu musí odpovídat ^[a-z0-9-]+$"

  # Lokální source musí začínat ./
  case "$p_source" in
    ./*) ;;
    *) err "[$p_name] lokální 'source' musí začínat './': ${p_source}" ;;
  esac

  plugin_dir="${REPO_ROOT}/${p_source#./}"
  [[ -d "$plugin_dir" ]] || err "[$p_name] adresář pluginu neexistuje: ${plugin_dir}"

  manifest="${plugin_dir}/.claude-plugin/plugin.json"
  [[ -f "$manifest" ]] || err "[$p_name] chybí manifest: ${manifest}"
  jq empty "$manifest" 2>/dev/null || err "[$p_name] plugin.json není validní JSON"

  m_name="$(jq -r '.name // empty' "$manifest")"
  [[ -n "$m_name" ]] || err "[$p_name] plugin.json: chybí pole 'name'"
  [[ "$m_name" == "$p_name" ]] \
    || err "[$p_name] 'name' v plugin.json ('${m_name}') neodpovídá názvu v marketplace.json"
  [[ "$m_name" == "$(basename "$plugin_dir")" ]] \
    || err "[$p_name] 'name' ('${m_name}') neodpovídá názvu adresáře ('$(basename "$plugin_dir")')"

  # Skills (pokud existují) — kontrola frontmatteru
  if [[ -d "${plugin_dir}/skills" ]]; then
    while IFS= read -r -d '' skill_md; do
      head -n 1 "$skill_md" | tr -d '\r' | grep -q '^---$' \
        || err "SKILL.md musí začínat YAML frontmatterem (---): ${skill_md}"
      frontmatter="$(awk 'NR==1 && /^---[[:space:]]*$/{f=1; next} f && /^---[[:space:]]*$/{exit} f' "$skill_md" | tr -d '\r')"
      for field in name description; do
        grep -qE "^${field}:" <<<"$frontmatter" \
          || err "SKILL.md frontmatter postrádá povinné pole '${field}': ${skill_md}"
      done
    done < <(find "${plugin_dir}/skills" -name SKILL.md -print0)
  fi

  # MCP konfigurace (pokud plugin.json odkazuje na soubor řetězcovou cestou)
  mcp_ref="$(jq -r 'if (.mcpServers | type) == "string" then .mcpServers else empty end' "$manifest")"
  if [[ -n "$mcp_ref" ]]; then
    mcp_file="${plugin_dir}/${mcp_ref#./}"
    [[ -f "$mcp_file" ]] || err "[$p_name] MCP konfigurace neexistuje: ${mcp_file}"
    jq empty "$mcp_file" 2>/dev/null || err "[$p_name] MCP konfigurace není validní JSON: ${mcp_file}"
  fi

  echo "  OK"
done < <(jq -r '.plugins[] | [.name, .source] | @tsv' "$MARKETPLACE")

echo "Marketplace prošel validací."
