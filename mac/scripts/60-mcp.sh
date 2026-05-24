#!/usr/bin/env bash
# MCP サーバーを Claude Code (`claude mcp add`) と VS Code (~/Library/Application
# Support/Code/User/mcp.json) の両方に投入する。
# 真実のソースは config/mcp/servers.json。
#
# 前提:
#   - 30-brewfile.sh を済ませている (jq / uv / Node = mise 経由)
#   - Claude Code CLI (`claude`) がインストール済み (Brewfile 外: 公式インストーラ)
#   - VS Code がインストール済み (Brewfile に含む)

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "MCP servers (Claude Code + VS Code)"

ROOT="$(setup_root)"
SERVERS_JSON="${ROOT}/config/mcp/servers.json"

[[ -f "$SERVERS_JSON" ]] || die "MCP 定義が見つかりません: $SERVERS_JSON"
have_cmd jq || die "jq が必要です。30-brewfile.sh を先に実行してください。"

# enabled な server 名一覧 (macOS の /bin/bash 3.2 互換: mapfile は使わない)
SERVERS=()
while IFS= read -r line; do
  SERVERS+=("$line")
done < <(jq -r '.servers | to_entries[] | select(.value.enabled == true) | .key' "$SERVERS_JSON")

if [[ ${#SERVERS[@]} -eq 0 ]]; then
  log_warning "enabled な MCP server がありません。終了。"
  exit 0
fi

# ---------------------------------------------
# 1. Claude Code: `claude mcp add` を user スコープで投入
# ---------------------------------------------
setup_claude_code() {
  if ! have_cmd claude; then
    log_warning "Claude Code CLI (claude) が PATH にありません。スキップします。"
    log_info "  -> https://claude.com/code からインストールしてください。"
    return 0
  fi

  log_info "Claude Code (user scope) に MCP server を追加します"

  for name in "${SERVERS[@]}"; do
    # 既存登録があれば一旦削除 (冪等性のため)
    if claude mcp get "$name" >/dev/null 2>&1; then
      log_info "  - replace existing: $name"
      run claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
    fi

    local transport
    transport="$(jq -r --arg n "$name" '.servers[$n].transport' "$SERVERS_JSON")"

    case "$transport" in
      stdio)
        local cmd
        cmd="$(jq -r --arg n "$name" '.servers[$n].command' "$SERVERS_JSON")"
        # args は ${HOME} 等の expand を bash 側で行う
        local args_json
        args_json="$(jq -c --arg n "$name" '.servers[$n].args // []' "$SERVERS_JSON")"
        # JSON 配列を bash 配列へ
        local -a args=()
        while IFS= read -r a; do
          # ${HOME} の素朴な展開
          a="${a//\$\{HOME\}/$HOME}"
          args+=("$a")
        done < <(jq -r '.[]' <<<"$args_json")

        log_info "  - add stdio: $name ($cmd ${args[*]})"
        run claude mcp add --transport stdio --scope user "$name" -- "$cmd" "${args[@]}"
        ;;
      http)
        local url auth_env
        url="$(jq -r --arg n "$name" '.servers[$n].url' "$SERVERS_JSON")"
        auth_env="$(jq -r --arg n "$name" '.servers[$n].auth_env // empty' "$SERVERS_JSON")"
        if [[ -n "$auth_env" ]]; then
          local token="${!auth_env:-}"
          if [[ -z "$token" ]]; then
            log_warning "  - skip $name: 環境変数 $auth_env が未設定です (export $auth_env=... してから再実行)"
            continue
          fi
          log_info "  - add http: $name (with Authorization)"
          run claude mcp add --transport http --scope user "$name" "$url" \
            --header "Authorization: Bearer $token"
        else
          log_info "  - add http: $name"
          run claude mcp add --transport http --scope user "$name" "$url"
        fi
        ;;
      *)
        log_warning "  - skip $name: 未対応 transport ($transport)"
        ;;
    esac
  done

  log_success "Claude Code MCP done. 確認: claude mcp list"
}

# ---------------------------------------------
# 2. VS Code: ~/Library/Application Support/Code/User/mcp.json を生成
# ---------------------------------------------
setup_vscode() {
  local target="$HOME/Library/Application Support/Code/User/mcp.json"
  local target_dir
  target_dir="$(dirname -- "$target")"

  if [[ ! -d "$target_dir" ]]; then
    log_warning "VS Code のユーザディレクトリが見つかりません: $target_dir"
    log_info "  -> VS Code を一度起動してから再実行してください。"
    return 0
  fi

  log_info "VS Code MCP user config を書き出します: $target"
  backup_file "$target"

  # servers.json -> VS Code 形式に変換
  local generated
  generated="$(jq '
    {
      "$schema": "https://modelcontextprotocol.io/schemas/mcp-vscode.json",
      "servers": (
        .servers
        | to_entries
        | map(select(.value.enabled == true))
        | map({
            key: .key,
            value: (
              if .value.transport == "stdio" then
                {
                  "type": "stdio",
                  "command": .value.command,
                  "args": (.value.args // [])
                }
              elif .value.transport == "http" then
                ({
                  "type": "http",
                  "url": .value.url
                } + (
                  if .value.auth_env then
                    {"headers": {"Authorization": ("Bearer ${input:" + .value.auth_env + "}")}}
                  else {} end
                ))
              else empty end
            )
          })
        | from_entries
      )
    }
  ' "$SERVERS_JSON")"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%b[dry-run]%b would write %s:\n%s\n' "$C_YELLOW" "$C_RESET" "$target" "$generated"
  else
    printf '%s\n' "$generated" > "$target"
    log_success "Wrote $target"
  fi
}

setup_claude_code
setup_vscode

log_success "MCP setup done"
