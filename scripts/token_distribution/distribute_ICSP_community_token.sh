#!/bin/bash
set -e
set -x

# Create identities and canister arguments
DEFAULT_IDENTITY=Stefs
MINTER_IDENTITY=ICSP_minter

dfx identity use $MINTER_IDENTITY
MINTER_PRINCIPAL_ID=$(dfx identity get-principal)

# File with winners
FILE=scripts/token_distribution/on_demand.txt

# Amount to transfer (150) in Decimal 8
AMOUNT=15000000000

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "Error: $FILE not found!"
    exit 1
fi

# Function to transfer tokens to a single principal
transfer_tokens() {
    local PRINCIPAL_ID=$1
    echo "Processing transfer to principal: $PRINCIPAL_ID"
    
    if dfx canister call spore_point icrc1_transfer "(record { to = record { owner = principal \"$PRINCIPAL_ID\"; subaccount = null }; amount = $AMOUNT })" --ic; then
        echo "Transfer successful: $PRINCIPAL_ID"
        echo "$PRINCIPAL_ID" >> successful_transfers.txt
    else
        echo "Transfer failed for principal: $PRINCIPAL_ID"
    fi
}

export -f transfer_tokens

# Check if parallel is available
if command -v parallel &> /dev/null; then
    echo "Using parallel processing"
    # Use parallel to process the file
    cat "$FILE" | sed 's/^[0-9]*\. *//' | tr -d '\r' | xargs -I{} echo {} | parallel --jobs 10 transfer_tokens {}
else
    echo "Parallel not found, using sequential processing"
    # Use a simple loop for sequential processing
    while IFS= read -r line; do
        PRINCIPAL_ID=$(echo "$line" | sed 's/^[0-9]*\. *//' | tr -d '\r')
        transfer_tokens "$PRINCIPAL_ID"
    done < "$FILE"
fi

# Count successful transfers
SUCCESSFUL_TRANSFERS=$(wc -l < successful_transfers.txt)

echo "Distribution complete. Successful transfers: $SUCCESSFUL_TRANSFERS"

# Clean up
# rm successful_transfers.txt
