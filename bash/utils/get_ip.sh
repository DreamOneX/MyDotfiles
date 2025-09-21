#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker
# desc: Get the IP address of this machine

# {{{ GETIP_IP_VERSION
# GETIP_IP_VERSION:
#   ipv4    = prefer IPv4 (default)
#   ipv6    = prefer IPv6
: "${GETIP_IP_VERSION:=ipv4}"
# }}}

# {{{ GETIP_IP_TYPE
# GETIP_IP_TYPE:
#   private  = prefer private IP (default)
#   public   = prefer public IP (may be slow, unreliable, privacy risk, etc.)
: "${GETIP_IP_TYPE:=private}"
# }}}

# {{{ GETIP_OUTPUT
# GETIP_OUTPUT:
#   - ip_only     = only the IP address (default)
#   - iface_ip    = interface name and IP address
#   - json        = JSON format with details
: "${GETIP_OUTPUT:=ip_only}"
# }}}

# {{{ GETIP_IFACE_LAN_ORDER
# GETIP_IFACE_LAN_ORDER:
#   - default order: eth0, wlan0, enp0s3, wlp2s0, eth1, wlan1, eth2, wlan2, lo
#   NOTE: modify this list to match your system's common LAN interfaces
#   NOTE: remove any interface you don't want to use
#   NOTE: 'lo' is the loopback interface, usually, keep it at the end of the list
: "${GETIP_IFACE_LAN_ORDER:="eth0 wlan0 enp0s3 wlp2s0 eth1 wlan1 eth2 wlan2 lo"}"
# }}}

# {{{ GETIP_IFACE_WAN_ORDER
# GETIP_IFACE_WAN_ORDER:
#  - default order: ppp0, tun0, wg0, utun0, lo
#  NOTE: modify this list to match your system's common WAN interfaces
#  NOTE: remove any interface you don't want to use
#  NOTE: 'lo' is the loopback interface, usually, keep it at the end of the list
#  NOTE: WAN interfaces may be virtual (VPN, SSH tunnel, etc.)
#  NOTE: WAN interfaces may not be present on all systems
#  NOTE: WAN interfaces may not have a public IP address
#  NOTE: WAN interfaces may be slower than LAN interfaces
#  NOTE: WAN interfaces may be less reliable than LAN interfaces
#  NOTE: WAN interfaces may be a privacy risk
#  NOTE: WAN interfaces may require special configuration
#  NOTE: WAN interfaces may not be supported by all backends
#  NOTE: WAN interfaces may not be supported by all systems
#  NOTE: WAN interfaces may not be supported by all network managers
#  NOTE: WAN interfaces may not be supported by all cloud providers
#  NOTE: WAN interfaces may not be supported by all ISPs
#  NOTE: WAN interfaces may not be supported by all VPN providers
: "${GETIP_IFACE_WAN_ORDER:="ppp0 tun0 wg0 utun0 lo"}"
# }}}

# {{{ GETIP_BACKEND_LAN_ORDER
# GETIP_BACKEND_LAN_ORDER:
#   - ip       = use the 'ip' command
#   - ifconfig = use the 'ifconfig' command
#   - hostname = use the 'hostname -I' command
#   - nmcli    = use the 'nmcli' command
#   - proc     = read from /proc
#   - curl     = use an external service (may be slow, unreliable, privacy risk, etc.)
#   - custom   = if you want to add your own implementation, please set the env to a command which returns the IP
#   - text     = if you want to hardcode an IP, please refer to the custom backend, like this "echo 127.0.0.1"
#   NOTE: curl requires internet access and an external service
#   NOTE: remove any backend you don't want to use
#   default order: ifconfig, ip, hostname, nmcli, /proc, curl
: "${GETIP_BACKEND_LAN_ORDER:="ifconfig ip hostname nmcli proc curl"}"
# }}}

# {{{ GETIP_BACKEND_WAN_ORDER
# GETIP_BACKEND_WAN_ORDER:
#  - it is the same as GETIP_BACKEND_LAN_ORDER.
#  - default order: curl, custom, text
: "${GETIP_BACKEND_WAN_ORDER:="curl custom text"}"
# }}}

