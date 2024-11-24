import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Error "mo:base/Error";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import { DAY; MINUTE; WEEK } "mo:time-consts";

import I "./ICPSwap";
import L "./Ledger";
import Types "types";
import DPC "./DynamicPoolCreator";
import K "./KongSwap";
import { tokenTickerFromPrincipalId } "./DynamicPoolCreator"

actor class DCA() = self {
    // DCA Types
    type Result<A, B> = Types.Result<A, B>;
    type PositionId = Types.PositionId;
    type Position = Types.Position;
    type TimerActionType = Types.TimerActionType;
    type Frequency = Types.Frequency;
    type IcpSwapDynamicSwapProperties = Types.IcpSwapDynamicSwapProperties;

    // DEX Types
    type DexInfo = Types.DexInfo;
    type QuoteResponse = Types.QuoteResponse;
    type IcpSwapPoolProperties = Types.IcpSwapPoolProperties;
    type IcpSwapPoolActor = Types.IcpSwapPoolActor;
    type KongSwapPoolActor = Types.KongSwapPoolActor;
    type SwapArgs = K.SwapArgs;
    type SwapResult = K.SwapResult;
    type Ledger = Types.Ledger;
    type Error = Types.Error;

    // Create HashMap to store positions
    stable let positionsLedger = Map.new<Principal, [Position]>();

    // Create HashMap to store ICPSwap pool configurations
    private let icpSwapPoolMap = Map.new<Text, IcpSwapPoolProperties>();

    private let kongSwapActor = actor("2ipq2-uqaaa-aaaar-qailq-cai"): KongSwapPoolActor;

    // Create HashMap to store DEX configurations
    private let dexMap = Map.new<Text, DexInfo>();

    // Timers vars
    var globalTimerId: Nat = 0;
    var actualWorker: ?Principal = null;

    // Trade vars
    let defaultSlippageInPercent: Float = 0.5;

    // Set allowed worker to execute "executePurchase" method
    let admin = Principal.fromText("hfugy-ahqdz-5sbki-vky4l-xceci-3se5z-2cb7k-jxjuq-qidax-gd53f-nqe");

    // Initialize pool configurations
    private func initPoolConfigs() {
        // Initialize pool configurations
        let icpCkBtcPool: IcpSwapPoolProperties = {
            poolPrincipalId = "xmiu5-jqaaa-aaaag-qbz7q-cai";
            tokenToSellLedgerFee = 10_000; // ICP fee
            tokenToBuyLedgerFee = 10; // ckBTC fee
        };
        ignore Map.put(icpSwapPoolMap, thash, DPC.makeKey("ICP", "ckBTC"), icpCkBtcPool);

        // ICP/ckETH pool
        let icpCkEthPool: IcpSwapPoolProperties = {
            poolPrincipalId = "angxa-baaaa-aaaag-qcvnq-cai";
            tokenToSellLedgerFee = 10_000; // ICP fee
            tokenToBuyLedgerFee = 2_000_000_000_000; // ckETH fee 140_000
        };
        ignore Map.put(icpSwapPoolMap, thash, DPC.makeKey("ICP", "ckETH"), icpCkEthPool);

        // ckUSDC/ICP pool
        let icpUsdcPool: IcpSwapPoolProperties = {
            poolPrincipalId = "mohjv-bqaaa-aaaag-qjyia-cai";
            tokenToBuyLedgerFee = 10_000; // ckUSDC fee
            tokenToSellLedgerFee = 10_000; // ICP fee
        };
        ignore Map.put(icpSwapPoolMap, thash, DPC.makeKey("ICP", "ckUSDC"), icpUsdcPool);

        // ckUSDT/ICP pool
        let icpUsdtPool: IcpSwapPoolProperties = {
            poolPrincipalId = "hkstf-6iaaa-aaaag-qkcoq-cai";
            tokenToSellLedgerFee = 10_000; // ckUSDT fee
            tokenToBuyLedgerFee = 10_000; // ICP fee
        };
        ignore Map.put(icpSwapPoolMap, thash, DPC.makeKey("ICP", "ckUSDT"), icpUsdtPool);

        Debug.print("[INFO]: Pool configurations initialized");
    };

    // Method to create a new position
    public shared ({ caller }) func openPosition(newPosition : Position) : async Result<PositionId, Text> {
        // Validate token pair exists in pool configurations

        let tokenToSellTicker: Text = tokenTickerFromPrincipalId(Principal.toText(newPosition.tokenToSell));
        let tokenToBuyTicker: Text = tokenTickerFromPrincipalId(Principal.toText(newPosition.tokenToBuy));

        let key = DPC.makeKey(tokenToSellTicker, tokenToBuyTicker);
        switch (Map.get(icpSwapPoolMap, thash, key)) {
            case null { return #err("Unsupported token pair: KEY - " # debug_show(key)) };
            case (?_) {};
        };

        if (newPosition.purchasesLeft == 0) {
            return #err("You need to set at least 1 purchase");
        };

        let currentPositions: [Position] = switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { [] };
            case (?positions) { positions };
        };
        let updatedPositions: [Position] = Array.append<Position>(currentPositions, [newPosition]);

        ignore Map.put<Principal, [Position]>(positionsLedger, phash, caller, updatedPositions);
        Debug.print("[INFO]: User " # debug_show(caller) # " created new position: " # debug_show(newPosition));
        #ok(updatedPositions.size() - 1);
    };

    public shared query ({ caller }) func getAllPositions() : async Result<[Position], Text> {
        switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                if (positions.size() == 0) {
                    return #err("There are no positions available for this user");
                } else {
                    return #ok(positions);
                };
            };
        };
    };

    public shared query ({ caller }) func getPosition(index : Nat) : async Result<Position, Text> {
        switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                let positionsBuffer = Buffer.fromArray<Position>(positions);
                let position = positionsBuffer.getOpt(index);
                switch (position) {
                    case (null) { return #err("Position does not exist for this index") };
                    case (?position) { return #ok(position) };
                };
            };
        };
    };

    public shared ({ caller }) func closePosition(index : Nat) : async Result<Text, Text> {
        switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                let positionsBuffer = Buffer.fromArray<Position>(positions);
                let position = positionsBuffer.getOpt(index);
                switch (position) {
                    case (null) { return #err("Position does not exist for this index") };
                    case (?position) {
                        ignore positionsBuffer.remove(index);
                        let updatedPositions = Buffer.toArray<Position>(positionsBuffer);
                        ignore Map.put<Principal, [Position]>(positionsLedger, phash, caller, updatedPositions);
                        Debug.print("[INFO]: User " # debug_show(caller) # " deleted position: " # debug_show(position));
                        return #ok("Position deleted");
                    };
                };
            };
        };
    };

    public shared ({ caller }) func executePurchase(principal : Principal, index : Nat) : async Result<Text, Text> {
        if (caller != Principal.fromActor(self)) {
            return #err("Only DCA canister can execute this method");
        };
        switch (Map.get<Principal, [Position]>(positionsLedger, phash, principal)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                let positionsBuffer = Buffer.fromArray<Position>(positions);
                let position = positionsBuffer.getOpt(index);
                switch (position) {
                    case (null) { return #err("Position does not exist for this index") };
                    case (?position) {
                        let purchaseResult = await _performAggregatorPurchase(position);
                        Debug.print("[INFO]: User " # debug_show(principal) # " executed position with result: " # debug_show(purchaseResult));
                        return purchaseResult;
                    };
                };
            };
        };
    };
    // KongSwap method for perform purchase
    private func _executeKongSwapPurchase(position : Position) : async Result<Text, Text> {            
        // Construct proper SwapArgs
        let swapArgs : SwapArgs = {
            pay_token = tokenTickerFromPrincipalId(Principal.toText(position.tokenToSell));
            receive_token = tokenTickerFromPrincipalId(Principal.toText(position.tokenToBuy));
            pay_amount = position.amountToSell;
            max_slippage = ?0.01; // 1% slippage
            receive_amount = null;
            receive_address = ?Principal.toText(position.beneficiary);
            referred_by = null;
            pay_tx_id = null;
        };

        let swapResult = await kongSwapActor.swap(swapArgs);
        Debug.print("[INFO]: KongSwap swap result: " # debug_show(swapResult));
        
        switch (swapResult) {
            case (#Ok(value)) {
                #ok(Nat.toText(value.receive_amount))
            };
            case (#Err(error)) {
                #err("KongSwap swap failed: " # error)
            };
        };
    };
    // ICPSwap method for performing multi-stage purchase
    private func _executeIcpSwapPurchase(position : Position) : async Result<Text, Text> {
        let tokenToSell: Text = tokenTickerFromPrincipalId(Principal.toText(position.tokenToSell));
        let tokenToBuy: Text = tokenTickerFromPrincipalId(Principal.toText(position.tokenToBuy));
        
        // Get dynamic swap properties for the token pair
        let dynamicSwapProperties = DPC.getIcpSwapDynamicSwapProperties(icpSwapPoolMap, tokenToSell, tokenToBuy);
        
        switch (dynamicSwapProperties) {
            case (null) { return #err("[ERROR]: Failed to get swap properties for token pair") };
            case (?swapProps) {
                // Transfer tokens from user to DCA canister
                let transferResult = await swapProps.tokenToSellLedger.icrc2_transfer_from({
                    to = {
                        owner = Principal.fromActor(self);
                        subaccount = null;
                    };
                    fee = ?swapProps.tokenToSellLedgerFee;
                    spender_subaccount = null;
                    from = {
                        owner = position.beneficiary;
                        subaccount = null;
                    };
                    memo = null;
                    created_at_time = null;
                    amount = position.amountToSell - swapProps.tokenToSellLedgerFee;
                });
                Debug.print("[INFO]: Trying to transfer tokens from Benefetiary to DCA");
                Debug.print("[INFO]: Token: " # debug_show(position.tokenToSell) # " Amount: " # debug_show(position.amountToSell - swapProps.tokenToSellLedgerFee));

                switch transferResult {
                    case (#Err(error)) {
                        return #err("[ERROR]: Error while transferring tokens to DCA " # debug_show(error));
                    };
                    case (#Ok(_)) {
                        // Deposit tokens to pool
                        let poolDepositResult = await swapProps.dynamicPool.depositFrom({
                            fee = swapProps.tokenToSellLedgerFee;
                            token = Principal.toText(position.tokenToSell);
                            amount = position.amountToSell;
                        });
                        Debug.print("[INFO]: Deposit result: " # debug_show(poolDepositResult));
                        switch poolDepositResult {
                            case (#err(error)) {
                                return #err("[ERROR]: Error while depositing tokens to pool " # debug_show(error));
                            };
                            case (#ok(_)) {
                                let amountOutMinimum = await _getAmountOutMinimum(swapProps.dynamicPool, position.amountToSell);
                                Debug.print("[INFO]: Amount out minimum: " # debug_show(amountOutMinimum));
                                let swapPoolResult = await swapProps.dynamicPool.swap({
                                    amountIn = Nat.toText(position.amountToSell);
                                    zeroForOne = false;
                                    amountOutMinimum = Int.toText(amountOutMinimum);
                                });

                                switch swapPoolResult {
                                    case (#err(error)) {
                                        return #err("[ERROR]: Error while swapping tokens in ICPSwap " # debug_show(error));
                                    };
                                    case (#ok(value)) {
                                        Debug.print("[INFO]: DEX Swap result value: " # debug_show(value));
                                        let balanceResult = await swapProps.dynamicPool.getUserUnusedBalance(Principal.fromActor(self));
                                        
                                        switch (balanceResult) {
                                            case (#err(error)) {
                                                return #err("[ERROR]: Error while getting balance " # debug_show(error));
                                            };
                                            case (#ok { balance0; balance1 }) {
                                                Debug.print("[INFO]: Balance0: " # debug_show(balance0) # " Balance1: " # debug_show(balance1));
                                                let withdrawResult = await swapProps.dynamicPool.withdraw({
                                                    amount = balance0;
                                                    fee = swapProps.tokenToBuyLedgerFee;
                                                    token = Principal.toText(position.tokenToBuy);
                                                });
                                                Debug.print("[INFO]: Trying to withdraw tokens from pool");
                                                switch withdrawResult {
                                                    case (#err(error)) {
                                                        return #err("[ERROR]: Error while withdrawing tokens from pool " # debug_show(error));
                                                    };
                                                    case (#ok(value)) {
                                                        Debug.print("[INFO]: Trying to transfer tokens to beneficiary");
                                                        let amountToSend = balance0 - swapProps.tokenToBuyLedgerFee;
                                                        let sendResult = await swapProps.tokenToBuyLedger.icrc1_transfer({
                                                            amount = amountToSend;
                                                            to = { owner = position.beneficiary; subaccount = null };
                                                            from_subaccount = null;
                                                            memo = null;
                                                            fee = ?swapProps.tokenToBuyLedgerFee;
                                                            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                                                        });

                                                        switch sendResult {
                                                            case (#Err(error)) {
                                                                return #err("[ERROR]: Error while transferring tokens to beneficiary " # debug_show(error));
                                                            };
                                                            case (#Ok(value)) {
                                                                Debug.print("[INFO]: Position successfully executed, amount: " # debug_show(amountToSend));
                                                                return #ok(Nat.toText(amountToSend));
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };

    private func _getAmountOutMinimum(pool: Types.IcpSwapPoolActor, amountIn: Nat): async Int {
        let quote = await pool.quote({
            amountIn = Nat.toText(amountIn);
            amountOutMinimum = "0";
            zeroForOne = false;
        });
        switch (quote) {
            case (#ok(value)) {
                Debug.print("[INFO]: Quote result for input amount: " # debug_show(amountIn) # " : " # debug_show(value));
                let slippage = Float.fromInt(value) * defaultSlippageInPercent / 100.0;
                return value - Float.toInt(slippage);
            };
            case (#err(error)) {
                return 0;
            };
        };
    };

    // Timer methods and automation logic flow
    private func _getTimestampFromFrequency(frequency : Frequency) : Time.Time {
        switch (frequency) {
            case (#TenMinutes) { MINUTE * 10 };
            case (#Daily) { DAY };
            case (#Weekly) { WEEK };
            case (#Monthly) { WEEK * 4 };
        };
    };

    private func _checkAndExecutePositions() : async () {
        Debug.print("Checking and executing positions");
        let entries = Map.entries(positionsLedger);
        let currentTime = Time.now();

        for ((user, positionsArray) in entries) {
            let updatedPositions = Buffer.Buffer<Position>(0);
            var updatesMade = false;

            for (positionId in Iter.range(0, positionsArray.size() - 1)) {
                let position = positionsArray[positionId];

                if (currentTime >= Option.get(position.nextRunTime, 0) and position.purchasesLeft > 0) {
                    let purchaseResult = await executePurchase(user, positionId);
                    let newNextRunTime = currentTime + _getTimestampFromFrequency(position.frequency);

                    let updatedHistory = switch (position.purchaseHistory) {
                        case (?existingHistory) { Array.append(existingHistory, [purchaseResult]) };
                        case null { [purchaseResult] };
                    };

                    let newPosition: Position = {
                        position with
                        purchasesLeft = position.purchasesLeft - 1;
                        nextRunTime = ?newNextRunTime;
                        lastPurchaseResult = ?purchaseResult;
                        purchaseHistory = ?updatedHistory;
                    };
                    updatedPositions.add(newPosition);
                    updatesMade := true;
                } else {
                    updatedPositions.add(position);
                };
            };

            if (updatesMade) {
                ignore Map.put<Principal, [Position]>(positionsLedger, phash, user, Buffer.toArray<Position>(updatedPositions));
            };
        };
    };

    public shared ({ caller }) func editTimer(timerId: Nat, actionType: TimerActionType) : async Result<Text, Text> {
        if (caller != admin) {
            return #err("Only worker can execute this method");
        };
        switch (actionType) {
            case (#StartTimer) {
                let timerId = await _startScheduler();
                Debug.print("Timer: " # debug_show(timerId) # " created");
                globalTimerId := timerId;
                return #ok(Nat.toText(timerId));
            };
            case (#StopTimer) {
                Timer.cancelTimer(timerId);
                Debug.print("Timer: " # debug_show(timerId) # " was deleted");
                return #ok("0");
            };
        };
    };

    private func _startScheduler() : async Nat {
        Timer.recurringTimer<system>(((#nanoseconds (MINUTE * 3)), _checkAndExecutePositions));
    };

    // Initialize pool configurations and restart timers after canister upgrade
    system func postupgrade() {
        initPoolConfigs();
        let timerId = Timer.recurringTimer<system>(((#nanoseconds (MINUTE * 3)), _checkAndExecutePositions));
        globalTimerId := timerId;
        Debug.print("Postupgrade Timer started: " # debug_show(timerId));
    };

    // only for Admin

    private func _setPoolApprove(ledgerPrincipal: Principal, ammountToSell : Nat, to : Principal) : async Result<Nat, L.ApproveError> {

        let ledgerActor = actor (Principal.toText(ledgerPrincipal)): Types.Ledger;

        let approve = await ledgerActor.icrc2_approve({
            amount = ammountToSell;
            created_at_time = null;
            expected_allowance = null;
            expires_at = null;
            fee = null;
            from_subaccount = null;
            memo = null;
            spender = {
                owner = to;
                subaccount = null;
            };
        });
        switch approve {
            case (#Err(error)) {
                return #err(error);
            };
            case (#Ok(value)) {
                return #ok(value);
            };
        };
    };

    public shared ({ caller }) func approve(ledgetPrincipal: Principal, amount : Nat, to : Principal) : async Result<Nat, L.ApproveError> {
        assert caller == admin;
        await _setPoolApprove(ledgetPrincipal, amount, to);
    };

    // Method to view all pool configurations
    public shared query ({ caller }) func getAllPools() : async Result<[(Text, IcpSwapPoolProperties)], Text> {
        if (caller != admin) {
            return #err("Only admin can view pool configurations");
        };

        let entries = Map.entries(icpSwapPoolMap);
        let result = Buffer.Buffer<(Text, IcpSwapPoolProperties)>(0);

        for ((key, properties) in entries) {
            result.add((key, properties));
        };

        Debug.print("[INFO]: Admin requested pool configurations");
        #ok(Buffer.toArray(result));
    };

    public shared func getQuotes(tokenToSell: Text, tokenToBuy: Text, amount: Nat, _slippage: Float) : async Result<[QuoteResponse], Error> {
        var quotes = Buffer.Buffer<QuoteResponse>(0);

        // Try to get ICP Swap quote
        switch (DPC.getIcpSwapDynamicSwapProperties(icpSwapPoolMap, tokenToSell, tokenToBuy)) {
            case (?icpSwapProperties) {
                Debug.print("ICPSwap:pool for pair created");
                try {
                    let icpSwapPoolActor = icpSwapProperties.dynamicPool;
                    let icpSwapQuoteResult = await icpSwapPoolActor.quote({
                        amountIn = Nat.toText(amount);
                        zeroForOne = false;
                        amountOutMinimum = "0";
                    });

                    switch (icpSwapQuoteResult) {
                        case (#ok(quoteValue)) {
                            Debug.print("ICPSwap: Quote value: " # debug_show(quoteValue));
                            quotes.add({
                                dexName = "ICPSwap";
                                inputAmount = amount;
                                outputAmount = quoteValue;
                            });
                        };
                        case (#err(error)) {
                            Debug.print("[ERROR] ICPSwap quote failed: " # debug_show(error));
                            // Continue to next DEX even if this one fails
                        };
                    };
                } catch (e) {
                    Debug.print("[ERROR] ICPSwap quote error: " # Error.message(e));
                    // Continue to next DEX even if this one fails
                };
            };
            case (null) {
                Debug.print("[INFO] No ICPSwap pool found for " # tokenToSell # " -> " # tokenToBuy);
                // Continue to next DEX if no pool found
            };
        };

        // Try to get KongSwap quote
        try {
            let kongSwapQuoteResult = await kongSwapActor.swap_amounts(
                tokenToSell,
                amount,
                tokenToBuy
            );

            switch (kongSwapQuoteResult) {
                case (#Ok(quoteResult)) {
                    Debug.print("KongSwap: Quote value: " # debug_show(quoteResult));
                    quotes.add({
                        dexName = "KongSwap";
                        inputAmount = amount;
                        outputAmount = quoteResult.receive_amount;
                    });
                };
                case (#Err(error)) {
                    Debug.print("[ERROR] KongSwap quote failed: " # error);
                    // Continue even if this DEX fails
                };
            };
        } catch (e) {
            Debug.print("[ERROR] KongSwap quote error: " # Error.message(e));
            // Continue even if this DEX fails
        };

        // Return error if no quotes were obtained
        if (quotes.size() == 0) {
            #err(#QuoteFailed("No quotes available from any DEX"));
        }
        else {
            #ok(Buffer.toArray(quotes));
        };
    };


    public shared func getBestQuote(tokenToSell: Text, tokenToBuy: Text, amount: Nat, slippage: Float) : async Result<QuoteResponse, Error> {
        let quotesResult = await getQuotes(tokenToSell, tokenToBuy, amount, slippage);
        
        switch (quotesResult) {
            case (#err(e)) { #err(e) };
            case (#ok(quotes)) {
                if (quotes.size() == 0) {
                    return #err(#QuoteFailed("No quotes available"));
                };

                var bestQuote = quotes[0];
                for (quote in quotes.vals()) {
                    if (quote.outputAmount > bestQuote.outputAmount) {
                        bestQuote := quote;
                    };
                };
                #ok(bestQuote)
            };
        };
    };

    private func _performAggregatorPurchase(position : Position) : async Result<Text, Text> {

        let bestQuoteResult = await getBestQuote(
            tokenTickerFromPrincipalId(Principal.toText(position.tokenToSell)),
            tokenTickerFromPrincipalId(Principal.toText(position.tokenToBuy)), 
            position.amountToSell,
            0.0
        );

        switch(bestQuoteResult) {
            case (#err(e)) { return #err(debug_show(e)) };
            case (#ok(bestQuote)) {

                switch(bestQuote.dexName) {
                    case ("ICPSwap") {
                        Debug.print("[INFO]: ICPSwap was selected as best quote provider");
                        return await _executeIcpSwapPurchase(position);
                    };
                    case ("KongSwap") {
                        Debug.print("[INFO]: KongSwap was selected as best quote provider");
                        return await _executeKongSwapPurchase(position);
                    };
                    case (_) {
                        return #err("Unknown DEX");
                    };
                };
            };
        };
    };
};
