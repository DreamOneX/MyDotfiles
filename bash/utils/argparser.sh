#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker

# A small argparse-like helper for Bash 4+ scripts.
#
# Example:
#   source ./utils/argparser.sh
#   argparse_init "demo" "Demo command"
#   argparse_add_flag verbose -v --verbose "Enable verbose output" 0
#   argparse_add_option name -n --name NAME "Set name" "default" 0
#   argparse_add_positional file FILE "Input file" 1
#   argparse_parse "$@" || return
#   (( ARGPARSE_HELP_REQUESTED )) && return 0

# Bash 4 provides associative arrays. This file intentionally avoids
# Bash 4.2's declare -g so it remains usable on older Bash 4.x releases.
declare -A ARGPARSE_OPTION_TYPE=()
declare -A ARGPARSE_OPTION_VAR=()
declare -A ARGPARSE_OPTION_SHORT=()
declare -A ARGPARSE_OPTION_LONG=()
declare -A ARGPARSE_OPTION_METAVAR=()
declare -A ARGPARSE_OPTION_HELP=()
declare -A ARGPARSE_OPTION_DEFAULT=()
declare -A ARGPARSE_OPTION_REQUIRED=()
declare -A ARGPARSE_LOOKUP=()

declare -A ARGPARSE_POSITIONAL_VAR=()
declare -A ARGPARSE_POSITIONAL_METAVAR=()
declare -A ARGPARSE_POSITIONAL_HELP=()
declare -A ARGPARSE_POSITIONAL_REQUIRED=()

# {{{ internal state
argparse_init() {
    ARGPARSE_PROG="${1:-${0##*/}}"
    ARGPARSE_DESCRIPTION="${2:-}"
    ARGPARSE_HELP_REQUESTED=0
    ARGPARSE_REMAINDER=()

    ARGPARSE_OPTION_KEYS=()
    ARGPARSE_POSITIONAL_KEYS=()

    ARGPARSE_OPTION_TYPE=()
    ARGPARSE_OPTION_VAR=()
    ARGPARSE_OPTION_SHORT=()
    ARGPARSE_OPTION_LONG=()
    ARGPARSE_OPTION_METAVAR=()
    ARGPARSE_OPTION_HELP=()
    ARGPARSE_OPTION_DEFAULT=()
    ARGPARSE_OPTION_REQUIRED=()
    ARGPARSE_LOOKUP=()

    ARGPARSE_POSITIONAL_VAR=()
    ARGPARSE_POSITIONAL_METAVAR=()
    ARGPARSE_POSITIONAL_HELP=()
    ARGPARSE_POSITIONAL_REQUIRED=()
}

_argparse_die() {
    printf '%s: error: %s\n' "${ARGPARSE_PROG:-${0##*/}}" "$*" >&2
    printf "Try '%s --help' for more information.\n" "${ARGPARSE_PROG:-${0##*/}}" >&2
    return 2
}

_argparse_normalize_short() {
    local value="${1:-}"
    if [[ -z "$value" || "$value" == "-" ]]; then
        printf ''
    elif [[ "$value" == --* ]]; then
        printf '%s' "$value"
    elif [[ "$value" == -* ]]; then
        printf '%s' "$value"
    else
        printf -- '-%s' "$value"
    fi
}

_argparse_normalize_long() {
    local value="${1:-}"
    if [[ -z "$value" || "$value" == "--" ]]; then
        printf ''
    elif [[ "$value" == --* ]]; then
        printf '%s' "$value"
    else
        printf -- '--%s' "$value"
    fi
}

_argparse_set_var() {
    printf -v "$1" '%s' "$2"
}

_argparse_register_option() {
    local key="$1"
    local short="$2"
    local long="$3"

    if [[ -n "$short" ]]; then
        if [[ -n "${ARGPARSE_LOOKUP[$short]+set}" ]]; then
            printf '%s: duplicate option: %s\n' "${ARGPARSE_PROG:-${0##*/}}" "$short" >&2
            return 2
        fi
        ARGPARSE_LOOKUP[$short]="$key"
    fi

    if [[ -n "$long" ]]; then
        if [[ -n "${ARGPARSE_LOOKUP[$long]+set}" ]]; then
            printf '%s: duplicate option: %s\n' "${ARGPARSE_PROG:-${0##*/}}" "$long" >&2
            return 2
        fi
        ARGPARSE_LOOKUP[$long]="$key"
    fi
}

