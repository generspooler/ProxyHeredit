# Uninstall ProxyHeredit on macOS/Linux
# 1. Remove ProxyHeredit sourcing block from shell rc file
# 2. Remove GitHub Token
# 3. Unset env vars in current session

_heredit_detect_rc() {
  case "$SHELL" in
    */zsh)
      echo "${ZDOTDIR:-$HOME}/.zshrc"
      ;;
    */bash)
      if [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
      elif [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.profile"
      fi
      ;;
    *)
      echo "$HOME/.profile"
      ;;
  esac
}

_heredit_remove_github_token() {
  local rc_file="$1"

  if grep -q "GITHUB_TOKEN" "$rc_file" 2>/dev/null; then
    echo ""
    printf "Remove GitHub Token from %s? [y/N]: " "$rc_file"
    read -r _confirm
    case "$_confirm" in
      y|Y|yes|YES)
        perl -i -0pe '
          s/\n# GitHub Token \(ProxyHeredit\)\nexport GITHUB_TOKEN="[^"]*"\n/\n/gs;
        ' "$rc_file"
        echo "[OK] Removed GitHub Token from $rc_file"
        ;;
      *)
        echo "[SKIP] GitHub Token left in $rc_file"
        ;;
    esac
  fi
}

uninstall() {
  local rc_file
  rc_file=$(_heredit_detect_rc)

  if [ ! -f "$rc_file" ]; then
    echo "[SKIP] $rc_file does not exist"
  elif ! command -v perl >/dev/null 2>&1; then
    echo "[WARN] perl not found; cannot remove ProxyHeredit block from $rc_file (manual edit needed)" >&2
  else
    local before
    before=$(cat "$rc_file")
    # Same patterns as install.sh so the two stay in sync.
    perl -i -0pe '
      s/\n# ={3,}\n# ProxyHeredit\n.*?\nfi\n/\n/gs;
      s/\n# =+ ProxyHeredit Start =+\n.*?\n# =+ ProxyHeredit End =+\n/\n/gs;
    ' "$rc_file"
    if [ "$before" = "$(cat "$rc_file")" ]; then
      echo "[SKIP] ProxyHeredit not found in $rc_file"
    else
      echo "[OK] Removed ProxyHeredit from $rc_file"
    fi
  fi

  _heredit_remove_github_token "$rc_file"

  unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
  unset GITHUB_TOKEN
  echo "[OK] Cleaned up environment variables"
}

uninstall
