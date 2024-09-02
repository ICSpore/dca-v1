import React, { useState, useRef } from "react";
import "./WalletInfo.css";
import copyIcon from "../../images/copy-4-svgrepo-com.svg";
import doneIcon from "../../images/checkmark-xs-svgrepo-com.svg";
import icpIcon from "../../images/internet-computer-icp-logo.svg";
import ckBTCIcon from "../../images/ckBTC.svg";
import DropDownList from "../DropDownList/DropDownList";
import BalanceInfo from "../BalanceInfo/BalanceInfo";

interface WalletInfoProps {
    principalId: string;
}

const WalletInfo: React.FC<WalletInfoProps> = ({ principalId }) => {
    const [isCopied, setIsCopied] = useState<boolean>(false);
    const [selectedWithdrawToken, setSelectedWithdrawToken] = useState<string | null>(null);
    const amountToWithdrawRef = useRef<HTMLInputElement>(null);
    const [amountToWithdraw, setAmountToWithdraw] = useState<number>(0);
    const [isFullAmount, setIsFullAmount] = useState<boolean>(true);
    const [balance, setBalance] = useState<number | null>(null);

    const optionsToWithdraw = [
        { label: "ICP", value: "ICP", icon: <img src={icpIcon} alt="ICP Icon" />, available: true },
        { label: "ckBTC", value: "ckBTC", icon: <img src={ckBTCIcon} alt="ckBTC Icon" />, available: true },
    ];

    const handleGetBalance = (newBalance: number | null) => {
        setBalance(newBalance);
        if (isFullAmount && newBalance !== null) {
            setAmountToWithdraw(newBalance);
        }
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
            setAmountToWithdraw(balance); // Устанавливаем баланс в стейт, если выбран полный вывод
        } else {
            setAmountToWithdraw(0); // Сбрасываем сумму при отключении полного вывода
        }
    };

    return (
        <>
            <ul className="wallet-info">
                <li className="wallet-info__element">
                    <div className="wallet-info__element-container">
                        <div className="wallet-info__element-sub-container">
                            <img className="wallet-info__icon" src={icpIcon} alt="ICP Icon" />
                            <span className="wallet-info__element">Principal ID</span>
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
                        <p className="wallet-info__element-description">Withdraw your tokens from canister</p>
                        <label className="wallet-info__input-label">Select token to withdraw:</label>
                        <DropDownList
                            selectedOption={selectedWithdrawToken}
                            onChange={setSelectedWithdrawToken}
                            options={optionsToWithdraw}
                            buttonTitle="Select token"
                            width="100%"
                        />
                        <BalanceInfo getBalance={handleGetBalance} />
                        <div className="wallet-info__withrdaw-checkbox-option">
                            <p className="wallet-info__option-description">Do you want to withdraw full amount?</p>
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
                        <label className="wallet-info__input-label">Amount to withdraw:</label>
                        <input
                            className="wallet-info__text-field"
                            type="number"
                            min={0}
                            ref={amountToWithdrawRef}
                            placeholder="Amount"
                            value={isFullAmount && balance !== null ? balance : amountToWithdraw}
                            onChange={handleAmountToWithdrawChange}
                            disabled={isFullAmount} // Блокируем поле ввода, если выбран полный вывод
                            onInvalid={(e) => e.preventDefault()}
                        />
                        <label className="wallet-info__input-label">Tell us your wallet Principal ID:</label>
                        <input
                            className="wallet-info__text-field wallet-info__text-field_principal"
                            type="text"
                            placeholder="Principal Id"
                            onInvalid={(e) => e.preventDefault()}
                        />
                        <button className="wallet-info__withdraw-button">Withdraw</button>
                    </div>
                </li>
            </ul>
        </>
    );
};

export default WalletInfo;
