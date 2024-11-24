import Error "mo:base/Error";

module {
    public type DepositArgs = {
        fee : Nat;
        token : Text;
        amount : Nat;
    };
    public type WithdrawArgs = {
        fee : Nat;
        token : Text;
        amount : Nat;
    };
    public type SwapArgs = {
        amountIn : Text;
        zeroForOne : Bool;
        amountOutMinimum : Text;
    };

    public type Result = { #ok : Nat; #err : CustomError };

    public type CustomError = {
        #CommonError;
        #InternalError : Text;
        #UnsupportedToken : Text;
        #InsufficientFunds;
    };

    public type Result_7 = {
        #ok : { balance0 : Nat; balance1 : Nat };
        #err : CustomError;
    };

    public type Result_8 = {
        #ok : Nat;
        #err : CustomError;
    };

    public type Self = actor {
        deposit : shared DepositArgs -> async Result;
        swap : shared SwapArgs -> async Result;
        withdraw : shared WithdrawArgs -> async Result;
    };
};
