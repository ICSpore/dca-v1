import React, { useState, useRef, useDebugValue, useEffect } from "react";
import "./WalletInfo.css";
import copyIcon from "../../images/copy-4-svgrepo-com.svg";
import doneIcon from "../../images/checkmark-xs-svgrepo-com.svg";
import icpIcon from "../../images/internet-computer-icp-logo.svg";
import ckBTCIcon from "../../images/ckBTC.svg";
import DropDownList from "../DropDownList/DropDownList";
import BalanceInfo from "../BalanceInfo/BalanceInfo";
import { useAuth } from "../../context/AuthContext";
import { Principal } from "@dfinity/principal";

interface WalletInfoProps {
    principalId: string;
}

const WalletInfo: React.FC<WalletInfoProps> = ({ principalId }) => {
    const { actorLedger, actorCKBTCLedger } = useAuth();

    const [isCopied, setIsCopied] = useState<boolean>(false);
    const [selectedWithdrawToken, setSelectedWithdrawToken] = useState<string | null>(null);
    const amountToWithdrawRef = useRef<HTMLInputElement>(null);
    const [amountToWithdraw, setAmountToWithdraw] = useState<number>(0);
    const [minimumAmountToWithdraw, setMinimumAmountToWithdraw] = useState<number>(0);
    const [fee, setFee] = useState<number>(0);
    const [isFullAmount, setIsFullAmount] = useState<boolean>(false);
    const [balance, setBalance] = useState<number | null>(null);
    const [walletPrincipal, setWalletPrincipal] = useState<string>("");
    const [errorMessage, setErrorMessage] = useState<string | null>(null);
    const [success, setSuccess] = useState<boolean>(false);
    const [isLoading, setIsLoading] = useState<boolean>(false);

    const optionsToWithdraw = [
        { label: "ICP", value: "ICP", icon: <img src={icpIcon} alt="ICP Icon" />, available: true },
        { label: "ckBTC", value: "ckBTC", icon: <img src={ckBTCIcon} alt="ckBTC Icon" />, available: true },
    ];

    useEffect(() => {
        if (selectedWithdrawToken === "ICP") {
            setMinimumAmountToWithdraw(0.00010001);
            setFee(0.0001);
        } else if (selectedWithdrawToken === "ckBTC") {
            setMinimumAmountToWithdraw(0.00000011);
            setFee(0.0000001);
        } else {
            setMinimumAmountToWithdraw(0);
        }
    }, [selectedWithdrawToken]);

    useEffect(() => {
        const isButtonDisabled =
            !selectedWithdrawToken || // Не выбран токен
            !amountToWithdraw || // Сумма не заполнена
            amountToWithdraw < minimumAmountToWithdraw || // Сумма меньше минимальной
            !walletPrincipal; // Principal ID не заполнен
    }, [walletPrincipal, amountToWithdraw, selectedWithdrawToken, minimumAmountToWithdraw]);

    const handleGetBalance = (newBalance: number | null) => {
        setBalance(newBalance);
        if (isFullAmount && newBalance !== null) {
            setAmountToWithdraw(newBalance);
        }
    };

    const withdraw = async () => {
        setIsLoading(true);
        setErrorMessage(null);

        if (selectedWithdrawToken) {
            try {
                let transferResult;
                if (selectedWithdrawToken === "ICP" && actorLedger) {
                    let amountToTransfer;
                    if (isFullAmount) {
                        amountToTransfer = BigInt(amountToWithdraw * 100000000 - fee);
                    } else if (!isFullAmount) {
                        amountToTransfer = BigInt(amountToWithdraw * 100000000);
                    }
                    transferResult = await actorLedger.icrc1_transfer({
                        to: { owner: Principal.fromText(walletPrincipal), subaccount: [] },
                        fee: [BigInt(10000)],
                        memo: [],
                        from_subaccount: [],
                        created_at_time: [],
                        amount: amountToTransfer,
                    });
                } else if (selectedWithdrawToken === "ckBTC" && actorCKBTCLedger) {
                    const amountToTransfer = BigInt(amountToWithdraw * 100000000);
                    transferResult = await actorCKBTCLedger.icrc1_transfer({
                        to: { owner: Principal.fromText(walletPrincipal), subaccount: [] },
                        fee: [BigInt(10)],
                        memo: [],
                        from_subaccount: [],
                        created_at_time: [],
                        amount: amountToTransfer,
                    });
                }

                if (transferResult && "Ok" in transferResult) {
                    setSuccess(true);
                    console.log("Transfer successful: ", transferResult);

                    setTimeout(() => {
                        setSuccess(false);
                    }, 2000);
                } else {
                    console.log(1, transferResult.Err);

                    if (transferResult.Err && typeof transferResult.Err === "object") {
                        const errorKey = Object.keys(transferResult.Err)[0];
                        setErrorMessage(`Transfer failed: ${errorKey}`);
                    } else {
                        setErrorMessage("Transfer failed: " + JSON.stringify(transferResult.Err));
                    }
                }
            } catch (error) {
                if (error instanceof Error) {
                    setErrorMessage("Error during transfer: " + error.message);
                } else {
                    setErrorMessage("Unknown error occurred");
                }
            }
        } else {
            setErrorMessage("No token selected");
        }

        setIsLoading(false);
    };

    const handleAmountToWithdrawChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const value = e.target.valueAsNumber;
        setAmountToWithdraw(value);
    };

    const handleCopy = async () => {
        try {
            await navigator.clipboard.writeText(principalId);
            setIsCopied(true);

            setTimeout(() => {
                setIsCopied(false);
            }, 1500);
        } catch (err) {
            console.error("Failed to copy text: ", err);
        }
    };

    const handleCheckboxChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setIsFullAmount(e.target.checked);
        if (e.target.checked && balance !== null) {
            setAmountToWithdraw(balance);
        } else {
            setAmountToWithdraw(0);
        }
    };

    return (
        <>
            <ul className="wallet-info">
                <li className="wallet-info__element">
                    <div className="wallet-info__element-container">
                        <div className="wallet-info__element-sub-container">
                            <img className="wallet-info__icon" src={icpIcon} alt="ICP Icon" />
                            <span className="wallet-info__element">Service principal ID</span>
                        </div>
                        <div className="wallet-info__element-sub-container">
                            <span className="wallet-info__value">{principalId}</span>
                            <img
                                className="wallet-info__icon wallet-info__icon_copy"
                                src={isCopied ? doneIcon : copyIcon}
                                alt="Copy Icon"
                                onClick={handleCopy}
                            />
                        </div>
                    </div>
                </li>
                <li className="wallet-info__element">
                    <div className="wallet-info__element-container wallet-info__element-container_vertical">
                        <p className="wallet-info__element-description">
                            Withdraw your tokens from service to your wallet
                        </p>
                        <label className="wallet-info__input-label">1. Select token to withdraw:</label>
                        <DropDownList
                            selectedOption={selectedWithdrawToken}
                            onChange={setSelectedWithdrawToken}
                            options={optionsToWithdraw}
                            buttonTitle="Select token"
                            width="100%"
                        />
                        <BalanceInfo getBalance={handleGetBalance} token={selectedWithdrawToken} />
                        <div className="wallet-info__withrdaw-checkbox-option">
                            <p className="wallet-info__option-description">2. Do you want to withdraw max amount?</p>
                            <div className="wallet-info__checkbox-container">
                                <div className="wallet-info__checkbox">
                                    <input
                                        type="checkbox"
                                        id="withdrawFullAmount"
                                        className="wallet-info__checkbox-input"
                                        onChange={handleCheckboxChange}
                                        checked={isFullAmount}
                                    />
                                    <label htmlFor="withdrawFullAmount" className="wallet-info__checkbox-label">
                                        {isFullAmount ? "Yes" : "Custom amount"}
                                    </label>
                                </div>
                            </div>
                        </div>
                        <label className="wallet-info__input-label">3. Amount to withdraw:</label>
                        <input
                            className="wallet-info__text-field"
                            type="number"
                            min={0}
                            ref={amountToWithdrawRef}
                            placeholder="Amount"
                            value={isFullAmount && balance !== null ? Math.max(balance - fee, 0) : amountToWithdraw}
                            onChange={handleAmountToWithdrawChange}
                            disabled={isFullAmount}
                            onInvalid={(e) => e.preventDefault()}
                        />
                        <span className="wallet-info__input-info">
                            Minimum amount to withdraw is:{" "}
                            {selectedWithdrawToken === "ICP"
                                ? "0.00010001 ICP"
                                : selectedWithdrawToken === "ckBTC"
                                ? "0.00000011 ckBTC"
                                : "-"}
                        </span>
                        <label className="wallet-info__input-label">4. Tell us your wallet principal ID:</label>
                        <input
                            className="wallet-info__text-field wallet-info__text-field_principal"
                            type="text"
                            placeholder="Principal Id"
                            onInvalid={(e) => e.preventDefault()}
                            value={walletPrincipal}
                            onChange={(e) => setWalletPrincipal(e.target.value)}
                        />
                        <button
                            onClick={withdraw}
                            className={`wallet-info__withdraw-button ${
                                success ? "wallet-info__withdraw-button_success" : ""
                            }`}
                            disabled={
                                !selectedWithdrawToken ||
                                !amountToWithdraw ||
                                amountToWithdraw < minimumAmountToWithdraw ||
                                !walletPrincipal ||
                                isLoading
                            }
                        >
                            {isLoading ? "Processing..." : success ? "Success" : "Withdraw"}
                        </button>
                        {errorMessage && <span className="wallet-info__error-message">{errorMessage}</span>}
                    </div>
                </li>
            </ul>
        </>
    );
};

export default WalletInfo;