_argparse_option_names_available() {
    local short="$1"
    local long="$2"

    if [[ -z "$short" && -z "$long" ]]; then
        printf '%s: option needs a short or long name\n' "${ARGPARSE_PROG:-${0##*/}}" >&2
        return 2
    fi

    if [[ "$short" == "-h" || "$long" == "--help" ]]; then
        printf '%s: -h/--help is reserved for generated help\n' "${ARGPARSE_PROG:-${0##*/}}" >&2
        return 2
    fi

    if [[ -n "$short" && -n "${ARGPARSE_LOOKUP[$short]+set}" ]]; then
        printf '%s: duplicate option: %s\n' "${ARGPARSE_PROG:-${0##*/}}" "$short" >&2
        return 2
    fi

    if [[ -n "$long" && -n "${ARGPARSE_LOOKUP[$long]+set}" ]]; then
        printf '%s: duplicate option: %s\n' "${ARGPARSE_PROG:-${0##*/}}" "$long" >&2
        return 2
    fi
}
# }}}

# {{{ public declarations
argparse_add_flag() {
    local var="${1:?missing destination variable}"
    local short
    local long
    local help="${4:-}"
    local default="${5:-0}"
    local key

    short="$(_argparse_normalize_short "${2:-}")"
    long="$(_argparse_normalize_long "${3:-}")"
    key="opt_${#ARGPARSE_OPTION_KEYS[@]}"

    _argparse_option_names_available "$short" "$long" || return 2

    ARGPARSE_OPTION_KEYS+=("$key")
    ARGPARSE_OPTION_TYPE[$key]="flag"
    ARGPARSE_OPTION_VAR[$key]="$var"
    ARGPARSE_OPTION_SHORT[$key]="$short"
    ARGPARSE_OPTION_LONG[$key]="$long"
    ARGPARSE_OPTION_METAVAR[$key]=""
    ARGPARSE_OPTION_HELP[$key]="$help"
    ARGPARSE_OPTION_DEFAULT[$key]="$default"
    ARGPARSE_OPTION_REQUIRED[$key]="0"

    _argparse_register_option "$key" "$short" "$long"
}

argparse_add_option() {
    local var="${1:?missing destination variable}"
    local short
    local long
    local metavar="${4:-VALUE}"
    local help="${5:-}"
    local default="${6:-}"
    local required="${7:-0}"
    local key

    short="$(_argparse_normalize_short "${2:-}")"
    long="$(_argparse_normalize_long "${3:-}")"
    key="opt_${#ARGPARSE_OPTION_KEYS[@]}"

    _argparse_option_names_available "$short" "$long" || return 2

    ARGPARSE_OPTION_KEYS+=("$key")
    ARGPARSE_OPTION_TYPE[$key]="option"
    ARGPARSE_OPTION_VAR[$key]="$var"
    ARGPARSE_OPTION_SHORT[$key]="$short"
    ARGPARSE_OPTION_LONG[$key]="$long"
    ARGPARSE_OPTION_METAVAR[$key]="$metavar"
    ARGPARSE_OPTION_HELP[$key]="$help"
    ARGPARSE_OPTION_DEFAULT[$key]="$default"
    ARGPARSE_OPTION_REQUIRED[$key]="$required"

    _argparse_register_option "$key" "$short" "$long"
}

argparse_add_positional() {
    local var="${1:?missing destination variable}"
    local metavar="${2:-ARG}"
    local help="${3:-}"
    local required="${4:-1}"
    local key="pos_${#ARGPARSE_POSITIONAL_KEYS[@]}"

    ARGPARSE_POSITIONAL_KEYS+=("$key")
    ARGPARSE_POSITIONAL_VAR[$key]="$var"
    ARGPARSE_POSITIONAL_METAVAR[$key]="$metavar"
    ARGPARSE_POSITIONAL_HELP[$key]="$help"
    ARGPARSE_POSITIONAL_REQUIRED[$key]="$required"
}
# }}}

