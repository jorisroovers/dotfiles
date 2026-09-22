#!/bin/bash
# Point Codex, Claude, Grok, and Cursor at the shared RTK instructions.
# Canonical file: dotfiles/.agents/RTK.md, exposed as ~/.agents/RTK.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
RULE="$ROOT/RTK.md"
INCLUDE='@~/.agents/RTK.md'

if [ ! -f "$RULE" ]; then
  echo "missing $RULE" >&2
  exit 1
fi

mkdir -p "$HOME/.codex" "$HOME/.claude" "$HOME/.grok/rules" "$HOME/.cursor/rules"
ln -sfn "$RULE" "$HOME/.codex/RTK.md"
ln -sfn "$RULE" "$HOME/.claude/RTK.md"
ln -sfn "$RULE" "$HOME/.grok/rules/RTK.md"

{
  printf '%s\n' '---' 'description: Prefix shell commands with rtk' 'alwaysApply: true' '---' ''
  cat "$RULE"
} > "$HOME/.cursor/rules/rtk.mdc"

ensure_include() {
  local file="$1"
  local content
  mkdir -p "$(dirname "$file")"
  if [ ! -e "$file" ]; then
    printf '%s\n' "$INCLUDE" > "$file"
    return
  fi
  if [ -L "$file" ]; then
    return
  fi
  if grep -Fqx "$INCLUDE" "$file"; then
    return
  fi
  content="$(tr -d '[:space:]' < "$file")"
  case "$content" in
    "@/Users/jorisroovers/.codex/RTK.md"|"@~/.codex/RTK.md")
      printf '%s\n' "$INCLUDE" > "$file"
      ;;
    *)
      local tmp
      tmp="$(mktemp)"
      printf '%s\n\n' "$INCLUDE" | cat - "$file" > "$tmp"
      mv "$tmp" "$file"
      ;;
  esac
}

ensure_include "$HOME/.codex/AGENTS.md"
ensure_include "$HOME/.claude/CLAUDE.md"
