# ICSpore DCA protocol

## Description:
With this project you can create an executable DCA financial strategy in IC (Internet Computer) ecosystem.


## Features:
- Create and manage automated token purchase strategy.
- Frontend 100% onchain
- Automation 100% onchin without 3'th party services
- Avaliable to interact from web Applications.
- Avaliable to interact from dfx SDK.
- 0% Fee


## Workflow schema
![DCA_Schema](https://salmon-bitter-gull-231.mypinata.cloud/ipfs/QmaUQsLC6XmLfnRxXUmGUv924u3T511BJmGBy5NWYpMzRe)


## Limitations:
* Token for sell - ICP
* Token to buy - ckBTC 


## Prerequisites:
* Some [ICP coin](https://coinmarketcap.com/currencies/internet-computer/) on your Principal-id  


## Mainnet interactions
| Canister type | Canister id | Stage |
|---------------|-------------|-------|
| DCA backend   | up2ak-nqaaa-aaaap-qccia-cai | Open beta |
| DCA frontend   | qnoqa-vaaaa-aaaap-qhima-cai | Open beta |


### Step 1. Set Approve to DCA canister

This call make future transfer from your wallet possible without any additional actions

```bash
dfx canister call ryjl3-tyaaa-aaaaa-aaaba-cai  icrc2_approve '(record { amount = 40_000; spender = record{owner = principal "up2ak-nqaaa-aaaap-qccia-cai";} })' --ic
```

CLI result
```
(variant { Ok = 12_141_598 : nat })
```

### Step 2. Creating a DCA strategy for swaping ICP to ckBTC


**beneficiary** change this valuse to your principal id who will receive swap result

**tokenToSell** ryjl3-tyaaa-aaaaa-aaaba-cai - its [ICP  Canister ID](https://dashboard.internetcomputer.org/canister/ryjl3-tyaaa-aaaaa-aaaba-cai)

**tokenToBuy** mxzaz-hqaaa-aaaar-qaada-cai - its 
[ckBTC Canister ID](https://dashboard.internetcomputer.org/canister/mxzaz-hqaaa-aaaar-qaada-cai)

**frequency** - one of (Daily, Weekly, Monthly)



CLI command to create DCA strategy:
```bash
dfx canister call up2ak-nqaaa-aaaap-qccia-cai  openPosition '(record { tokenToSell = principal "ryjl3-tyaaa-aaaaa-aaaba-cai"; tokenToBuy = principal "mxzaz-hqaaa-aaaar-qaada-cai"; beneficiary = principal "hfugy-ahqdz-5sbki-vky4l-xceci-3se5z-2cb7k-jxjuq-qidax-gd53f-nqe"; amountToSell = 30_000; frequency = variant {Daily} })' --ic
```

CLI result
```bash
(variant { ok = 0 : nat })
```

## Step 3. Wait some time and receive ckBTC
Right after creation, your position will be executed for the first time (usually it takes around 3 minutes). The date of the second purchase depends on the **frequency** field from the Position



## Local development

### Step 1. Deploying ICP Ledger and ckBTC Ledger

##### Edit deploy_local.sh to change DEFAULT_IDENTITY to your identity before run
```bash
bash scripts/deploy_local.sh
```
### Step 2. deploy **dca_backend** canister
```bash
1. dfx deploy dca_backend
```

### Step 3. Set Approve to DCA canister

```bash
dfx canister call ryjl3-tyaaa-aaaaa-aaaba-cai  icrc2_approve '(record { amount = 40_000; spender = record{owner = principal "up2ak-nqaaa-aaaap-qccia-cai";} })'
```

### Step 4. Creating a DCA strategy for swaping ICP to ckBTC
Change the **hfugy-ahqdz-5sbki-vky4l-xceci-3se5z-2cb7k-jxjuq-qidax-gd53f-nqe** to your principal id who will receive swap result

```bash
dfx canister call dca_backend openPosition '(record { tokenToSell = principal "ryjl3-tyaaa-aaaaa-aaaba-cai"; tokenToBuy = principal "mxzaz-hqaaa-aaaar-qaada-cai"; beneficiary = principal "hfugy-ahqdz-5sbki-vky4l-xceci-3se5z-2cb7k-jxjuq-qidax-gd53f-nqe"; amountToSell = 30_000; frequency = variant {Daily} })'
```

## Roadmap
Our achievements and future goals.

- [x] DCA canister can serve to create/edit user Positions
- [x] ICPSwap swap pool integrated 
- [x] Onchain automation for purchases 
- [x] Frontend canister integrated
- [x] Internet Identity integrated
- [ ] Plug wallet integrated
- [ ] ckUSDT, ckUSDC, ckETH, CHAT integrated 
- [ ] Aggregator router integrated

## License
This project is licensed under the MIT license, see LICENSE.md for details.

## Status: Beta Version
This project is in the beta testing phase. We are actively working on adding new features and improving existing ones. Please be cautious as the software may contain bugs, and its stability is not guaranteed.

## Disclaimer
By using this project, you agree to do so at your own risk. The authors of the project are not responsible for any potential consequences of using this software.