# {{{ help
argparse_help() {
    local usage="Usage: ${ARGPARSE_PROG:-${0##*/}}"
    local key
    local label
    local short
    local long
    local metavar
    local help
    local required
    local default

    if ((${#ARGPARSE_OPTION_KEYS[@]})); then
        usage+=" [options]"
    fi

    for key in "${ARGPARSE_POSITIONAL_KEYS[@]}"; do
        metavar="${ARGPARSE_POSITIONAL_METAVAR[$key]}"
        required="${ARGPARSE_POSITIONAL_REQUIRED[$key]}"
        if [[ "$required" == "1" || "$required" == "true" || "$required" == "yes" ]]; then
            usage+=" $metavar"
        else
            usage+=" [$metavar]"
        fi
    done

    printf '%s\n' "$usage"

    if [[ -n "${ARGPARSE_DESCRIPTION:-}" ]]; then
        printf '\n%s\n' "$ARGPARSE_DESCRIPTION"
    fi

    printf '\nOptions:\n'
    printf '  %-28s %s\n' '-h, --help' 'Show this help message'

    for key in "${ARGPARSE_OPTION_KEYS[@]}"; do
        short="${ARGPARSE_OPTION_SHORT[$key]}"
        long="${ARGPARSE_OPTION_LONG[$key]}"
        metavar="${ARGPARSE_OPTION_METAVAR[$key]}"
        help="${ARGPARSE_OPTION_HELP[$key]}"
        default="${ARGPARSE_OPTION_DEFAULT[$key]}"
        required="${ARGPARSE_OPTION_REQUIRED[$key]}"

        label=""
        if [[ -n "$short" ]]; then
            label="$short"
            if [[ "${ARGPARSE_OPTION_TYPE[$key]}" == "option" ]]; then
                label+=" $metavar"
            fi
        fi
        if [[ -n "$long" ]]; then
            [[ -n "$label" ]] && label+=", "
            label+="$long"
            if [[ "${ARGPARSE_OPTION_TYPE[$key]}" == "option" ]]; then
                label+=" $metavar"
            fi
        fi

        if [[ "$required" == "1" || "$required" == "true" || "$required" == "yes" ]]; then
            help+=" (required)"
        elif [[ "${ARGPARSE_OPTION_TYPE[$key]}" == "option" && -n "$default" ]]; then
            help+=" (default: $default)"
        fi

        printf '  %-28s %s\n' "$label" "$help"
    done

    if ((${#ARGPARSE_POSITIONAL_KEYS[@]})); then
        printf '\nPositionals:\n'
        for key in "${ARGPARSE_POSITIONAL_KEYS[@]}"; do
            metavar="${ARGPARSE_POSITIONAL_METAVAR[$key]}"
            help="${ARGPARSE_POSITIONAL_HELP[$key]}"
            required="${ARGPARSE_POSITIONAL_REQUIRED[$key]}"
            if [[ "$required" != "1" && "$required" != "true" && "$required" != "yes" ]]; then
                help+=" (optional)"
            fi
            printf '  %-28s %s\n' "$metavar" "$help"
        done
    fi
}
# }}}

# {{{ parsing
argparse_parse() {
    local _argparse_key
    local _argparse_arg
    local _argparse_name
    local _argparse_value
    local _argparse_pos_index=0
    local _argparse_explicit_options=()
    local _argparse_pos_var

    ARGPARSE_HELP_REQUESTED=0
    ARGPARSE_REMAINDER=()

    for _argparse_key in "${ARGPARSE_OPTION_KEYS[@]}"; do
        _argparse_set_var "${ARGPARSE_OPTION_VAR[$_argparse_key]}" "${ARGPARSE_OPTION_DEFAULT[$_argparse_key]}"
    done

    for _argparse_key in "${ARGPARSE_POSITIONAL_KEYS[@]}"; do
        _argparse_set_var "${ARGPARSE_POSITIONAL_VAR[$_argparse_key]}" ""
    done

    while (($#)); do
        _argparse_arg="$1"

        case "$_argparse_arg" in
            -h|--help)
                argparse_help
                ARGPARSE_HELP_REQUESTED=1
                return 0
                ;;
            --)
                shift
                while (($#)); do
                    if ((_argparse_pos_index < ${#ARGPARSE_POSITIONAL_KEYS[@]})); then
                        _argparse_key="${ARGPARSE_POSITIONAL_KEYS[$_argparse_pos_index]}"
                        _argparse_set_var "${ARGPARSE_POSITIONAL_VAR[$_argparse_key]}" "$1"
                        ((_argparse_pos_index += 1))
                    else
                        ARGPARSE_REMAINDER+=("$1")
                    fi
                    shift
                done
                break
                ;;
            --*=*)
                _argparse_name="${_argparse_arg%%=*}"
                _argparse_value="${_argparse_arg#*=}"
                if [[ -z "${ARGPARSE_LOOKUP[$_argparse_name]+set}" ]]; then
                    _argparse_die "unknown option: $_argparse_name"
                    return 2
                fi
                _argparse_key="${ARGPARSE_LOOKUP[$_argparse_name]}"
                if [[ "${ARGPARSE_OPTION_TYPE[$_argparse_key]}" != "option" ]]; then
                    _argparse_die "option does not take a value: $_argparse_name"
                    return 2
                fi
                _argparse_set_var "${ARGPARSE_OPTION_VAR[$_argparse_key]}" "$_argparse_value"
                _argparse_explicit_options+=("$_argparse_key")
                shift
                ;;
            -*)
                _argparse_name="$_argparse_arg"
                if [[ -z "${ARGPARSE_LOOKUP[$_argparse_name]+set}" ]]; then
                    _argparse_die "unknown option: $_argparse_name"
                    return 2
                fi
                _argparse_key="${ARGPARSE_LOOKUP[$_argparse_name]}"
                if [[ "${ARGPARSE_OPTION_TYPE[$_argparse_key]}" == "flag" ]]; then
                    _argparse_set_var "${ARGPARSE_OPTION_VAR[$_argparse_key]}" "1"
                    _argparse_explicit_options+=("$_argparse_key")
                    shift
                else
                    if (($# < 2)); then
                        _argparse_die "option requires a value: $_argparse_name"
                        return 2
                    fi
                    _argparse_value="$2"
                    _argparse_set_var "${ARGPARSE_OPTION_VAR[$_argparse_key]}" "$_argparse_value"
                    _argparse_explicit_options+=("$_argparse_key")
                    shift 2
                fi
                ;;
            *)
                if ((_argparse_pos_index < ${#ARGPARSE_POSITIONAL_KEYS[@]})); then
                    _argparse_key="${ARGPARSE_POSITIONAL_KEYS[$_argparse_pos_index]}"
                    _argparse_set_var "${ARGPARSE_POSITIONAL_VAR[$_argparse_key]}" "$_argparse_arg"
                    ((_argparse_pos_index += 1))
                else
                    ARGPARSE_REMAINDER+=("$_argparse_arg")
                fi
                shift
                ;;
        esac
    done

    local _argparse_seen_key
    local _argparse_found
    for _argparse_key in "${ARGPARSE_OPTION_KEYS[@]}"; do
        if [[ "${ARGPARSE_OPTION_REQUIRED[$_argparse_key]}" == "1" || "${ARGPARSE_OPTION_REQUIRED[$_argparse_key]}" == "true" || "${ARGPARSE_OPTION_REQUIRED[$_argparse_key]}" == "yes" ]]; then
            _argparse_found=0
            for _argparse_seen_key in "${_argparse_explicit_options[@]}"; do
                if [[ "$_argparse_seen_key" == "$_argparse_key" ]]; then
                    _argparse_found=1
                    break
                fi
            done
            if ((_argparse_found == 0)); then
                _argparse_name="${ARGPARSE_OPTION_LONG[$_argparse_key]:-${ARGPARSE_OPTION_SHORT[$_argparse_key]}}"
                _argparse_die "required option missing: $_argparse_name"
                return 2
            fi
        fi
    done

    for _argparse_key in "${ARGPARSE_POSITIONAL_KEYS[@]}"; do
        if [[ "${ARGPARSE_POSITIONAL_REQUIRED[$_argparse_key]}" == "1" || "${ARGPARSE_POSITIONAL_REQUIRED[$_argparse_key]}" == "true" || "${ARGPARSE_POSITIONAL_REQUIRED[$_argparse_key]}" == "yes" ]]; then
            _argparse_pos_var="${ARGPARSE_POSITIONAL_VAR[$_argparse_key]}"
            if [[ -z "${!_argparse_pos_var}" ]]; then
                _argparse_die "required positional missing: ${ARGPARSE_POSITIONAL_METAVAR[$_argparse_key]}"
                return 2
            fi
        fi
    done

    return 0
}
# }}}
