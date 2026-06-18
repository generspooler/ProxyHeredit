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

_heredit_prompt_github_token() {
  local rc_file="$1"

  grep -q "export GITHUB_TOKEN=" "$rc_file" 2>/dev/null && return

  echo ""
  echo "┌  GitHub API Token (optional)"
  echo "│  Avoids 403 rate limiting (60 → 5000 req/hour)"
  echo "│  when tools like opencode access api.github.com"
  echo "│  Create at: https://github.com/settings/tokens"
  echo "└  ─────────────────────────────────────"
  printf "Enter GitHub Token (blank to skip): "
  read -rs _token
  echo

  if [ -n "$_token" ]; then
    case "$_token" in
      ghp_*|gho_*|ghu_*|ghs_*|ghr_*|github_pat_*)
        {
          echo ""
          echo "# GitHub Token (ProxyHeredit)"
          echo "export GITHUB_TOKEN=\"$_token\""
        } >> "$rc_file"
        export GITHUB_TOKEN="$_token"
        echo "[OK] GitHub Token configured"
        ;;
      *)
        echo "[SKIP] Invalid token format (expected ghp_*, gho_*, github_pat_*, etc.)"
        ;;
    esac
  else
    echo "[SKIP] GitHub Token not configured (run install.sh again to set)"
  fi
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
  local start_marker="# ========== ProxyHeredit Start =========="
  local end_marker="# ========== ProxyHeredit End =========="

  mkdir -p "$(dirname "$rc_file")" 2>/dev/null

  # Remove existing ProxyHeredit block (old and new format)
  if [ -f "$rc_file" ] && command -v perl >/dev/null 2>&1; then
    perl -i -0pe '
      s/\n# ={3,}\n# ProxyHeredit\n.*?\nfi\n/\n/gs;
      s/\n# =+ ProxyHeredit Start =+\n.*?\n# =+ ProxyHeredit End =+\n/\n/gs;
    ' "$rc_file"
  elif [ -f "$rc_file" ]; then
    echo "[WARN] perl not found; could not clean old ProxyHeredit block (manual edit may be needed)" >&2
  fi

  # Append new block with markers
  {
    echo "$start_marker"
    echo "# ProxyHeredit"
    echo "# Bridge system proxy to CLI env vars"
    echo "# ============================================"
    echo "if [ -f \"$profile_script\" ]; then"
    echo "    . \"$profile_script\""
    echo "fi"
    echo "$end_marker"
  } >> "$rc_file"

  echo "[OK] Wrote ProxyHeredit block to $rc_file"

  if [ -f "$profile_script" ]; then
    . "$profile_script"
    echo "[OK] ProxyHeredit active in this session"
  fi

  "$SHELL" -c ". \"$rc_file\"" && echo "[OK] Reloaded $rc_file"

  _heredit_prompt_github_token "$rc_file"
}

install
