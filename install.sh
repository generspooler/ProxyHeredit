# ProxyHeredit install script
# Detect shell (bash/zsh), locate rc file, and append sourcing of profile.sh

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
    */sh)
      echo "$HOME/.profile"
      ;;
    *)
      echo "$HOME/.profile"
      ;;
  esac
}

_heredit_get_profile_path() {
  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  echo "${script_dir}/profile.sh"
}

install() {
  local profile_script
  profile_script=$(_heredit_get_profile_path)

  if [ ! -f "$profile_script" ]; then
    echo "[ERROR] profile.sh not found at $profile_script" >&2
    return 1
  fi

  local rc_file
  rc_file=$(_heredit_detect_rc)
  local marker="# ProxyHeredit"

  if [ -f "$rc_file" ] && grep -qF "$marker" "$rc_file" 2>/dev/null; then
    echo "[SKIP] ProxyHeredit already in $rc_file"
    return 0
  fi

  mkdir -p "$(dirname "$rc_file")" 2>/dev/null

  {
    echo ""
    echo "# ============================================"
    echo "# ProxyHeredit"
    echo "# Bridge system proxy to CLI env vars"
    echo "# ============================================"
    echo "if [ -f \"$profile_script\" ]; then"
    echo "    . \"$profile_script\""
    echo "fi"
  } >> "$rc_file"

  echo "[OK] Appended source of profile.sh to $rc_file"

  if [ -f "$profile_script" ]; then
    . "$profile_script"
    echo "[OK] ProxyHeredit active in this session"
  fi

  . "$rc_file" && echo "[OK] Reloaded $rc_file"
}

install