# {{{ GETIP_BACKEND_CUSTOM_COMMAND / GETIP_BACKEND_TEXT_VALUE / EXTERNAL_IP_SERVICE
: "${GETIP_BACKEND_CUSTOM_COMMAND:=}"
: "${GETIP_BACKEND_TEXT_VALUE:=}"
: "${GETIP_CURL_TIMEOUT:=5}"
: "${EXTERNAL_IP_SERVICE:="https://api.ipify.org https://ifconfig.me https://icanhazip.com https://checkip.amazonaws.com"}"
# }}}

set -o pipefail

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

trim() {
  local var="$1"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

split_words() {
  local value="$1"
  local -n __arr_ref="$2"
  __arr_ref=()
  local word
  for word in $value; do
    if [[ -n $word ]]; then
      __arr_ref+=("$word")
    fi
  done
}

json_escape() {
  local str="$1"
  str=${str//\\/\\\\}
  str=${str//"/\\"}
  str=${str//$'\n'/\\n}
  str=${str//$'\r'/\\r}
  str=${str//$'\t'/\\t}
  str=${str//$'\f'/\\f}
  str=${str//$'\b'/\\b}
  printf '%s' "$str"
}

is_valid_ipv4() {
  local ip="$1"
  [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS=.
  read -r -a parts <<<"$ip"
  local part
  for part in "${parts[@]}"; do
    ((part >= 0 && part <= 255)) || return 1
  done
  return 0
}

HAS_PYTHON3=0
if command_exists python3; then
  HAS_PYTHON3=1
fi

is_valid_ipv6() {
  local ip="$1"
  if ((HAS_PYTHON3)); then
    python3 - "$ip" <<'PY'
import sys
import ipaddress
try:
    ipaddress.IPv6Address(sys.argv[1])
except Exception:  # noqa: BLE001 - handled generically
    sys.exit(1)
PY
    return $?
  fi

  [[ $ip == *:* ]] || return 1
  [[ $ip =~ ^([0-9A-Fa-f]{0,4}:){2,7}[0-9A-Fa-f]{0,4}$ ]] && return 0
  [[ $ip =~ ^([0-9A-Fa-f]{1,4}:){1,7}:$ ]] && return 0
  [[ $ip =~ ^:([0-9A-Fa-f]{1,4}:){1,7}[0-9A-Fa-f]{1,4}$ ]] && return 0
  return 1
}

is_valid_ip() {
  local ip="$1"
  local version="$2"
  case "$version" in
    ipv4) is_valid_ipv4 "$ip" ;;
    ipv6) is_valid_ipv6 "$ip" ;;
    *) return 1 ;;
  esac
}

is_loopback_ipv4() {
  [[ $1 == 127.* ]]
}

is_loopback_ipv6() {
  local ip=${1,,}
  [[ $ip == ::1 || $ip == 0:0:0:0:0:0:0:1 ]]
}

is_loopback_ip() {
  local ip="$1"
  local version="$2"
  case "$version" in
    ipv4) is_loopback_ipv4 "$ip" ;;
    ipv6) is_loopback_ipv6 "$ip" ;;
    *) return 1 ;;
  esac
}

is_link_local_ipv4() {
  [[ $1 == 169.254.* ]]
}

is_link_local_ipv6() {
  local ip=${1,,}
  case "$ip" in
    fe8*|fe9*|fea*|feb*) return 0 ;;
  esac
  return 1
}

is_link_local_ip() {
  local ip="$1"
  local version="$2"
  case "$version" in
    ipv4) is_link_local_ipv4 "$ip" ;;
    ipv6) is_link_local_ipv6 "$ip" ;;
    *) return 1 ;;
  esac
}

is_private_ipv4() {
  local ip="$1"
  case "$ip" in
    10.*|192.168.*|172.16.*|172.17.*|172.18.*|172.19.*|172.20.*|172.21.*|172.22.*|172.23.*|172.24.*|172.25.*|172.26.*|172.27.*|172.28.*|172.29.*|172.30.*|172.31.*) return 0 ;;
    169.254.*) return 0 ;;
    127.*) return 0 ;;
    198.18.*|198.19.*) return 0 ;;
  esac
  if [[ $ip == 100.* ]]; then
    local second=${ip#100.}
    second=${second%%.*}
    if ((second >= 64 && second <= 127)); then
      return 0
    fi
  fi
  return 1
}

is_private_ipv6() {
  local ip=${1,,}
  case "$ip" in
    fc*|fd*) return 0 ;;
  esac
  return 1
}

is_private_ip() {
  local ip="$1"
  local version="$2"
  case "$version" in
    ipv4) is_private_ipv4 "$ip" ;;
    ipv6) is_private_ipv6 "$ip" ;;
    *) return 1 ;;
  esac
}

