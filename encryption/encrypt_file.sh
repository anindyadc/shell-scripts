#!/bin/bash

# === Check input ===
FILE="$1"
ENCRYPTED_FILE="${FILE}.enc"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file-to-encrypt>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found."
    exit 1
fi

# === Prompt for encryption password ===
echo "Enter password to encrypt the file:"
read -s ENCRYPT_PASS
echo "Re-enter password:"
read -s ENCRYPT_PASS2

if [ "$ENCRYPT_PASS" != "$ENCRYPT_PASS2" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

# === Encrypt the file (with PBKDF2) ===
echo "Encrypting $FILE to $ENCRYPTED_FILE..."
openssl enc -aes-256-cbc -pbkdf2 -salt -in "$FILE" -out "$ENCRYPTED_FILE" -pass pass:"$ENCRYPT_PASS"

if [ $? -ne 0 ]; then
    echo "Encryption failed."
    exit 1
fi

echo "Encryption successful: $ENCRYPTED_FILE"

# === Optional: Delete original file ===
read -p "Delete original file ($FILE)? [y/N]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    rm -f "$FILE"
    echo "Original file deleted."
fi
