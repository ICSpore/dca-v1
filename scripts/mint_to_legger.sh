set -x

## Transfer some ICP tokens to II Priccipal
II_PRINCIPAL="h6nh3-ofzyy-6jar5-kuybm-enviy-3wt3s-ub27l-dwtp4-mwml6-woh6e-wae"
dfx identity use artem
dfx canister call icp_ledger_canister icrc1_transfer "(record 
    { to = 
        record { owner = principal \"${II_PRINCIPAL}\"; subaccount = null }; 
    amount = 3_00_000_000 
    }
)"