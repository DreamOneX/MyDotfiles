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
#   ip_only   = only the IP address (default)
#   iface_ip  = interface name followed by IP address
#   json      = JSON format with details
: "${GETIP_OUTPUT:=ip_only}"
# }}}

# {{{ GETIP_IFACE_LAN_ORDER
# GETIP_IFACE_LAN_ORDER:
#   default order: eth0, wlan0, enp0s3, wlp2s0, eth1, wlan1, eth2, wlan2, lo
#   adjust to match the preferred LAN interface priority on your system
: "${GETIP_IFACE_LAN_ORDER:="eth0 wlan0 enp0s3 wlp2s0 eth1 wlan1 eth2 wlan2 lo"}"
# }}}

# {{{ GETIP_IFACE_WAN_ORDER
# GETIP_IFACE_WAN_ORDER:
#   default order: ppp0, tun0, wg0, utun0, lo
#   tune this list when VPN/PPP interfaces have priority for public lookups
: "${GETIP_IFACE_WAN_ORDER:="ppp0 tun0 wg0 utun0 lo"}"
# }}}

# {{{ GETIP_BACKEND_LAN_ORDER
# GETIP_BACKEND_LAN_ORDER:
#   ip       = use the `ip` command
#   ifconfig = use the `ifconfig` command
#   hostname = use `hostname -I`
#   nmcli    = query NetworkManager via `nmcli`
#   proc     = read kernel tables under /proc
#   curl     = query public HTTP services
#   custom   = execute GETIP_CUSTOM_COMMAND (must print an IP)
#   text     = echo GETIP_TEXT_VALUE verbatim (must be an IP)
#   default order: ifconfig, ip, hostname, nmcli, proc, curl
: "${GETIP_BACKEND_LAN_ORDER:="ifconfig ip hostname nmcli proc curl"}"
# }}}

# {{{ GETIP_BACKEND_WAN_ORDER
# GETIP_BACKEND_WAN_ORDER:
#   preferred public lookup backends (same keywords as above)
#   default order: curl, custom, text
: "${GETIP_BACKEND_WAN_ORDER:="curl custom text"}"
# }}}

# {{{ EXTERNAL_IP_SERVICE
# EXTERNAL_IP_SERVICE:
#   space separated list of curl-able endpoints returning the caller IP
: "${EXTERNAL_IP_SERVICE:="https://api.ipify.org https://ifconfig.me https://ifconfig.co/ip https://icanhazip.com https://ipinfo.io/ip https://checkip.amazonaws.com"}"
# }}}

# {{{ GETIP_CURL_TIMEOUT
# GETIP_CURL_TIMEOUT:
#   timeout in seconds for curl/wget public queries
#   default: 5
: "${GETIP_CURL_TIMEOUT:=5}"
# }}}

# {{{ GETIP_CUSTOM_COMMAND
# GETIP_CUSTOM_COMMAND:
#   shell command invoked when `custom` backend is selected
#   command output must be a bare IPv4/IPv6 string
: "${GETIP_CUSTOM_COMMAND:=}"
# }}}

# {{{ GETIP_TEXT_VALUE
# GETIP_TEXT_VALUE:
#   literal IP address returned by the `text` backend
: "${GETIP_TEXT_VALUE:=}"
# }}}

set -o pipefail

__getip_last_iface=""

# {{{ helpers
__getip_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

__getip_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

__getip_json_escape() {
  local str="$1"
  str=${str//\\/\\\\}
  str=${str//"/\\"}
  str=${str//$'\n'/\\n}
  str=${str//$'\r'/\\r}
  str=${str//$'\t'/\\t}
  printf '%s' "$str"
}

__getip_normalize_version() {
  local value=${1,,}
  case "$value" in
    ipv4|v4|4) printf 'ipv4' ;;
    ipv6|v6|6) printf 'ipv6' ;;
    *) return 1 ;;
  esac
}

__getip_normalize_type() {
  local value=${1,,}
  case "$value" in
    private|lan|local) printf 'private' ;;
    public|wan|external) printf 'public' ;;
    *) return 1 ;;
  esac
}

__getip_normalize_output() {
  local value=${1,,}
  case "$value" in
    ''|ip_only|ip|plain) printf 'ip_only' ;;
    iface_ip|iface|interface) printf 'iface_ip' ;;
    json) printf 'json' ;;
    *) return 1 ;;
  esac
}

__getip_split_words() {
  local input="$1"
  # shellcheck disable=SC2206
  local words=($input)
  printf '%s\n' "${words[@]}"
}

