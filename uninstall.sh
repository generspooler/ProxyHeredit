<#
.SYNOPSIS
    Uninstall ProxyHeredit on macOS/Linux: remove from shell rc file.
.DESCRIPTION
    1. Remove ProxyHeredit sourcing block from shell rc file
    2. Unset env vars in current session
#>

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

uninstall() {
  local rc_file
  rc_file=$(_heredit_detect_rc)

  if [ -f "$rc_file" ]; then
    local tmp_file
    tmp_file="$(mktemp)"

    awk '
      /^# ==+$/ && !skip { skip=1; next }
      /^fi$/ && skip { skip=0; next }
      skip { next }
      { print }
    ' "$rc_file" > "$tmp_file"

    if cmp -s "$rc_file" "$tmp_file" >/dev/null 2>&1; then
      rm -f "$tmp_file"
      echo "[SKIP] ProxyHeredit not found in $rc_file"
    else
      mv "$tmp_file" "$rc_file"
      echo "[OK] Removed ProxyHeredit from $rc_file"
    fi
  else
    echo "[SKIP] $rc_file does not exist"
  fi

  unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
  echo "[OK] Cleaned up environment variables"
}

uninstall
