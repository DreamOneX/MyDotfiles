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

# {{{ EXTERNAL_IP_SERVICE
# EXTERNAL_IP_SERVICE:
#   - ipinfo.io/ip
#   - icanhazip.com
#   - ifconfig.me
#   - checkip.amazonaws.com
#   - api.ipify.org
#   - ident.me
#   - myexternalip.com/raw
#   - bot.whatismyipaddress.com
#   - checkip.dyndns.org
#   - myip.dnsomatic.com
#   - whatismyip.akamai.com
#   - curlmyip.com
#   - ifconfig.co/ip
#   - wtfismyip.com/text
#   - ip.seeip.org
#   - ipecho.net/plain