__getip_is_valid_ipv4() {
  local ip="$1"
  [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS=.
  read -r -a octets <<<"$ip"
  local octet
  for octet in "${octets[@]}"; do
    ((octet >= 0 && octet <= 255)) || return 1
  done
  return 0
}

__getip_is_valid_ipv6() {
  local ip="$1"
  if __getip_command_exists python3; then
    python3 - "$ip" <<'PY'
import ipaddress
import sys
try:
    ipaddress.IPv6Address(sys.argv[1])
except Exception:  # noqa: BLE001
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

__getip_usable_private_ipv4() {
  local ip="$1"
  case "$ip" in
    ''|0.0.0.0|127.*|169.254.*) return 1 ;;
  esac
  __getip_is_valid_ipv4 "$ip"
}

__getip_usable_private_ipv6() {
  local ip="$1"
  [[ -n $ip ]] || return 1
  if __getip_command_exists python3; then
    python3 - "$ip" <<'PY'
import ipaddress
import sys
try:
    addr = ipaddress.IPv6Address(sys.argv[1])
except ValueError:
    sys.exit(1)
if addr.is_loopback or addr.is_link_local or addr.is_unspecified:
    sys.exit(1)
sys.exit(0)
PY
    return $?
  fi
  local lower=${ip,,}
  case "$lower" in
    ::|::1|0:0:0:0:0:0:0:1|fe80:*) return 1 ;;
  esac
  __getip_is_valid_ipv6 "$ip"
}

__getip_print_json() {
  local ip="$1"
  local type="$2"
  local version="$3"
  local iface="$4"
  printf '{\n'
  printf '  "ip": "%s",\n' "$(__getip_json_escape "$ip")"
  printf '  "type": "%s",\n' "$(__getip_json_escape "$type")"
  printf '  "version": "%s",\n' "$(__getip_json_escape "$version")"
  if [[ -n $iface ]]; then
    printf '  "interface": "%s"\n' "$(__getip_json_escape "$iface")"
  else
    printf '  "interface": null\n'
  fi
  printf '}\n'
}
# }}}

