#!/usr/bin/env bash
# Aktualizuje registry.json ze všech plugin.json v adresáři plugins/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLUGINS_DIR="${REPO_ROOT}/plugins"
REGISTRY_FILE="${REPO_ROOT}/registry.json"
SCHEMA_REF="./schema/registry.schema.json"

check_dependencies() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Chybí požadovaný nástroj: jq" >&2
    exit 1
  fi
}

build_registry() {
  local updated
  updated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  local plugins_json="[]"

  if [[ -d "$PLUGINS_DIR" ]]; then
    for plugin_dir in "$PLUGINS_DIR"/*/; do
      [[ -d "$plugin_dir" ]] || continue

      local plugin_json="${plugin_dir}plugin.json"
      if [[ ! -f "$plugin_json" ]]; then
        continue
      fi

      local relative_path="plugins/$(basename "${plugin_dir%/}")"
      local id version name description author tags types min_claude

      id="$(jq -r '.id' "$plugin_json")"
      version="$(jq -r '.version' "$plugin_json")"
      name="$(jq -r '.name' "$plugin_json")"
      description="$(jq -r '.description' "$plugin_json")"
      author="$(jq -r '.author' "$plugin_json")"
      tags="$(jq -c '.tags // []' "$plugin_json")"
      types="$(jq -c '.types' "$plugin_json")"
      min_claude="$(jq -c '.minClaudeVersion // null' "$plugin_json")"

      local dist_file="${relative_path}/dist/${id}-${version}.plugin"
      local readme="${relative_path}/README.md"
      local changelog="${relative_path}/CHANGELOG.md"

      local entry
      entry="$(jq -n \
        --arg id "$id" \
        --arg name "$name" \
        --arg version "$version" \
        --arg description "$description" \
        --arg author "$author" \
        --argjson tags "$tags" \
        --argjson types "$types" \
        --argjson minClaudeVersion "$min_claude" \
        --arg path "$relative_path" \
        --arg distFile "$dist_file" \
        --arg readme "$readme" \
        --arg changelog "$changelog" \
        '{
          id: $id,
          name: $name,
          version: $version,
          description: $description,
          author: $author,
          tags: $tags,
          types: $types,
          minClaudeVersion: $minClaudeVersion,
          path: $path,
          distFile: $distFile,
          readme: $readme,
          changelog: $changelog
        }')"

      plugins_json="$(jq --argjson entry "$entry" '. + [$entry]' <<<"$plugins_json")"
    done
  fi

  # Seřazení podle id pro deterministický výstup
  plugins_json="$(jq 'sort_by(.id)' <<<"$plugins_json")"

  jq -n \
    --arg schema "$SCHEMA_REF" \
    --arg updated "$updated" \
    --argjson plugins "$plugins_json" \
    '{
      "$schema": $schema,
      version: "1",
      updated: $updated,
      plugins: $plugins
    }' > "$REGISTRY_FILE"

  echo "Registry aktualizován: ${REGISTRY_FILE} (${updated})"
}

check_dependencies
build_registry
