#!/bin/bash

echo "Enter passphrase to encrypt private keys:"
read -s PASSPHRASE

for file in *; do
    if [[ -f "$file" ]]; then
        if grep -qE "BEGIN (RSA |EC )?PRIVATE KEY" "$file"; then
            echo "Encrypting private key file: $file"
            openssl pkey -in "$file" -aes256 -passout pass:"$PASSPHRASE" -out "${file%.pem}_enc.pem"

            # Optionally delete or backup the original file
            # mv "$file" "${file}.bak"
            rm "$file"

            echo "Encrypted file saved as: ${file%.pem}_enc.pem"
        fi
    fi
done
