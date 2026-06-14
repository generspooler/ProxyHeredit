# ============================================
# ProxyHeredit
# Bridge system proxy to CLI env vars
# Supports: macOS, Linux
# ============================================
# Reads system proxy settings and exports them as
# HTTP_PROXY / HTTPS_PROXY / NO_PROXY env vars
# so Node.js tools (opencode, claude code, npm, etc.)
# inherit the proxy automatically.

_heredit_get_proxy_url() {
  case "$(uname -s)" in
    Darwin)
      local info
      info=$(scutil --proxy 2>/dev/null) || return 1
      local enabled
      enabled=$(echo "$info" | awk '/HTTPEnable/{print $3}')
      [ "$enabled" = "1" ] || return 1
      local server port
      server=$(echo "$info" | awk '/HTTPProxy/{print $3}')
      port=$(echo "$info" | awk '/HTTPPort/{print $3}')
      [ -n "$server" ] && [ -n "$port" ] || return 1
      echo "http://$server:$port"
      ;;
    Linux)
      if command -v gsettings &>/dev/null; then
        local mode
        mode=$(gsettings get org.gnome.system.proxy mode 2>/dev/null)
        if [ "$mode" = "'manual'" ]; then
          local server port
          server=$(gsettings get org.gnome.system.proxy.http host 2>/dev/null | tr -d "'")
          port=$(gsettings get org.gnome.system.proxy.http port 2>/dev/null)
          if [ -n "$server" ] && [ -n "$port" ]; then
            echo "http://$server:$port"
            return 0
          fi
        fi
      fi
      if command -v kreadconfig5 &>/dev/null; then
        local server port
        server=$(kreadconfig5 --group "Proxy Settings" --key "httpProxy" 2>/dev/null)
        port=$(kreadconfig5 --group "Proxy Settings" --key "httpProxyPort" 2>/dev/null)
        if [ -n "$server" ] && [ -n "$port" ]; then
          echo "http://$server:$port"
          return 0
        fi
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

_heredit_get_no_proxy() {
  case "$(uname -s)" in
    Darwin)
      local info
      info=$(scutil --proxy 2>/dev/null) || { echo "localhost,127.0.0.1"; return; }
      local exceptions
      exceptions=$(echo "$info" | awk '/ExceptionsList/{flag=1; next} /^[[:space:]]*}/{flag=0} flag' |
        awk -F: '{print $2}' | tr -d ' "' | paste -sd, - 2>/dev/null)
      if [ -z "$exceptions" ]; then
        echo "localhost,127.0.0.1"
      else
        echo "${exceptions},localhost,127.0.0.1"
      fi
      ;;
    Linux)
      local no_proxy="localhost,127.0.0.1"
      if command -v gsettings &>/dev/null; then
        local ignore_hosts
        ignore_hosts=$(gsettings get org.gnome.system.proxy ignore-hosts 2>/dev/null)
        if [ -n "$ignore_hosts" ] && [ "$ignore_hosts" != "@as []" ]; then
          ignore_hosts=$(echo "$ignore_hosts" | tr -d "[]'" | tr ',' '\n' | sed 's/^ *//' | tr '\n' ',' | sed 's/,$//')
          [ -n "$ignore_hosts" ] && no_proxy="${no_proxy},${ignore_hosts}"
        fi
      fi
      echo "$no_proxy"
      ;;
    *)
      echo "localhost,127.0.0.1"
      ;;
  esac
}

_heredit_setup() {
  local proxy_url
  proxy_url=$(_heredit_get_proxy_url)
  if [ -n "$proxy_url" ]; then
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    local no_proxy
    no_proxy=$(_heredit_get_no_proxy)
    export NO_PROXY="$no_proxy"
    export no_proxy="$no_proxy"
  else
    unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
  fi
}

_heredit_setup