# {{{ interface helpers
__getip_pick_interface_address() {
  local _version="$1"
  local iface_list="$2"
  local -n ref_addresses=$3
  local entry iface_name candidate ip
  if [[ -n $iface_list ]]; then
    while IFS= read -r candidate; do
      [[ -n $candidate ]] || continue
      for entry in "${ref_addresses[@]}"; do
        iface_name=${entry%%|*}
        ip=${entry#*|}
        if [[ $iface_name == "$candidate" ]]; then
          __getip_last_iface="$iface_name"
          printf '%s\n' "$ip"
          return 0
        fi
      done
    done < <(__getip_split_words "$iface_list")
  fi
  if ((${#ref_addresses[@]} > 0)); then
    entry=${ref_addresses[0]}
    iface_name=${entry%%|*}
    ip=${entry#*|}
    __getip_last_iface="$iface_name"
    printf '%s\n' "$ip"
    return 0
  fi
  return 1
}
# }}}

# {{{ backend collectors
__getip_backend_ip() {
  local version="$1"
  local iface_list="$2"
  __getip_command_exists ip || return 1
  local flag=-4
  [[ $version == ipv6 ]] && flag=-6
  local line iface address
  local -a addresses=()
  while IFS=' ' read -r _ iface _ address _rest; do
    iface=${iface%:}
    address=${address%%/*}
    if [[ $version == ipv4 ]]; then
      __getip_usable_private_ipv4 "$address" || continue
    else
      __getip_usable_private_ipv6 "$address" || continue
    fi
    addresses+=("$iface|$address")
  done < <(ip -o "$flag" addr show scope global 2>/dev/null)
  ((${#addresses[@]} > 0)) || return 1
  __getip_pick_interface_address "$version" "$iface_list" addresses
}

__getip_backend_ifconfig() {
  local version="$1"
  local iface_list="$2"
  __getip_command_exists ifconfig || return 1
  local output
  output=$(ifconfig 2>/dev/null) || return 1
  local line iface="" ip
  local -a addresses=()
  while IFS= read -r line; do
    if [[ $line =~ ^([[:alnum:]_.:-]+):?[[:space:]] ]]; then
      iface=${BASH_REMATCH[1]%:}
      continue
    fi
    if [[ $version == ipv4 && $line =~ inet[[:space:]]([0-9.]+) ]]; then
      ip=${BASH_REMATCH[1]}
      __getip_usable_private_ipv4 "$ip" || continue
      addresses+=("$iface|$ip")
    elif [[ $version == ipv6 && $line =~ inet6[[:space:]]([0-9a-fA-F:]+) ]]; then
      ip=${BASH_REMATCH[1]}
      __getip_usable_private_ipv6 "$ip" || continue
      addresses+=("$iface|$ip")
    fi
  done <<<"$output"
  ((${#addresses[@]} > 0)) || return 1
  __getip_pick_interface_address "$version" "$iface_list" addresses
}

__getip_backend_hostname() {
  local version="$1"
  __getip_command_exists hostname || return 1
  local tokens token
  tokens=$(hostname -I 2>/dev/null) || return 1
  for token in $tokens; do
    token=${token%%/*}
    if [[ $version == ipv4 ]]; then
      if ! __getip_usable_private_ipv4 "$token"; then
        continue
      fi
    else
      if ! __getip_usable_private_ipv6 "$token"; then
        continue
      fi
    fi
    __getip_last_iface=""
    printf '%s\n' "$token"
    return 0
  done
  return 1
}

__getip_backend_nmcli() {
  local version="$1"
  local iface_list="$2"
  __getip_command_exists nmcli || return 1
  local -a addresses=()
  local key value iface=""
  while IFS=: read -r key value; do
    case "$key" in
      DEVICE)
        iface=$value
        ;;
      IP4.ADDRESS*)
        [[ $version == ipv4 ]] || continue
        value=${value%%/*}
        [[ -n $iface ]] || continue
        __getip_usable_private_ipv4 "$value" || continue
        addresses+=("$iface|$value")
        ;;
      IP6.ADDRESS*)
        [[ $version == ipv6 ]] || continue
        value=${value%%/*}
        [[ -n $iface ]] || continue
        __getip_usable_private_ipv6 "$value" || continue
        addresses+=("$iface|$value")
        ;;
    esac
  done < <(nmcli -t -f DEVICE,IP4.ADDRESS,IP6.ADDRESS device show 2>/dev/null)
  ((${#addresses[@]} > 0)) || return 1
  __getip_pick_interface_address "$version" "$iface_list" addresses
}

__getip_backend_proc_ipv4() {
  local iface_list="$1"
  [[ -r /proc/net/fib_trie ]] || return 1
  local line ip iface
  local current_iface=""
  local -a addresses=()
  while IFS= read -r line; do
    if [[ $line == *"32 host"* ]]; then
      read -r line || break
      if [[ $line == *"local"* ]]; then
        read -r line || break
        ip=$(__getip_trim "$line")
        if __getip_usable_private_ipv4 "$ip"; then
          addresses+=("$current_iface|$ip")
        fi
      fi
    elif [[ $line == *"Primary"* ]]; then
      iface=$(__getip_trim "${line##*--}")
      current_iface=${iface%%:*}
    fi
  done < /proc/net/fib_trie
  ((${#addresses[@]} > 0)) || return 1
  __getip_pick_interface_address ipv4 "$iface_list" addresses
}

__getip_backend_proc_ipv6() {
  local iface_list="$1"
  [[ -r /proc/net/if_inet6 ]] || return 1
  local iface raw ip
  local -a addresses=()
  while read -r raw iface _; do
    ip=${raw:0:4}:${raw:4:4}:${raw:8:4}:${raw:12:4}:${raw:16:4}:${raw:20:4}:${raw:24:4}:${raw:28:4}
    ip=${ip//:0000/:0}
    ip=${ip//0000/0}
    __getip_usable_private_ipv6 "$ip" || continue
    addresses+=("$iface|$ip")
  done < /proc/net/if_inet6
  ((${#addresses[@]} > 0)) || return 1
  __getip_pick_interface_address ipv6 "$iface_list" addresses
}

__getip_backend_proc() {
  local version="$1"
  local iface_list="$2"
  if [[ $version == ipv4 ]]; then
    __getip_backend_proc_ipv4 "$iface_list"
  else
    __getip_backend_proc_ipv6 "$iface_list"
  fi
}

__getip_backend_curl() {
  local version="$1"
  local services_string="$2"
  local timeout="${3:-$GETIP_CURL_TIMEOUT}"
  local -a services=()
  local service
  for service in $services_string; do
    [[ -n $service ]] && services+=("$service")
  done
  if ((${#services[@]} == 0)); then
    services=(
      "https://api.ipify.org"
      "https://ifconfig.me"
      "https://icanhazip.com"
      "https://checkip.amazonaws.com"
    )
  fi
  local curl_flag="--ipv4"
  [[ $version == ipv6 ]] && curl_flag="--ipv6"
  local response
  for service in "${services[@]}"; do
    if __getip_command_exists curl; then
      response=$(curl -fsSL --max-time "$timeout" "$curl_flag" "$service" 2>/dev/null) || response=""
    elif __getip_command_exists wget; then
      local -a wget_flags=(-q -T "$timeout" -O -)
      [[ $version == ipv6 ]] && wget_flags+=(-6) || wget_flags+=(-4)
      response=$(wget "${wget_flags[@]}" "$service" 2>/dev/null) || response=""
    else
      return 1
    fi
    response=${response//$'\r'/}
    response=$(__getip_trim "$response")
    response=${response%%$'\n'*}
    if [[ $version == ipv4 ]]; then
      __getip_is_valid_ipv4 "$response" || continue
    else
      __getip_is_valid_ipv6 "$response" || continue
    fi
    __getip_last_iface=""
    printf '%s\n' "$response"
    return 0
  done
  return 1
}

__getip_backend_custom() {
  local version="$1"
  local command_string="$2"
  [[ -n $command_string ]] || return 1
  local response
  response=$(eval "$command_string" 2>/dev/null) || response=""
  response=$(__getip_trim "$response")
  response=${response%%$'\n'*}
  if [[ $version == ipv4 ]]; then
    __getip_is_valid_ipv4 "$response" || return 1
  else
    __getip_is_valid_ipv6 "$response" || return 1
  fi
  __getip_last_iface=""
  printf '%s\n' "$response"
}

__getip_backend_text() {
  local version="$1"
  local value="$2"
  [[ -n $value ]] || return 1
  if [[ $version == ipv4 ]]; then
    __getip_is_valid_ipv4 "$value" || return 1
  else
    __getip_is_valid_ipv6 "$value" || return 1
  fi
  __getip_last_iface=""
  printf '%s\n' "$value"
}
# }}}

# {{{ core lookup
__getip_lookup_private_ip() {
  local version="$1"
  local iface_list="$2"
  local backends_string="$3"
  local services_string="$4"
  local timeout_value="${5:-$GETIP_CURL_TIMEOUT}"
  local -a backends=()
  local backend
  for backend in $backends_string; do
    [[ -n $backend ]] && backends+=("$backend")
  done
  for backend in "${backends[@]}"; do
    case "$backend" in
      ip)
        __getip_backend_ip "$version" "$iface_list" && return 0
        ;;
      ifconfig)
        __getip_backend_ifconfig "$version" "$iface_list" && return 0
        ;;
      hostname)
        __getip_backend_hostname "$version" && return 0
        ;;
      nmcli)
        __getip_backend_nmcli "$version" "$iface_list" && return 0
        ;;
      proc)
        __getip_backend_proc "$version" "$iface_list" && return 0
        ;;
      curl)
        __getip_backend_curl "$version" "${services_string:-$EXTERNAL_IP_SERVICE}" "$timeout_value" && return 0
        ;;
      custom)
        __getip_backend_custom "$version" "${GETIP_CUSTOM_COMMAND:-}" && return 0
        ;;
      text)
        __getip_backend_text "$version" "${GETIP_TEXT_VALUE:-}" && return 0
        ;;
    esac
  done
  return 1
}

__getip_lookup_public_ip() {
  local version="$1"
  local iface_list="$2"
  local backends_string="$3"
  local services="$4"
  local timeout="${5:-$GETIP_CURL_TIMEOUT}"
  local -a backends=()
  local backend
  for backend in $backends_string; do
    [[ -n $backend ]] && backends+=("$backend")
  done
  for backend in "${backends[@]}"; do
    case "$backend" in
      ip|ifconfig|hostname|nmcli|proc)
        # Attempt interface based discovery first for completeness.
        if __getip_lookup_private_ip "$version" "$iface_list" "$backend" "$services" "$timeout"; then
          return 0
        fi
        ;;
      curl)
        __getip_backend_curl "$version" "$services" "$timeout" && return 0
        ;;
      custom)
        __getip_backend_custom "$version" "${GETIP_CUSTOM_COMMAND:-}" && return 0
        ;;
      text)
        __getip_backend_text "$version" "${GETIP_TEXT_VALUE:-}" && return 0
        ;;
    esac
  done
  return 1
}
# }}}

# {{{ usage
__getip_usage() {
  cat <<'USAGE'
Usage: getip [options]

Options:
  -4, --ipv4            Prefer IPv4 addresses (default)
  -6, --ipv6            Prefer IPv6 addresses
  -t, --type TYPE       TYPE is "private" (default) or "public"
  -i, --interface IFACE Restrict to network interface IFACE
  -b, --backend LIST    Space separated backend order override
  -s, --service LIST    Space separated list of public IP services
  -T, --timeout SEC     Timeout in seconds for public lookups (default: 5)
  -o, --output FORMAT   Output format: ip_only, iface_ip, json
      --json            Shortcut for "--output json"
  -q, --quiet           Suppress error messages
  -h, --help            Show this help and exit
USAGE
}
# }}}

# {{{ main function
getip() {
  local version="$GETIP_IP_VERSION"
  local type="$GETIP_IP_TYPE"
  local output="$GETIP_OUTPUT"
  local iface_override=""
  local backend_override=""
  local services_override="$EXTERNAL_IP_SERVICE"
  local timeout="$GETIP_CURL_TIMEOUT"
  local quiet=0

  while (($#)); do
    case "$1" in
      -4|--ipv4)
        version=ipv4
        ;;
      -6|--ipv6)
        version=ipv6
        ;;
      -t|--type)
        if [[ -z ${2:-} ]]; then
          ((quiet)) || printf 'getip: missing value for --type\n' >&2
          return 1
        fi
        type=$2
        shift
        ;;
      -i|--interface)
        if [[ -z ${2:-} ]]; then
          ((quiet)) || printf 'getip: missing value for --interface\n' >&2
          return 1
        fi
        iface_override=$2
        shift
        ;;
      -b|--backend)
        if [[ -z ${2:-} ]]; then
          ((quiet)) || printf 'getip: missing value for --backend\n' >&2
          return 1
        fi
        backend_override=$2
        shift
        ;;
      -s|--service)
        if [[ -z ${2:-} ]]; then
          ((quiet)) || printf 'getip: missing value for --service\n' >&2
          return 1
        fi
        services_override=$2
        shift
        ;;
      -T|--timeout)
        if [[ -z ${2:-} ]]; then
          ((quiet)) || printf 'getip: missing value for --timeout\n' >&2
          return 1
        fi
        timeout=$2
        shift
        ;;
      -o|--output)
        if [[ -z ${2:-} ]]; then
          ((quiet)) || printf 'getip: missing value for --output\n' >&2
          return 1
        fi
        output=$2
        shift
        ;;
      --json)
        output=json
        ;;
      -q|--quiet)
        quiet=1
        ;;
      -h|--help)
        __getip_usage
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        ((quiet)) || printf 'getip: unknown option %s\n' "$1" >&2
        return 1
        ;;
      *)
        ((quiet)) || printf 'getip: unexpected argument %s\n' "$1" >&2
        return 1
        ;;
    esac
    shift
  done

  if (($#)); then
    ((quiet)) || printf 'getip: unexpected argument %s\n' "$1" >&2
    return 1
  fi

  version=$(__getip_normalize_version "$version") || {
    ((quiet)) || printf 'getip: unsupported IP version "%s"\n' "$version" >&2
    return 1
  }
  type=$(__getip_normalize_type "$type") || {
    ((quiet)) || printf 'getip: unsupported IP type "%s"\n' "$type" >&2
    return 1
  }
  output=$(__getip_normalize_output "$output") || {
    ((quiet)) || printf 'getip: unsupported output format "%s"\n' "$output" >&2
    return 1
  }

  local iface_list=""
  if [[ -n $iface_override ]]; then
    iface_list="$iface_override"
  else
    if [[ $type == private ]]; then
      iface_list="$GETIP_IFACE_LAN_ORDER"
    else
      iface_list="$GETIP_IFACE_WAN_ORDER"
    fi
  fi

  local backend_list=""
  if [[ -n $backend_override ]]; then
    backend_list="$backend_override"
  else
    if [[ $type == private ]]; then
      backend_list="$GETIP_BACKEND_LAN_ORDER"
    else
      backend_list="$GETIP_BACKEND_WAN_ORDER"
    fi
  fi

  local services="$services_override"
  local ip=""
  __getip_last_iface=""

  if [[ $type == private ]]; then
    ip=$(__getip_lookup_private_ip "$version" "$iface_list" "$backend_list" "$services" "$timeout") || {
      ((quiet)) || printf 'getip: unable to determine private %s address\n' "$version" >&2
      return 1
    }
  else
    ip=$(__getip_lookup_public_ip "$version" "$iface_list" "$backend_list" "$services" "$timeout") || {
      ((quiet)) || printf 'getip: unable to determine public %s address\n' "$version" >&2
      return 1
    }
  fi

  case "$output" in
    ip_only)
      printf '%s\n' "$ip"
      ;;
    iface_ip)
      if [[ -n $__getip_last_iface ]]; then
        printf '%s %s\n' "$__getip_last_iface" "$ip"
      else
        printf '%s\n' "$ip"
      fi
      ;;
    json)
      __getip_print_json "$ip" "$type" "$version" "$__getip_last_iface"
      ;;
  esac
}
# }}}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  getip "$@"
fi
