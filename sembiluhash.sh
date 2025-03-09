#!/bin/bash
VERSION="Sembilu X PLIR-256 v.6.9"

touch .keys
TEMP_KEYS_FILE=".keys"

to_ascii() {
    echo -n "$1" | hexdump -ve '1/1 "%02x"'
}

from_ascii() {
    echo -n "$1" | xxd -r -p 2>/dev/null || {
        echo "Error: Invalid encoded data"
        exit 1
    }
}

rotate_tr() {
    echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}

show_version() {
    echo "Version: $VERSION"
}

show_help() {
    cat <<EOF
Usage:
  $0 -e|--encode <data>    Encode <data> and generate a short code.
  $0 -d|--decode <code>    Decode <code> back to the original data.
  $0 -h|--help             Display this help message.
  $0 -v|--version          Display the program version.
  $0 --generate-salt       Generate random salt

Feature:
  - Entries that are newly encoded get a 10-minute expiry time.
  - If that time passes, the entry is automatically removed from .keys.
  - Old entries (which do not have an expiry column) will remain intact.

EOF
}

clean_expired_entries() {
    local now
    now=$(date +%s)

    # Buat file sementara
    awk -F'|' -v now="$now" '
    {
        if (NF < 5) {
            print $0
        } else {
            expiry_time = $5
            if (expiry_time ~ /^[0-9]+$/ && now <= expiry_time) {
                print $0
            }
        }
    }
    ' "$TEMP_KEYS_FILE" > "$TEMP_KEYS_FILE.tmp"

    mv "$TEMP_KEYS_FILE.tmp" "$TEMP_KEYS_FILE"
}

generate_code() {
    local showtk="$*"

    local rotated_input
    rotated_input=$(rotate_tr "$showtk")

    local salt
    salt=$(openssl rand -hex 8)

    local ascii_input
    ascii_input=$(to_ascii "$rotated_input")

    local hash
    hash=$(echo -n "${ascii_input}${salt}" | plirsum | awk '{print $1}')

    local short_code=${hash:0:6}

    local now
    now=$(date +%s)
    local expiry_time=$(( now + 600 ))
    echo "$short_code|$ascii_input|$salt|$hash|$expiry_time" >> "$TEMP_KEYS_FILE"

    echo "Generated code: $short_code"
}

decode_code() {
    local short_code="$1"

    local match
    match=$(grep "^${short_code}|" "$TEMP_KEYS_FILE")

    if [ -z "$match" ]; then
        echo "Error: Code not found or expired!"
        exit 1
    fi

    local ascii_input salt stored_hash
    ascii_input=$(echo "$match" | awk -F'|' '{print $2}')
    salt=$(echo "$match"        | awk -F'|' '{print $3}')
    stored_hash=$(echo "$match" | awk -F'|' '{print $4}')

    local check_hash
    check_hash=$(echo -n "${ascii_input}${salt}" | plirsum | awk '{print $1}')

    if [ "$check_hash" != "$stored_hash" ]; then
        echo "Error: Hash mismatch! Data might be altered."
        exit 1
    fi

    local full_data
    full_data=$(rotate_tr "$(from_ascii "$ascii_input")")

    echo -e "Decoded data:\n$(echo "$full_data" | fold -w 50 -s)"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/^${short_code}|/d" "$TEMP_KEYS_FILE"
    else
        sed -i "/^${short_code}|/d" "$TEMP_KEYS_FILE"
    fi
}

generate_salt() {
    local input="$1"

    if [ -z "$input" ]; then
        echo "Error: No input provided for salt generation!"
        exit 1
    fi
    local rotated_input
    rotated_input=$(rotate_tr "$showtk")

    local salt
    salt=$(openssl rand -hex 8)

    local ascii_input
    ascii_input=$(to_ascii "$rotated_input")

    local hash
    hash=$(echo -n "${ascii_input}${salt}" | plirsum | awk '{print substr ($1,1,16)}')

    echo "$hash"
}

if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        show_version
        exit 0
        ;;
    -e|--encode)
        shift
        if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
            ENCODE_DATA="$*"
        else
            ENCODE_DATA="$(cat -)"
        fi
        clean_expired_entries

        generate_code "$ENCODE_DATA"
        ;;
    -d|--decode)
        shift
        SHORT_CODE="$1"
        if [ -z "$SHORT_CODE" ]; then
            echo "Error: no code supplied to decode!"
            exit 1
        fi

        clean_expired_entries

        decode_code "$SHORT_CODE"
        ;;
    --generate-salt)
        shift
        if [ -z "$1" ]; then
            echo "Error: No username supplied!"
            exit 1
        fi
        generate_salt "$1"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