ip_is_allowed() {
  local ip="$1"
  local ip_type="$2"
  local version="$3"
  is_valid_ip "$ip" "$version" || return 1
  if [[ $ip_type == public ]]; then
    if is_loopback_ip "$ip" "$version"; then
      return 1
    fi
    if is_private_ip "$ip" "$version"; then
      return 1
    fi
    if is_link_local_ip "$ip" "$version"; then
      return 1
    fi
  fi
  return 0
}

iface_exists() {
  local iface="$1"
  [[ -n $iface ]] || return 1
  if command_exists ip; then
    ip link show "$iface" >/dev/null 2>&1 && return 0
  fi
  if command_exists ifconfig; then
    ifconfig "$iface" >/dev/null 2>&1 && return 0
  fi
  [[ -d /sys/class/net/$iface ]]
}

backend_ip() {
  local iface="$1"
  local version="$2"
  command_exists ip || return 1
  local family_flag
  if [[ $version == ipv4 ]]; then
    family_flag=-4
  else
    family_flag=-6
  fi
  local output
  output=$(ip -o "$family_flag" addr show dev "$iface" scope global 2>/dev/null)
  if [[ -z $output ]]; then
    output=$(ip -o "$family_flag" addr show dev "$iface" 2>/dev/null) || return 1
  fi
  local ip
  ip=$(printf '%s\n' "$output" | awk '{print $4}' | head -n1)
  ip=${ip%%/*}
  ip=${ip%%%*}
  [[ -n $ip ]] || return 1
  printf '%s\n' "$ip"
}

backend_ifconfig() {
  local iface="$1"
  local version="$2"
  command_exists ifconfig || return 1
  local output
  output=$(ifconfig "$iface" 2>/dev/null) || return 1
  local ip=""
  if [[ $version == ipv4 ]]; then
    ip=$(printf '%s\n' "$output" | awk '/inet / {print $2} /inet addr:/ {sub("addr:", "", $2); print $2}' | head -n1)
  else
    ip=$(printf '%s\n' "$output" | awk '/inet6 / {print $2} /inet6 addr:/ {sub("addr:", "", $3); print $3}' | head -n1)
  fi
  ip=${ip%%/*}
  ip=${ip%%%*}
  [[ -n $ip ]] || return 1
  printf '%s\n' "$ip"
}

backend_nmcli() {
  local iface="$1"
  local version="$2"
  command_exists nmcli || return 1
  local field
  if [[ $version == ipv4 ]]; then
    field="IP4.ADDRESS"
  else
    field="IP6.ADDRESS"
  fi
  local output
  output=$(nmcli -t -f "$field" dev show "$iface" 2>/dev/null) || return 1
  local ip
  ip=$(printf '%s\n' "$output" | awk -F':' 'NF > 1 {print $2}' | head -n1)
  ip=${ip%%/*}
  ip=${ip%%%*}
  [[ -n $ip ]] || return 1
  printf '%s\n' "$ip"
}

backend_proc() {
  local iface="$1"
  local version="$2"
  if [[ $version == ipv4 ]]; then
    [[ -r /proc/net/fib_trie ]] || return 1
    local ip
    ip=$(awk -v iface="$iface" '
      $1 == "32" && $2 == "host" {candidate=""}
      $1 == "local" {candidate=$2}
      $1 == "dev" && $2 == iface && candidate != "" {print candidate; exit}
    ' /proc/net/fib_trie)
    [[ -n $ip ]] || return 1
    printf '%s\n' "$ip"
    return 0
  else
    [[ -r /proc/net/if_inet6 ]] || return 1
    local ip
    ip=$(awk -v iface="$iface" '
      tolower($NF) == tolower(iface) {
        ip=""
        for (i = 1; i <= length($1); i += 4) {
          segment = substr($1, i, 4)
          ip = ip segment ":"
        }
        sub(/:$/, "", ip)
        print ip
        exit
      }
    ' /proc/net/if_inet6)
    [[ -n $ip ]] || return 1
    printf '%s\n' "$ip"
    return 0
  fi
}

backend_hostname() {
  local version="$1"
  command_exists hostname || return 1
  local output
  output=$(hostname -I 2>/dev/null) || return 1
  local token
  for token in $output; do
    token=$(trim "$token")
    token=${token%%/*}
    token=${token%%%*}
    if is_valid_ip "$token" "$version"; then
      if [[ $version == ipv4 ]]; then
        [[ $token == 127.* ]] && continue
      else
        local lower=${token,,}
        [[ $lower == ::1 || $lower == 0:0:0:0:0:0:0:1 ]] && continue
      fi
      printf '%s\n' "$token"
      return 0
    fi
  done
  return 1
}

BACKEND_LAST_SOURCE=""

backend_curl() {
  local version="$1"
  command_exists curl || return 1
  local -a services
  split_words "$EXTERNAL_IP_SERVICE" services
  if ((${#services[@]} == 0)); then
    services=("https://api.ipify.org")
  fi
  local curl_flag="--ipv4"
  if [[ $version == ipv6 ]]; then
    curl_flag="--ipv6"
  fi
  local service response
  for service in "${services[@]}"; do
    [[ -n $service ]] || continue
    response=$(curl -fsS --max-time "$GETIP_CURL_TIMEOUT" "$curl_flag" "$service" 2>/dev/null) || continue
    response=${response//$'\r'/}
    response=$(trim "$response")
    response=${response%%$'\n'*}
    if is_valid_ip "$response" "$version"; then
      BACKEND_LAST_SOURCE="curl:${service}"
      printf '%s\n' "$response"
      return 0
    fi
  done
  return 1
}

backend_custom() {
  local version="$1"
  [[ -n $GETIP_BACKEND_CUSTOM_COMMAND ]] || return 1
  local output
  output=$(GETIP_IP_VERSION="$version" GETIP_IP_TYPE="$GETIP_IP_TYPE" bash -c "$GETIP_BACKEND_CUSTOM_COMMAND" 2>/dev/null) || return 1
  output=$(trim "$output")
  output=${output%%$'\n'*}
  if is_valid_ip "$output" "$version"; then
    BACKEND_LAST_SOURCE="custom"
    printf '%s\n' "$output"
    return 0
  fi
  return 1
}

backend_text() {
  local version="$1"
  [[ -n $GETIP_BACKEND_TEXT_VALUE ]] || return 1
  local ip
  ip=$(trim "$GETIP_BACKEND_TEXT_VALUE")
  ip=${ip%%$'\n'*}
  if is_valid_ip "$ip" "$version"; then
    BACKEND_LAST_SOURCE="text"
    printf '%s\n' "$ip"
    return 0
  fi
  return 1
}

backend_external_command() {
  local backend="$1"
  local iface="$2"
  local version="$3"
  command_exists "$backend" || return 1
  local output
  output=$(GETIP_IFACE="$iface" GETIP_IP_VERSION="$version" GETIP_IP_TYPE="$GETIP_IP_TYPE" "$backend" 2>/dev/null) || return 1
  output=$(trim "$output")
  output=${output%%$'\n'*}
  if is_valid_ip "$output" "$version"; then
    BACKEND_LAST_SOURCE="$backend"
    printf '%s\n' "$output"
    return 0
  fi
  return 1
}

invoke_backend() {
  local backend="$1"
  local iface="$2"
  local version="$3"
  local backend_lc=${backend,,}
  BACKEND_LAST_SOURCE="$backend"
  case "$backend_lc" in
    ip) backend_ip "$iface" "$version" ;;
    ifconfig) backend_ifconfig "$iface" "$version" ;;
    nmcli) backend_nmcli "$iface" "$version" ;;
    proc|/proc|procfs) backend_proc "$iface" "$version" ;;
    hostname) backend_hostname "$version" ;;
    curl) backend_curl "$version" ;;
    custom) backend_custom "$version" ;;
    text) backend_text "$version" ;;
    *) backend_external_command "$backend" "$iface" "$version" ;;
  esac
}

backend_is_global() {
  local backend_lc="$1"
  case "$backend_lc" in
    curl|hostname|custom|text) return 0 ;;
  esac
  return 1
}

get_ip_for_type() {
  local ip_type="$1"
  local version="$2"
  local -a ifaces backends
  if [[ $ip_type == public ]]; then
    split_words "$GETIP_IFACE_WAN_ORDER" ifaces
    split_words "$GETIP_BACKEND_WAN_ORDER" backends
  else
    split_words "$GETIP_IFACE_LAN_ORDER" ifaces
    split_words "$GETIP_BACKEND_LAN_ORDER" backends
  fi

  if ((${#backends[@]} == 0)); then
    backends=(ip ifconfig hostname)
  fi

  local backend backend_lc iface ip source
  for backend in "${backends[@]}"; do
    backend_lc=${backend,,}
    if backend_is_global "$backend_lc"; then
      ip=$(invoke_backend "$backend" "" "$version") || continue
      source=${BACKEND_LAST_SOURCE:-$backend}
      if ip_is_allowed "$ip" "$ip_type" "$version"; then
        printf '%s|%s|%s\n' "$ip" "" "$source"
        return 0
      fi
      continue
    fi

    for iface in "${ifaces[@]}"; do
      [[ -n $iface ]] || continue
      if ! iface_exists "$iface"; then
        continue
      fi
      ip=$(invoke_backend "$backend" "$iface" "$version") || continue
      source=${BACKEND_LAST_SOURCE:-$backend}
      if ip_is_allowed "$ip" "$ip_type" "$version"; then
        printf '%s|%s|%s\n' "$ip" "$iface" "$source"
        return 0
      fi
    done
  done
  return 1
}

print_json() {
  local ip="$1"
  local iface="$2"
  local backend="$3"
  local ip_type="$4"
  local version="$5"
  printf '{\n'
  printf '  "ip": "%s",\n' "$(json_escape "$ip")"
  if [[ -n $iface ]]; then
    printf '  "interface": "%s",\n' "$(json_escape "$iface")"
  else
    printf '  "interface": null,\n'
  fi
  if [[ -n $backend ]]; then
    printf '  "backend": "%s",\n' "$(json_escape "$backend")"
  else
    printf '  "backend": null,\n'
  fi
  printf '  "type": "%s",\n' "$(json_escape "$ip_type")"
  printf '  "version": "%s"\n' "$(json_escape "$version")"
  printf '}\n'
}

print_output() {
  local ip="$1"
  local iface="$2"
  local backend="$3"
  case "${GETIP_OUTPUT,,}" in
    ip_only|ip)
      printf '%s\n' "$ip"
      ;;
    iface_ip|iface|interface)
      if [[ -n $iface ]]; then
        printf '%s %s\n' "$iface" "$ip"
      else
        printf '%s\n' "$ip"
      fi
      ;;
    json)
      print_json "$ip" "$iface" "$backend" "$GETIP_IP_TYPE" "$GETIP_IP_VERSION"
      ;;
    *)
      printf '%s\n' "$ip"
      ;;
  esac
}

normalise_ip_version() {
  local version=${1,,}
  case "$version" in
    ipv4|v4|4) printf 'ipv4' ;;
    ipv6|v6|6) printf 'ipv6' ;;
    *) return 1 ;;
  esac
}

normalise_ip_type() {
  local type=${1,,}
  case "$type" in
    private|lan|local) printf 'private' ;;
    public|wan|external) printf 'public' ;;
    *) return 1 ;;
  esac
}

normalise_output_mode() {
  local mode=${1,,}
  case "$mode" in
    ip_only|ip) printf 'ip_only' ;;
    iface_ip|iface|interface) printf 'iface_ip' ;;
    json) printf 'json' ;;
    *) return 1 ;;
  esac
}

main() {
  local normalised
  normalised=$(normalise_ip_version "$GETIP_IP_VERSION") || {
    printf 'get_ip: unsupported GETIP_IP_VERSION=%s\n' "$GETIP_IP_VERSION" >&2
    return 1
  }
  GETIP_IP_VERSION=$normalised

  normalised=$(normalise_ip_type "$GETIP_IP_TYPE") || {
    printf 'get_ip: unsupported GETIP_IP_TYPE=%s\n' "$GETIP_IP_TYPE" >&2
    return 1
  }
  GETIP_IP_TYPE=$normalised

  normalised=$(normalise_output_mode "$GETIP_OUTPUT") || {
    printf 'get_ip: unsupported GETIP_OUTPUT=%s\n' "$GETIP_OUTPUT" >&2
    return 1
  }
  GETIP_OUTPUT=$normalised

  local result ip iface backend
  result=$(get_ip_for_type "$GETIP_IP_TYPE" "$GETIP_IP_VERSION") || {
    printf 'get_ip: unable to determine %s %s address\n' "$GETIP_IP_TYPE" "$GETIP_IP_VERSION" >&2
    return 1
  }

  IFS='|' read -r ip iface backend <<<"$result"
  print_output "$ip" "$iface" "$backend"
}

main "$@"
