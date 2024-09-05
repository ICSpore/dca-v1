set -x

## Transfer some ICP tokens to II Priccipal
II_PRINCIPAL="u34c5-gxzr2-zhq6c-uh22j-k6mip-ic5fy-hdrfx-k3adp-kc4hz-ibwxh-5ae"
dfx identity use artem
dfx canister call icp_ledger_canister icrc1_transfer "(record 
    { to = 
        record { owner = principal \"${II_PRINCIPAL}\"; subaccount = null }; 
    amount = 3_00_000_000 
    }
)"