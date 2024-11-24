import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import { thash } "mo:map/Map";
import Map "mo:map/Map";
import Text "mo:base/Text";

import I "./ICPSwap";
import Types "types";
import Ledger "Ledger";


module DynamicPoolCreator = {

    type IcpSwapPoolActor = Types.IcpSwapPoolActor;
    type IcpSwapPoolProperties = Types.IcpSwapPoolProperties;
    type SwapArgs = I.SwapArgs;
    type Result = I.Result;
    type Ledger = Types.Ledger;
    type IcpSwapDynamicSwapProperties = Types.IcpSwapDynamicSwapProperties;
    type TokenPair = Types.TokenPair;

    // Constants for token principals
    private let ICP_PRINCIPAL = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    private let CKBTC_PRINCIPAL = "mxzaz-hqaaa-aaaar-qaada-cai";
    private let CKETH_PRINCIPAL = "ss2fx-dyaaa-aaaar-qacoq-cai";
    private let CKUSDC_PRINCIPAL = "xevnm-gaaaa-aaaar-qafnq-cai";
    private let CKUSDT_PRINCIPAL = "cngnf-vqaaa-aaaar-qag4a-cai";

    // Helper function to get Principal ID from ticker
    public func principalIdFromTokenTicker(ticker: Text) : Text {
        switch (ticker) {
            case ("ICP") { ICP_PRINCIPAL };
            case ("ckBTC") { CKBTC_PRINCIPAL };
            case ("ckETH") { CKETH_PRINCIPAL };
            case ("ckUSDC") { CKUSDC_PRINCIPAL };
            case ("ckUSDT") { CKUSDT_PRINCIPAL };
            case (_) { "" }; // Return empty string for unknown tickers
        };
    };

    // Helper function to get token ticker from Principal ID
    public func tokenTickerFromPrincipalId(principalId: Text) : Text {
        if (principalId == ICP_PRINCIPAL) { "ICP" }
        else if (principalId == CKBTC_PRINCIPAL) { "ckBTC" }
        else if (principalId == CKETH_PRINCIPAL) { "ckETH" }
        else if (principalId == CKUSDC_PRINCIPAL) { "ckUSDC" }
        else if (principalId == CKUSDT_PRINCIPAL) { "ckUSDT" }
        else { "" };
    };

    // Функция для формирования ключа
    public func makeKey(tokenA : Text, tokenB : Text) : Text {
        // Конкатенируем нормализованные названия токенов с разделителем, например, "_"
        return tokenA # "_" # tokenB;
    };

    // Универсальный метод для получения конфигов для динамического пула и леджера
    public func getIcpSwapDynamicSwapProperties(poolMap : Map.Map<Text, IcpSwapPoolProperties>, tokenToSell : Text, tokenToBuy : Text) : ?IcpSwapDynamicSwapProperties {

        let key : Text = makeKey(tokenToSell, tokenToBuy);  
        Debug.print("[INFO]: Key for pool map: " # key);      

        // Ищем пул для пары токенов
        switch (Map.get<Text, IcpSwapPoolProperties>(poolMap, thash, key)) {
            case (?poolProperties) {

                Debug.print("[INFO]: Pool principal ID " # debug_show(poolProperties.poolPrincipalId));
                // Create a new IcpSwapPoolActor instance
                let poolPrincipalId: Text = poolProperties.poolPrincipalId;
                let poolActor = actor (poolPrincipalId) : IcpSwapPoolActor;

                let tokenToSellPrincipalId: Text = principalIdFromTokenTicker(tokenToSell);
                let tokenToBuyPrincipalId: Text = principalIdFromTokenTicker(tokenToBuy);

                Debug.print("[getIcpSwapDynamicSwapProperties INFO]: Token to sell principal ID " # tokenToSellPrincipalId);
                Debug.print("[getIcpSwapDynamicSwapProperties INFO]: Token to buy principal ID " # tokenToBuyPrincipalId);
                
                // Create a new Ledger instances
                let tokenToSellLedger = actor (tokenToSellPrincipalId): Ledger;
                let tokenToBuyLedger = actor (tokenToBuyPrincipalId): Ledger;

                // Create a new IcpSwapDynamicSwapProperties instance
                return ?{
                    dynamicPool = poolActor;
                    tokenToSellLedgerFee = poolProperties.tokenToSellLedgerFee;
                    tokenToBuyLedgerFee = poolProperties.tokenToBuyLedgerFee;
                    tokenToSellLedger = tokenToSellLedger;
                    tokenToBuyLedger = tokenToBuyLedger;
                };
            };
            case null {
                // Пул не найден
                Debug.print("[INFO]: Pool not found for token pair: " # tokenToSell # " -> " # tokenToBuy);
                null;
            };
        };
    };

    private func _getDynamicQuote(poolMap : Map.Map<Text, IcpSwapPoolProperties>, tokenA : Text, tokenB : Text, amountIn : Text, zeroForOne : Bool) : async ?IcpSwapDynamicSwapProperties {
        let dynamicSwapProperties: ?IcpSwapDynamicSwapProperties = getIcpSwapDynamicSwapProperties(poolMap, tokenA, tokenB);
        // let dynamicPool = dynamicSwapProperties.dynamicPool;
        switch (dynamicSwapProperties) {
            case (?dynamicSwapProperties) {
                let pool = dynamicSwapProperties.dynamicPool;
                let quoteResult = await pool.quote({
                    amountIn = amountIn;
                    zeroForOne = zeroForOne;
                    amountOutMinimum = "0";
                });
                Debug.print("Quote result: " # debug_show(quoteResult));
                ?dynamicSwapProperties;
            };
            case null {
                Debug.print("Pool not found for token pair: " # tokenA # " -> " # tokenB);
                return
                null;
            };
        };

    };

};
