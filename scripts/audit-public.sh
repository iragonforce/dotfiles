#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
failures=0

fail() {
  printf '\033[1;31m[public-audit]\033[0m %s\n' "$*" >&2
  failures=$((failures + 1))
}

while IFS= read -r path; do
  rel=${path#"$ROOT_DIR/"}
  [ "$rel" = "scripts/audit-public.sh" ] && continue
  case "$rel" in
    .git/*|*.DS_Store|*.swp|*.swo|*.un~|*.shada|*.viminfo|*/.ssh/*|*/.env|*/.env.*|*/credentials/*|*/secrets/*|*/private/*)
      fail "forbidden path: $rel"
      continue
      ;;
  esac
  size=$(wc -c < "$path" | tr -d ' ')
  [ "$size" -le 1048576 ] || fail "file is larger than 1 MiB: $rel"
  case "$rel" in
    */plugin/*|*/pack/*|*/lazy/*|*/plugged/*|*/.cache/*|*/.local/share/*)
      fail "generated/plugin tree must not be committed: $rel"
      ;;
  esac
  if grep -Iq . "$path" 2>/dev/null; then
    if grep -nE "(/Users/|/home/)[A-Za-z0-9_-]+/" "$path" >/dev/null 2>&1; then
      fail "machine-specific absolute home path: $rel"
    fi
    if grep -nE '(BEGIN [A-Z ]*PRIVATE KEY|github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9]+|sk-[A-Za-z0-9]{16,}|api[_-]?key[[:space:]]*[=:]|password[[:space:]]*[=:]|secret[[:space:]]*[=:])' "$path" >/dev/null 2>&1; then
      fail "credential-like content: $rel"
    fi
  fi
done < <(find "$ROOT_DIR" -type f -not -path "$ROOT_DIR/.git/*" -not -path "$ROOT_DIR/.DS_Store" -print)

if grep -RInE --exclude=audit-public.sh 'tmux-auto-start|ghostty-tmux|tmux-ssh|openclaw|sunshine' "$ROOT_DIR/home" "$ROOT_DIR/scripts" "$ROOT_DIR/install.sh" >/dev/null 2>&1; then
  fail "retired auto-start or service helper reference found"
fi

if [ "$failures" -gt 0 ]; then
  printf '%d public-audit failure(s)\n' "$failures" >&2
  exit 1
fi
printf '%s\n' 'public-audit: OK'
