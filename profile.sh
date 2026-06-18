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
  local info="$1"
  case "$(uname -s)" in
    Darwin)
      [ -n "$info" ] || info=$(scutil --proxy 2>/dev/null) || return 1
      # Prefer HTTPS proxy, then HTTP, then SOCKS
      local https_en http_en socks_en server port scheme
      https_en=$(echo "$info" | awk '/HTTPSEnable/{print $3}')
      http_en=$(echo "$info" | awk '/HTTPEnable/{print $3}')
      socks_en=$(echo "$info" | awk '/SOCKSEnable/{print $3}')
      if [ "$https_en" = "1" ]; then
        server=$(echo "$info" | awk '/HTTPSProxy/{print $3}')
        port=$(echo "$info" | awk '/HTTPSPort/{print $3}')
        scheme="http"
      elif [ "$http_en" = "1" ]; then
        server=$(echo "$info" | awk '/HTTPProxy/{print $3}')
        port=$(echo "$info" | awk '/HTTPPort/{print $3}')
        scheme="http"
      elif [ "$socks_en" = "1" ]; then
        server=$(echo "$info" | awk '/SOCKSProxy/{print $3}')
        port=$(echo "$info" | awk '/SOCKSPort/{print $3}')
        scheme="socks5"
      else
        return 1
      fi
      [ -n "$server" ] && [ -n "$port" ] || return 1
      echo "${scheme}://${server}:${port}"
      ;;
    Linux)
      if command -v gsettings &>/dev/null; then
        local mode
        mode=$(gsettings get org.gnome.system.proxy mode 2>/dev/null)
        if [ "$mode" = "'manual'" ]; then
          # Prefer https schema, then http, then socks
          local server port
          server=$(gsettings get org.gnome.system.proxy.https host 2>/dev/null | tr -d "'")
          port=$(gsettings get org.gnome.system.proxy.https port 2>/dev/null)
          if [ -n "$server" ] && [ -n "$port" ] && [ "$port" != "0" ]; then
            echo "http://$server:$port"
            return 0
          fi
          server=$(gsettings get org.gnome.system.proxy.http host 2>/dev/null | tr -d "'")
          port=$(gsettings get org.gnome.system.proxy.http port 2>/dev/null)
          if [ -n "$server" ] && [ -n "$port" ] && [ "$port" != "0" ]; then
            echo "http://$server:$port"
            return 0
          fi
          server=$(gsettings get org.gnome.system.proxy.socks host 2>/dev/null | tr -d "'")
          port=$(gsettings get org.gnome.system.proxy.socks port 2>/dev/null)
          if [ -n "$server" ] && [ -n "$port" ] && [ "$port" != "0" ]; then
            echo "socks5://$server:$port"
            return 0
          fi
        fi
      fi
      if command -v kreadconfig6 &>/dev/null; then
        local server port
        server=$(kreadconfig6 --group "Proxy Settings" --key "httpProxy" 2>/dev/null)
        port=$(kreadconfig6 --group "Proxy Settings" --key "httpProxyPort" 2>/dev/null)
        if [ -n "$server" ] && [ -n "$port" ]; then
          echo "http://$server:$port"
          return 0
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
  local info="$1"
  case "$(uname -s)" in
    Darwin)
      if [ -z "$info" ]; then
        info=$(scutil --proxy 2>/dev/null)
      fi
      if [ -z "$info" ]; then
        echo "localhost,127.0.0.1"
        return 0
      fi
      local exceptions
      # scutil ExceptionsList entries look like "  0 : 127.0.0.1" / "  3 : ::1".
      # Strip the index prefix on " : " so IPv6 entries (::1, fe80::1) survive.
      exceptions=$(echo "$info" | awk '/ExceptionsList/{flag=1; next} /^[[:space:]]*}/{flag=0} flag' |
        sed 's/^[[:space:]]*[0-9]* : //' | tr -d ' "' | paste -sd, - 2>/dev/null)
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
  local cached_info=""
  if [ "$(uname -s)" = "Darwin" ]; then
    cached_info=$(scutil --proxy 2>/dev/null)
  fi
  local proxy_url
  proxy_url=$(_heredit_get_proxy_url "$cached_info")
  if [ -n "$proxy_url" ]; then
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    local no_proxy
    no_proxy=$(_heredit_get_no_proxy "$cached_info")
    export NO_PROXY="$no_proxy"
    export no_proxy="$no_proxy"
  else
    unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
  fi
}

_heredit_setup
