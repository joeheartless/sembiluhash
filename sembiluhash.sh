#!/bin/bash

touch .keys

to_ascii() {
    echo -n "$1" | hexdump -ve '1/1 "%02x"'
}

from_ascii() {
    echo -n "$1" | xxd -r -p 2>/dev/null || { echo "Error: Invalid encoded data"; exit 1; }
}

generate_code() {
    local showtk="$*"
    local salt=$(openssl rand -hex 8) 
    local ascii_input=$(to_ascii "$showtk") 
    local hash=$(echo -n "${ascii_input}${salt}" | md5sum | awk '{print $1}')
    local short_code=${hash:0:6} 

    echo "$short_code|$ascii_input|$salt|$hash" >> .keys
    echo "Generated code: $short_code"
}

decode_code() {
    local short_code="$1"
    local match=$(grep "^${short_code}|" .keys)

    if [ -z "$match" ]; then
        echo "Error: Code not found!"
        exit 1
    fi

    local ascii_input=$(echo "$match" | awk -F'|' '{print $2}')
    local salt=$(echo "$match" | awk -F'|' '{print $3}')
    local stored_hash=$(echo "$match" | awk -F'|' '{print $4}')
    local check_hash=$(echo -n "${ascii_input}${salt}" | md5sum | awk '{print $1}')

    if [ "$check_hash" != "$stored_hash" ]; then
        echo "Error: Hash mismatch! Data might be altered."
        exit 1
    fi

    local full_data=$(from_ascii "$ascii_input")
    echo "Decoded data: $full_data"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/^${short_code}|/d" .keys
    else
        sed -i "/^${short_code}|/d" .keys
    fi
    echo "Data dengan kode $short_code berhasil dihapus dari .keys."
}

show_help() {
    echo "Usage:"
    echo " $0 -e <data>   Encode data and generate short code"
    echo " $0 -d <code>   Decode short code to original data"
    echo " $0 -h          Show this help message"
}

if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

if [ "$1" == "-e" ]; then
    shift
    generate_code "$*"
elif [ "$1" == "-d" ]; then
    shift
    decode_code "$1"
else
    show_help
    exit 1
fi
