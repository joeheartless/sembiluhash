#!/bin/bash

# Fungsi untuk encode data ke ASCII Hex
to_ascii() {
    echo -n "$1" | hexdump -ve '1/1 "%02x"'
}

# Fungsi untuk decode ASCII Hex ke string asli
from_ascii() {
    echo -n "$1" | xxd -r -p 2>/dev/null || echo "Error: Invalid encoded data"
}

# Fungsi generate kode pendek (encode)
generate_code() {
    local showtk="$*"
    local salt=$(openssl rand -hex 8) # Generate salt random
    local ascii_input=$(to_ascii "$showtk") # Ubah input ke ASCII Hex
    local hash=$(echo -n "${ascii_input}${salt}" | md5sum | awk '{print $1}')
    local short_code=${hash:0:6} # Ambil 6 karakter pertama

    # Simpan ke file (format: short_code|ascii_input|salt|hash)
    echo "$short_code|$ascii_input|$salt|$hash" >> .keys
    echo "Generated code: $short_code"
}

# Fungsi decode kode pendek
decode_code() {
    local short_code="$1"
    local match=$(grep "^${short_code}|" .keys)

    if [ -z "$match" ]; then
        echo "Error: Code not found!"
        exit 1
    fi

    # Ambil data dari file
    local ascii_input=$(echo "$match" | awk -F'|' '{print $2}')
    local salt=$(echo "$match" | awk -F'|' '{print $3}')
    local stored_hash=$(echo "$match" | awk -F'|' '{print $4}')
    
    # Verifikasi apakah hash sesuai
    local check_hash=$(echo -n "${ascii_input}${salt}" | md5sum | awk '{print $1}')
    if [ "$check_hash" != "$stored_hash" ]; then
        echo "Error: Hash mismatch! Data might be altered."
        exit 1
    fi

    # Decode dari ASCII Hex ke teks asli
    local full_data=$(from_ascii "$ascii_input")
    echo "Decoded data: $full_data"

    # Hapus data yg udah didecode dari .keys
    sed -i "/^${short_code}|/d" .keys
    echo "Data dengan kode $short_code berhasil dihapus dari .keys."
}

# Menu bantuan
show_help() {
    echo "Usage:"
    echo " $0 -e <data> Encode data and generate short code"
    echo " $0 -d <code> Decode short code to original data"
    echo " $0 -h Show this help message"
}

# Main script
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi
