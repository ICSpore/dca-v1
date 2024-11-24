import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import I "./ICPSwap";
import L "./Ledger";
import K "./KongSwap";
module {

    public type Result<A, B> = {
        #ok : A;
        #err : B;
    };

    // Define the structure of a error
    public type Error = {
        #InvalidDex: Text;
        #QuoteFailed: Text;
        #InsufficientLiquidity;
        #ExcessiveSlippage;
        #Other: Text;
    };

    // Define the structure of a position
    public type Position = {
        beneficiary : Principal;
        amountToSell : Nat;
        tokenToBuy : Principal;
        tokenToSell : Principal;
        frequency : Frequency;
        purchasesLeft : Int;
        nextRunTime: ?Time.Time;
        lastPurchaseResult: ?Result<Text, Text>;
        purchaseHistory: ?[Result<Text, Text>];
    };
    // Define the structure of a timer
    public type Frequency = {
        #TenMinutes;
        #Daily;
        #Weekly;
        #Monthly;
    };

    public type PositionId = Nat;

    // Define the helpfull types for the timer actions
    public type TimerActionType = {
        #StartTimer;
        #StopTimer;
    };

    // Define the structure of a PoolProperties objcet
    public type IcpSwapPoolProperties = {
        poolPrincipalId: Text;
        tokenToSellLedgerFee: Nat;
        tokenToBuyLedgerFee: Nat;
    };

    public type Ledger = actor {
        icrc1_transfer : shared L.TransferArg -> async L.Result<>;
        icrc2_approve : shared L.ApproveArgs -> async L.Result_1<>;
        icrc2_transfer_from : shared L.TransferFromArgs -> async L.Result_2<>;
        icrc1_balance_of : shared query L.Account -> async Nat;
    };

    public type KongSwapPoolActor = actor {
        swap : shared K.SwapArgs -> async K.SwapResult;
        swap_amounts : shared query (Text, Nat, Text) -> async K.SwapAmountsResult;
    };

    public type IcpSwapPoolActor = actor {
        deposit : shared (I.DepositArgs) -> async I.Result;
        depositFrom : shared (I.DepositArgs) -> async I.Result;
        swap : shared (I.SwapArgs) -> async I.Result;
        getUserUnusedBalance : shared query (Principal) -> async I.Result_7;
        withdraw : shared (I.WithdrawArgs) -> async I.Result;
        applyDepositToDex : shared (I.DepositArgs) -> async I.Result;
        quote : shared query (I.SwapArgs) -> async I.Result_8;
    };

    public type IcpSwapDynamicSwapProperties = {
        dynamicPool: IcpSwapPoolActor;
        tokenToSellLedgerFee: Nat;
        tokenToBuyLedgerFee: Nat;
        tokenToSellLedger: Ledger;
        tokenToBuyLedger: Ledger;
    };

    public type TokenPair = (Text, Text);

    // Добавить типы для работы с агрегатором
    public type DexInfo = {
        name: Text;
        backendCanisterId: Principal; 
    };

    public type QuoteResponse = {
        dexName: Text;
        inputAmount: Nat;
        outputAmount: Int;
    };

    public type SwapArgs = {
        pay_token: Text;
        receive_token: Text;
        pay_amount: Nat;
        max_slippage: ?Float;
        receive_amount: ?Nat;
        receive_address: ?Text;
        referred_by: ?Text;
        pay_tx_id: ?Nat;
    };

    public type SwapResult = {
        pay_token: Text;
        receive_token: Text;
        pay_amount: Nat;
        receive_amount: Nat;
    };

};