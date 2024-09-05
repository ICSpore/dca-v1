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
import Map "mo:map/Map";
import { phash } "mo:map/Map";
import { DAY; MINUTE; WEEK } "mo:time-consts";

import I "./ICSwap";
import L "./Ledger";
import Types "types";

actor class DCA() = self {
    // DCA Types
    type Result<A, B> = Types.Result<A, B>;
    type PositionId = Types.PositionId;
    type Position = Types.Position;
    type TimerActionType = Types.TimerActionType;
    type Frequency = Types.Frequency;

    // Create HashMap to store a positions
    stable let positionsLedger = Map.new<Principal, [Position]>();

    // Timers vars
    var globalTimerId: Nat = 0;
    var actualWorker: ?Principal = null;

    // Trade vars
    let defaultSlippageInPercent: Float = 0.5;

    // Create ICP Ledger actor
    let Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai") : actor {
        icrc1_transfer : shared L.TransferArg -> async L.Result<>;
        icrc2_approve : shared L.ApproveArgs -> async L.Result_1<>;
        icrc2_transfer_from : shared L.TransferFromArgs -> async L.Result_2<>;
        icrc1_balance_of : shared query L.Account -> async Nat;
    };

    // Create ckBTC Ledger actor
    let ckBtcLedger = actor ("mxzaz-hqaaa-aaaar-qaada-cai") : actor {
        icrc1_transfer : shared L.TransferArg -> async L.Result<>;
        icrc2_approve : shared L.ApproveArgs -> async L.Result_1<>;
        icrc2_transfer_from : shared L.TransferFromArgs -> async L.Result_2<>;
        icrc1_balance_of : shared query L.Account -> async Nat;
    };

    // Create ICPSwap ICP/ckBTC pool actor
    let ICPBTCpool = actor ("xmiu5-jqaaa-aaaag-qbz7q-cai") : actor {
        deposit : shared (I.DepositArgs) -> async I.Result;
        depositFrom : shared (I.DepositArgs) -> async I.Result;
        swap : shared (I.SwapArgs) -> async I.Result;
        getUserUnusedBalance : shared query (Principal) -> async I.Result_7;
        withdraw : shared (I.WithdrawArgs) -> async I.Result;
        applyDepositToDex : shared (I.DepositArgs) -> async I.Result;
        quote : shared query (I.SwapArgs) -> async I.Result_8;

    };

    // Set allowed worker to execute "executePurchase" method
    let admin = Principal.fromText("klcto-2xe2e-hjit4-wphri-c3ify-wgrjd-jc5c2-pbvjd-gpwdx-ib2ra-hae");

    // Method to create a new position
    public shared ({ caller }) func openPosition(newPosition : Position) : async Result<PositionId, Text> {

        if (newPosition.tokenToBuy != Principal.fromText("mxzaz-hqaaa-aaaar-qaada-cai")) {
            return #err("Not supported token to buy :( Only ckBTC at this moment");
        };

        if (newPosition.tokenToSell != Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai")) {
            return #err("Not supported token to sell :( Only ICP at this moment");
        };

        if (newPosition.purchasesLeft == 0) {
            return #err("You need to set at least 1 purchase");
        };

        let currentPositions: [Position] = switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) {
                // Create new Array if it does not exist
                [];
            };
            case (?positions) {
                // Use existing Array if it exists
                positions;
            };
        };
        let updatedPositions: [Position] = Array.append<Position>(currentPositions, [newPosition]);

        // Save the Array to the Map
        ignore Map.put<Principal, [Position]>(positionsLedger, phash, caller, updatedPositions);
        Debug.print("[INFO]: User " # debug_show(caller) # " created new position: " # debug_show(newPosition));
        #ok(updatedPositions.size() - 1);
    };

    public shared query ({ caller }) func getAllPositions() : async Result<[Position], Text> {

        switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { 
                return #err("There are no positions available for this user"); 
            };
            case (?positions) {
                if (positions.size() == 0) {
                    return #err("There are no positions available for this user");
                } else {
                    return #ok(positions);
                }
            };
        };
    };

    public shared query ({ caller }) func getPosition(index : Nat) : async Result<Position, Text> {

        switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                // use getOpt for safe getting position by index
                let positionsBuffer = Buffer.fromArray<Position>(positions);
                let position = positionsBuffer.getOpt(index);
                switch (position) {
                    case (null) {
                        return #err("Position does not exist for this index");
                    };
                    case (?position) { return #ok(position) };
                };
            };
        };
    };

    public shared ({ caller }) func closePosition(index : Nat) : async Result<Text, Text> {

        switch (Map.get<Principal, [Position]>(positionsLedger, phash, caller)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                // use getOpt for safe getting position by index
                let positionsBuffer = Buffer.fromArray<Position>(positions);
                let position = positionsBuffer.getOpt(index);
                switch (position) {
                    case (null) {
                        return #err("Position does not exist for this index");
                    };
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

    public shared ({ caller }) func  executePurchase(principal : Principal, index : Nat) : async Result<Text, Text> {
        if (caller != Principal.fromActor(self)){
            return #err("Only DCA canister can execute this method");
        };
        switch (Map.get<Principal, [Position]>(positionsLedger, phash, principal)) {
            case (null) { return #err("There are no positions available for this user") };
            case (?positions) {
                // use getOpt for safe getting position by index
                let positionsBuffer = Buffer.fromArray<Position>(positions);
                let position = positionsBuffer.getOpt(index);
                switch (position) {
                    case (null) {
                        return #err("Position does not exist for this index");
                    };
                    case (?position) {
                        // Perform the multi-stage purchase
                        let purchaseResult = await _performMultiStagePurchase(position);
                        Debug.print("[INFO]: User " # debug_show(principal) # " executed position with result: " # debug_show(purchaseResult));
                        return purchaseResult;
                    };
                };
            };
        };
    };

    private func _getBalance0(principal: Principal) : async Nat {
        let result = await ICPBTCpool.getUserUnusedBalance(principal);
        switch (result) {
            case (#ok(record)) {
                return record.balance0;
            };
            case (#err(_)) {
                return 0;
            };
        };
    };

    private func _performMultiStagePurchase(position : Position) : async Result<Text, Text> {
        // Perform the multi-stage purchase
        let transferResult = await Ledger.icrc2_transfer_from({
            to = {
                owner = Principal.fromActor(self);
                subaccount = null;
            };
            fee = ?10_000;
            spender_subaccount = null;
            from = {
                owner = position.beneficiary;
                subaccount = null;
            };
            memo = null;
            created_at_time = null;
            amount = position.amountToSell - 10_000;
        });
        switch transferResult {
            case (#Err(error)) {
                return #err("Error while transferring ICP to DCA " # debug_show(error));
            };
            case (#Ok(value)) {
                let poolDepositResult = await ICPBTCpool.depositFrom({
                    fee = 10_000;
                    token = Principal.toText(position.tokenToSell);
                    amount = position.amountToSell;
                });
                switch poolDepositResult {
                    case (#err(error)) {
                        return #err("Error while depositing ICP to pool " # debug_show(error));
                    };
                    case (#ok(value)) {
                        let amountOutMinimum = await _getAmountOutMinimum(position.amountToSell);
                        let swapPoolResult = await ICPBTCpool.swap({
                            amountIn = Nat.toText(position.amountToSell);
                            zeroForOne = false;
                            amountOutMinimum = Int.toText(amountOutMinimum);
                        });
                        switch swapPoolResult {
                            case (#err(error)) {
                                return #err("Error while swaping ICP to ckBTC in ICPSwap " # debug_show(error));
                            };
                            case (#ok(value)) {
                                Debug.print("[INFO]: DEX Swap result value: " # debug_show(value));
                                let balance0Result = await _getBalance0(Principal.fromActor(self));
                                let withdrawResult = await ICPBTCpool.withdraw({
                                    amount = balance0Result;
                                    fee = 10; // Default ckBTC fee
                                    token = Principal.toText(position.tokenToBuy);
                                });
                                switch withdrawResult {
                                    case (#err(error)) {
                                        return #err("Error while withdrawing ckBTC from pool " # debug_show(error)) ;
                                    };
                                    case (#ok(value)) {
                                        let previousStepFee = 10; // Default ckBTC fee
                                        let amountToSend = balance0Result - previousStepFee;
                                        let sendCkBtcResult = await _sendCkBTC(position.beneficiary, amountToSend, null);
                                        switch sendCkBtcResult {
                                            case (#err(error)) {
                                                return #err("Error while transferring ckBTC to beneficiary " # debug_show(error) # "Trying to send: " # Nat.toText(amountToSend));
                                            };
                                            case (#ok(value)) {
                                                Debug.print("[INFO]: Position successfully executed, ckBTC: " # debug_show(amountToSend));
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

    private func _principalToBlob(p : Principal) : Blob {
        var arr : [Nat8] = Blob.toArray(Principal.toBlob(p));
        var defaultArr : [var Nat8] = Array.init<Nat8>(32, 0);
        defaultArr[0] := Nat8.fromNat(arr.size());
        var ind : Nat = 0;
        while (ind < arr.size() and ind < 32) {
            defaultArr[ind + 1] := arr[ind];
            ind := ind + 1;
        };
        return Blob.fromArray(Array.freeze(defaultArr));
    };


    public shared func depositToICSwap(amount : Nat) : async Result<Nat, L.TransferError> {
        let sendIcpToICSwapResult = await _sendIcp(Principal.fromActor(ICPBTCpool), amount, ?_principalToBlob(Principal.fromActor(self)));
        return sendIcpToICSwapResult;
    };

    public shared func swapICPtockBTC(amount : Text) : async I.Result {
        let swapResult = await ICPBTCpool.swap({
            amountIn = amount;
            zeroForOne = false;
            amountOutMinimum = "0";
        });
        return swapResult;
    };

    public shared func applyDepositToDex(amount : Nat, token : Text) : async I.Result {
        await ICPBTCpool.deposit({
            amount = amount;
            fee = 10_000;
            token = token;
        });
    };

    public shared func withdrawFromICPSwap(amount : Nat, token : Text) : async I.Result {
        await ICPBTCpool.withdraw({
            amount = amount;
            fee = 10;
            token = token;
        });
    };

    // only for Development

    private func _getAmountOutMinimum (amountIn: Nat): async Int{
        let quote = await ICPBTCpool.quote({
            amountIn = Nat.toText(amountIn);
            amountOutMinimum = "0";
            zeroForOne = false;
        });
        switch (quote) {
            case (#ok(value)) {
                let slippage = Float.fromInt(value) * defaultSlippageInPercent / 100.0;
                return value - Float.toInt(slippage);
            };
            case (#err(error)) {
                return 0;
            };
        };
    };

    public shared ({ caller }) func withdraw(amount : Nat, address : Principal) : async Result<Nat, L.TransferError> {
        assert caller == admin;
        await _sendIcp(address, amount, null);
    };

    private func _sendIcp(address : Principal, amount : Nat, subaccount : ?Blob) : async Result<Nat, L.TransferError> {
        Debug.print("Sending ICP to:" # Principal.toText(address));

        // Transfer from this Canister to an address
        let icp_reciept = await Ledger.icrc1_transfer({
            amount = amount;
            to = { owner = address; subaccount = subaccount };
            from_subaccount = null;
            memo = null;
            fee = ?10_000; // default ICP fee
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        });

        switch icp_reciept {
            case (#Err(error)) {
                return #err(error);
            };
            case (#Ok(value)) {
                return #ok(value);
            };
        };
    };

    private func _sendCkBTC(address : Principal, amount : Nat, subaccount : ?Blob) : async Result<Nat, L.TransferError> {
        Debug.print("Sending ckBTC to:" # Principal.toText(address));

        // Transfer from this Canister to an address
        let ckBtcReciept = await ckBtcLedger.icrc1_transfer({
            amount = amount;
            to = { owner = address; subaccount = subaccount };
            from_subaccount = null;
            memo = null;
            fee = ?10; // default ckBTC fee
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        });

        switch ckBtcReciept {
            case (#Err(error)) {
                return #err(error);
            };
            case (#Ok(value)) {
                return #ok(value);
            };
        };
    };

    // only for Admin
    public shared ({ caller }) func approve(amount : Nat, to : Principal) : async Result<Nat, L.ApproveError> {
        assert caller == admin;
        await _setApprove(amount, to);
    };

    public shared ({ caller }) func getGlobalTimerId() : async Nat {
        assert caller == admin;
        globalTimerId;
    };

    public func getWorker() : async ?Principal {
        actualWorker;
    };

    public shared ({ caller }) func getDCAUnusedBalance(principal: Principal) : async Result<Text, Text> {
        assert caller == admin;
        let result = await ICPBTCpool.getUserUnusedBalance(principal);
        switch (result) {
            case (#ok {balance0; balance1}) {
                return #ok("ckBTC: " #Nat.toText(balance0) # " ICP: " #Nat.toText(balance1));
            };
            case (#err(_)) {
                return #err("Error while getting balance");
            };
        };
    };


    private func _setApprove(ammountToSell : Nat, to : Principal) : async Result<Nat, L.ApproveError> {

        let approve = await Ledger.icrc2_approve({
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

    // Timers methods and automation logic flow

    private func _getTimestampFromFrequency(frequency : Frequency) : Time.Time {
        switch (frequency) {
            case (#TenMinutes) {
                MINUTE * 10;
            };
            case (#Daily) {
                DAY;
            };
            case (#Weekly) {
                WEEK;
            };
            case (#Monthly) {
                WEEK * 4;
            };
        };
    };

    private func _checkAndExecutePositions() : async () {
        Debug.print("Checking and executing positions");
        let entries = Map.entries(positionsLedger);
        let currentTime = Time.now();

        // Iterate over all users
        for ((user, positionsArray) in entries) {
            let updatedPositions: Buffer.Buffer<Position> = Buffer.Buffer<Position>(0);
            var updatesMade: Bool = false;

            // Iterate over all positions
            for (positionId in Iter.range(0, positionsArray.size() - 1)) {
                let position: Position = positionsArray[positionId];

                if (currentTime >= Option.get(position.nextRunTime, 0) and position.purchasesLeft > 0) {
                    // Call executePurchase with the correct positionId
                    let purchaseResult = await executePurchase(user, positionId);
                    let newNextRunTime = currentTime + _getTimestampFromFrequency(position.frequency);

                    let updatedHistory: [Result<Text, Text>] = switch (position.purchaseHistory) {
                        // If history exists, append the new result
                        case (?existingHistory) {
                            Array.append(existingHistory, [purchaseResult]);
                        };
                        // If history does not exist, create a new one
                        case null {
                            [purchaseResult];
                        };
                    };

                    // Create a new position state
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
                    // If no purchase was made, keep the position as is
                    updatedPositions.add(position);
                    };
            };

            // If any updates were made, convert Buffer back to Array and update the map
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

    // In order to restart timers after the canister upgrade
    system func postupgrade() {
        let timerId = Timer.recurringTimer<system>(((#nanoseconds (MINUTE * 3)), _checkAndExecutePositions));
        globalTimerId := timerId;
        Debug.print("Postupgrade Timer started: " # debug_show(timerId));
    };
};