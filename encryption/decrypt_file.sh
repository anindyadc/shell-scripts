#!/bin/bash

# === Check input ===
ENCRYPTED_FILE="$1"
OUTPUT_FILE="${ENCRYPTED_FILE%.enc}"

if [ -z "$ENCRYPTED_FILE" ]; then
    echo "Usage: $0 <encrypted-file.enc>"
    exit 1
fi

if [ ! -f "$ENCRYPTED_FILE" ]; then
    echo "Error: File '$ENCRYPTED_FILE' not found."
    exit 1
fi

# === Prompt for decryption password ===
echo "Enter password to decrypt the file:"
read -s DECRYPT_PASS

# === Decrypt the file (with PBKDF2) ===
echo "Decrypting $ENCRYPTED_FILE to $OUTPUT_FILE..."
openssl enc -d -aes-256-cbc -pbkdf2 -in "$ENCRYPTED_FILE" -out "$OUTPUT_FILE" -pass pass:"$DECRYPT_PASS"

if [ $? -ne 0 ]; then
    echo "Decryption failed. Incorrect password or corrupted file."
    exit 1
fi

echo "Decryption successful: $OUTPUT_FILE"
