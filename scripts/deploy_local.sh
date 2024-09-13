#!/bin/bash
set -x

dfx start --background --clean

# Create identities and canister arguments

DEFAULT_IDENTITY=Your_DFX_Identity_name

dfx identity new minter
dfx identity use minter
MINTER_ACCOUNT_ID=$(dfx ledger account-id)
MINTER_PRRINCIPAL_ID=$(dfx identity get-principal)

dfx identity use $DEFAULT_IDENTITY
DEFAULT_ACCOUNT_ID=$(dfx ledger account-id)
DEFAULT_PRINCIPAL_ID=$(dfx identity get-principal)

ckBTC_TOKEN_NAME="Chain Key Bitcoin"
ckBTC_TOKEN_SYMBOL="ckBTC"

ICP_TOKEN_NAME="Internet Computer"
ICP_TOKEN_SYMBOL="ICP"

PRE_MINTED_TOKENS=10_000_000_000
ICP_TRANSFER_FEE=10_000
ckBTC_TRANSFER_FEE=10

dfx identity new archive_controller
dfx identity use archive_controller
ARCHIVE_CONTROLLER=$(dfx identity get-principal)
TRIGGER_THRESHOLD=2000
NUM_OF_BLOCK_TO_ARCHIVE=1000
CYCLE_FOR_ARCHIVE_CREATION=10000000000000
FEATURE_FLAGS=true

# Deploy ICP ledger canister
dfx identity use $DEFAULT_IDENTITY
dfx deploy icp_ledger_canister --specified-id ryjl3-tyaaa-aaaaa-aaaba-cai  --argument "(variant { Init = 
record {
      minting_account = \"${MINTER_ACCOUNT_ID}\";
      initial_values = vec {
        record {
          \"${DEFAULT_ACCOUNT_ID}\";
          record {
            e8s = ${PRE_MINTED_TOKENS} : nat64;
          };
        };
      };
      send_whitelist = vec {};
      transfer_fee = opt record {
        e8s = ${ICP_TRANSFER_FEE} : nat64;
      };
      token_symbol = opt \"${ICP_TOKEN_SYMBOL}\";
      token_name = opt \"${ICP_TOKEN_NAME}\";
    }
})"

# Deploy ckBTC ledger canister
dfx deploy ckBTC_ledger_canister --specified-id mxzaz-hqaaa-aaaar-qaada-cai --argument "(variant {Init = 
record {
     token_symbol = \"${ckBTC_TOKEN_SYMBOL}\";
     token_name = \"${ckBTC_TOKEN_NAME}\";
     minting_account = record { owner = principal \"${MINTER_PRRINCIPAL_ID}\" };
     transfer_fee = ${ckBTC_TRANSFER_FEE};
     metadata = vec {};
     feature_flags = opt record{icrc2 = ${FEATURE_FLAGS}};
     initial_balances = vec { record { record { owner = principal \"${DEFAULT_PRINCIPAL_ID}\"; }; ${PRE_MINTED_TOKENS}; }; };
     archive_options = record {
         num_blocks_to_archive = ${NUM_OF_BLOCK_TO_ARCHIVE};
         trigger_threshold = ${TRIGGER_THRESHOLD};
         controller_id = principal \"${ARCHIVE_CONTROLLER}\";
         cycles_for_archive_creation = opt ${CYCLE_FOR_ARCHIVE_CREATION};
     };
 }
})"
