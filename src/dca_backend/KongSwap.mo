// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module {
  public type AddLiquiditAmountsResult = {
    #Ok : AddLiquidityAmountsReply;
    #Err : Text;
  };
  public type AddLiquidityAmountsReply = {
    add_lp_token_amount : Nat;
    amount_0 : Nat;
    amount_1 : Nat;
    address_0 : Text;
    address_1 : Text;
    symbol_0 : Text;
    symbol_1 : Text;
    chain_0 : Text;
    chain_1 : Text;
    symbol : Text;
    fee_0 : Nat;
    fee_1 : Nat;
  };
  public type AddLiquidityArgs = {
    token_0 : Text;
    token_1 : Text;
    amount_0 : Nat;
    amount_1 : Nat;
    tx_id_0 : ?TxId;
    tx_id_1 : ?TxId;
  };
  public type AddLiquidityAsyncResult = { #Ok : Nat64; #Err : Text };
  public type AddLiquidityReply = {
    ts : Nat64;
    request_id : Nat64;
    status : Text;
    tx_id : Nat64;
    add_lp_token_amount : Nat;
    transfer_ids : [TransferIdReply];
    amount_0 : Nat;
    amount_1 : Nat;
    claim_ids : [Nat64];
    symbol_0 : Text;
    symbol_1 : Text;
    chain_0 : Text;
    chain_1 : Text;
    symbol : Text;
  };
  public type AddLiquidityResult = { #Ok : AddLiquidityReply; #Err : Text };
  public type AddPoolArgs = {
    token_0 : Text;
    token_1 : Text;
    amount_0 : Nat;
    amount_1 : Nat;
    tx_id_0 : ?TxId;
    tx_id_1 : ?TxId;
    lp_fee_bps : ?Nat8;
    on_kong : ?Bool;
  };
  public type AddPoolReply = {
    ts : Nat64;
    request_id : Nat64;
    status : Text;
    tx_id : Nat64;
    lp_token_symbol : Text;
    balance : Nat;
    add_lp_token_amount : Nat;
    transfer_ids : [TransferIdReply];
    amount_0 : Nat;
    amount_1 : Nat;
    claim_ids : [Nat64];
    symbol_0 : Text;
    symbol_1 : Text;
    chain_0 : Text;
    chain_1 : Text;
    lp_token_supply : Nat;
    symbol : Text;
    lp_fee_bps : Nat8;
    on_kong : Bool;
  };
  public type AddPoolResult = { #Ok : AddPoolReply; #Err : Text };
  public type AddTokenArgs = { token : Text; on_kong : ?Bool };
  public type AddTokenReply = { #IC : ICTokenReply };
  public type AddTokenResult = { #Ok : AddTokenReply; #Err : Text };
  public type BalancesReply = {
    ts : Nat64;
    usd_balance : Float;
    balance : Float;
    name : Text;
    amount_0 : Float;
    amount_1 : Float;
    symbol_0 : Text;
    symbol_1 : Text;
    usd_amount_0 : Float;
    usd_amount_1 : Float;
    symbol : Text;
  };
  public type CheckPoolsReply = {
    expected_balance : ExpectedBalance;
    diff_balance : Int;
    actual_balance : Nat;
    symbol : Text;
  };
  public type CheckPoolsResult = { #Ok : [CheckPoolsReply]; #Err : Text };
  public type ExpectedBalance = {
    balance : Nat;
    pool_balances : [PoolExpectedBalance];
    unclaimed_claims : Nat;
  };
  public type ICTokenReply = {
    fee : Nat;
    decimals : Nat8;
    token : Text;
    token_id : Nat32;
    chain : Text;
    name : Text;
    canister_id : Text;
    icrc1 : Bool;
    icrc2 : Bool;
    icrc3 : Bool;
    pool_symbol : Text;
    symbol : Text;
    on_kong : Bool;
  };
  public type ICTransferReply = {
    is_send : Bool;
    block_index : Nat;
    chain : Text;
    canister_id : Text;
    amount : Nat;
    symbol : Text;
  };
  public type Icrc28TrustedOriginsResponse = { trusted_origins : [Text] };
  public type LPTokenReply = {
    fee : Nat;
    decimals : Nat8;
    token : Text;
    token_id : Nat32;
    chain : Text;
    name : Text;
    address : Text;
    pool_id_of : Nat32;
    pool_symbol : Text;
    total_supply : Nat;
    symbol : Text;
    on_kong : Bool;
  };
  public type MessagesReply = {
    ts : Nat64;
    title : Text;
    message : Text;
    message_id : Nat64;
  };
  public type MessagesResult = { #Ok : [MessagesReply]; #Err : Text };
  public type PoolExpectedBalance = {
    balance : Nat;
    kong_fee : Nat;
    pool_symbol : Text;
    lp_fee : Nat;
  };
  public type PoolReply = {
    lp_token_symbol : Text;
    balance : Nat;
    total_lp_fee : Nat;
    name : Text;
    lp_fee_0 : Nat;
    lp_fee_1 : Nat;
    balance_0 : Nat;
    balance_1 : Nat;
    rolling_24h_volume : Nat;
    rolling_24h_apy : Float;
    address_0 : Text;
    address_1 : Text;
    rolling_24h_num_swaps : Nat;
    symbol_0 : Text;
    symbol_1 : Text;
    total_volume : Nat;
    pool_id : Nat32;
    price : Float;
    chain_0 : Text;
    chain_1 : Text;
    lp_token_supply : Nat;
    symbol : Text;
    rolling_24h_lp_fee : Nat;
    lp_fee_bps : Nat8;
    on_kong : Bool;
  };
  public type PoolsReply = {
    total_24h_lp_fee : Nat;
    total_tvl : Nat;
    total_24h_volume : Nat;
    pools : [PoolReply];
    total_24h_num_swaps : Nat;
  };
  public type PoolsResult = { #Ok : PoolsReply; #Err : Text };
  public type RemoveLiquidityAmountsReply = {
    lp_fee_0 : Nat;
    lp_fee_1 : Nat;
    amount_0 : Nat;
    amount_1 : Nat;
    address_0 : Text;
    address_1 : Text;
    symbol_0 : Text;
    symbol_1 : Text;
    chain_0 : Text;
    chain_1 : Text;
    remove_lp_token_amount : Nat;
    symbol : Text;
  };
  public type RemoveLiquidityAmountsResult = {
    #Ok : RemoveLiquidityAmountsReply;
    #Err : Text;
  };
  public type RemoveLiquidityArgs = {
    token_0 : Text;
    token_1 : Text;
    remove_lp_token_amount : Nat;
  };
  public type RemoveLiquidityAsyncResult = { #Ok : Nat64; #Err : Text };
  public type RemoveLiquidityReply = {
    ts : Nat64;
    request_id : Nat64;
    status : Text;
    tx_id : Nat64;
    transfer_ids : [TransferIdReply];
    lp_fee_0 : Nat;
    lp_fee_1 : Nat;
    amount_0 : Nat;
    amount_1 : Nat;
    claim_ids : [Nat64];
    symbol_0 : Text;
    symbol_1 : Text;
    chain_0 : Text;
    chain_1 : Text;
    remove_lp_token_amount : Nat;
    symbol : Text;
  };
  public type RemoveLiquidityResult = {
    #Ok : RemoveLiquidityReply;
    #Err : Text;
  };
  public type RequestReply = {
    #AddLiquidity : AddLiquidityReply;
    #Swap : SwapReply;
    #AddPool : AddPoolReply;
    #RemoveLiquidity : RemoveLiquidityReply;
    #Pending;
  };
  public type RequestRequest = {
    #AddLiquidity : AddLiquidityArgs;
    #Swap : SwapArgs;
    #AddPool : AddPoolArgs;
    #RemoveLiquidity : RemoveLiquidityArgs;
  };
  public type RequestsReply = {
    ts : Nat64;
    request_id : Nat64;
    request : RequestRequest;
    statuses : [Text];
    reply : RequestReply;
  };
  public type RequestsResult = { #Ok : [RequestsReply]; #Err : Text };
  public type SendArgs = { token : Text; to_address : Text; amount : Nat };
  public type SendReply = {
    ts : Nat64;
    request_id : Nat64;
    status : Text;
    tx_id : Nat64;
    chain : Text;
    to_address : Text;
    amount : Nat;
    symbol : Text;
  };
  public type SendResult = { #OK : SendReply; #Err : Text };
  public type SwapAmountsReply = {
    txs : [SwapAmountsTxReply];
    receive_chain : Text;
    mid_price : Float;
    pay_amount : Nat;
    receive_amount : Nat;
    pay_symbol : Text;
    receive_symbol : Text;
    receive_address : Text;
    pay_address : Text;
    price : Float;
    pay_chain : Text;
    slippage : Float;
  };
  public type SwapAmountsResult = { #Ok : SwapAmountsReply; #Err : Text };
  public type SwapAmountsTxReply = {
    receive_chain : Text;
    pay_amount : Nat;
    receive_amount : Nat;
    pay_symbol : Text;
    receive_symbol : Text;
    receive_address : Text;
    pool_symbol : Text;
    pay_address : Text;
    price : Float;
    pay_chain : Text;
    lp_fee : Nat;
    gas_fee : Nat;
  };
  public type SwapArgs = {
    receive_token : Text;
    max_slippage : ?Float;
    pay_amount : Nat;
    referred_by : ?Text;
    receive_amount : ?Nat;
    receive_address : ?Text;
    pay_token : Text;
    pay_tx_id : ?TxId;
  };
  public type SwapAsyncResult = { #Ok : Nat64; #Err : Text };
  public type SwapReply = {
    ts : Nat64;
    txs : [SwapTxReply];
    request_id : Nat64;
    status : Text;
    tx_id : Nat64;
    transfer_ids : [TransferIdReply];
    receive_chain : Text;
    mid_price : Float;
    pay_amount : Nat;
    receive_amount : Nat;
    claim_ids : [Nat64];
    pay_symbol : Text;
    receive_symbol : Text;
    price : Float;
    pay_chain : Text;
    slippage : Float;
  };
  public type SwapResult = { #Ok : SwapReply; #Err : Text };
  public type SwapTxReply = {
    ts : Nat64;
    receive_chain : Text;
    pay_amount : Nat;
    receive_amount : Nat;
    pay_symbol : Text;
    receive_symbol : Text;
    pool_symbol : Text;
    price : Float;
    pay_chain : Text;
    lp_fee : Nat;
    gas_fee : Nat;
  };
  public type TokenReply = { #IC : ICTokenReply; #LP : LPTokenReply };
  public type TokensResult = { #Ok : [TokenReply]; #Err : Text };
  public type TransferIdReply = {
    transfer_id : Nat64;
    transfer : TransferReply;
  };
  public type TransferReply = { #IC : ICTransferReply };
  public type TransfersResult = { #Ok : [TransferIdReply]; #Err : Text };
  public type TxId = { #TransactionId : Text; #BlockIndex : Nat };
  public type TxsReply = {
    #AddLiquidity : AddLiquidityReply;
    #Swap : SwapReply;
    #AddPool : AddPoolReply;
    #RemoveLiquidity : RemoveLiquidityReply;
  };
  public type TxsResult = { #Ok : [TxsReply]; #Err : Text };
  public type UserBalancesReply = { #LP : BalancesReply };
  public type UserBalancesResult = { #Ok : [UserBalancesReply]; #Err : Text };
  public type UserReply = {
    account_id : Text;
    user_name : Text;
    fee_level_expires_at : ?Nat64;
    referred_by : ?Text;
    user_id : Nat32;
    fee_level : Nat8;
    principal_id : Text;
    referred_by_expires_at : ?Nat64;
    campaign1_flags : [Bool];
    my_referral_code : Text;
  };
  public type UserResult = { #Ok : UserReply; #Err : Text };
  public type ValidateAddLiquidityResult = { #Ok : Text; #Err : Text };
  public type Self = actor {
    add_liquidity : shared AddLiquidityArgs -> async AddLiquidityResult;
    add_liquidity_amounts : shared query (
        Text,
        Nat,
        Text,
      ) -> async AddLiquiditAmountsResult;
    add_liquidity_async : shared AddLiquidityArgs -> async AddLiquidityAsyncResult;
    add_pool : shared AddPoolArgs -> async AddPoolResult;
    add_token : shared AddTokenArgs -> async AddTokenResult;
    check_pools : shared () -> async CheckPoolsResult;
    get_requests : shared query (?Nat64, ?Nat32) -> async RequestsResult;
    get_transfers : shared query ?Nat64 -> async TransfersResult;
    get_txs : shared query (?Nat64, ?Nat32) -> async TxsResult;
    get_user : shared query () -> async UserResult;
    icrc1_name : shared query () -> async Text;
    icrc28_trusted_origins : shared () -> async Icrc28TrustedOriginsResponse;
    messages : shared query ?Nat64 -> async MessagesResult;
    pools : shared query ?Text -> async PoolsResult;
    remove_liquidity : shared RemoveLiquidityArgs -> async RemoveLiquidityResult;
    remove_liquidity_amounts : shared query (
        Text,
        Text,
        Nat,
      ) -> async RemoveLiquidityAmountsResult;
    remove_liquidity_async : shared RemoveLiquidityArgs -> async RemoveLiquidityAsyncResult;
    requests : shared query ?Nat64 -> async RequestsResult;
    send : shared SendArgs -> async SendResult;
    swap : shared SwapArgs -> async SwapResult;
    swap_amounts : shared query (Text, Nat, Text) -> async SwapAmountsResult;
    swap_async : shared SwapArgs -> async SwapAsyncResult;
    tokens : shared query ?Text -> async TokensResult;
    txs : shared query ?Bool -> async TxsResult;
    user_balances : shared query ?Text -> async UserBalancesResult;
    validate_add_liquidity : shared () -> async ValidateAddLiquidityResult;
  }
}