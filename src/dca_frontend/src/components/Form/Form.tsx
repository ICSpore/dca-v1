import React, { useRef, useState, useEffect } from "react";
import "./Form.css";
import SubmitButton from "../SubmitButton/SubmitButton";
import ConnectWalletButton from "../ConnectWalletButton/ConnectWalletButton";
import { useAuth } from "../../context/AuthContext";
import RadioButtons from "../RadioButtons/RadioButtons";
import BalanceInfo from "../BalanceInfo/BalanceInfo";
import DropDownList from "../DropDownList/DropDownList";
import icpIcon from "../../images/icp-rounded.svg";
import ckUSDCIcon from "../../images/ckUSDC.svg";
import ckUSDTIcon from "../../images/ckUSDT.svg";

import ckBTCIcon from "../../images/ckBTC.svg";
import ckETHIcon from "../../images/ckETH.svg";
import CHATIcon from "../../images/spinner.svg";
import { Position } from "../../../declarations/dca_backend/dca_backend.did";

interface FormProps {
    isWalletConnected: boolean;
}

const Form: React.FC<FormProps> = ({ isWalletConnected }) => {
    const { isConnected } = useAuth();

    const [endDate, setEndDate] = useState<string>("");
    const [isFormValid, setIsFormValid] = useState<boolean>(false);
    const [amountToSell, setAmountToSell] = useState<number>(1.0);

    const amountToSellRef = useRef<HTMLInputElement>(null);
    const frequencyRef = useRef<{ getFrequency: () => string }>(null);

    const [selectedSellToken, setSelectedSellToken] = useState<string | null>(null);
    const [selectedBuyToken, setSelectedBuyToken] = useState<string | null>(null);

    useEffect(() => {
        validateForm();
    }, [endDate, amountToSell, frequencyRef, selectedSellToken, selectedBuyToken]);

    const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const value = e.target.valueAsNumber;
        setAmountToSell(value);
        validateForm();
    };

    const handleFrequencyChange = () => {
        validateForm();
    };

    const validateForm = () => {
        const isAmountValid = amountToSell > 0;
        const isFrequencyValid = frequencyRef.current?.getFrequency();
        const isEndDateValid = endDate !== "";
        const isSellTokenValid = selectedSellToken !== null;
        const isBuyTokenValid = selectedBuyToken !== null;

        setIsFormValid(isAmountValid && !!isFrequencyValid && isEndDateValid && isSellTokenValid && isBuyTokenValid);
    };

    const handleSubmitForm = (e: React.FormEvent) => {
        e.preventDefault();
    };

    const optionsToSell = [
        { label: "ICP", value: "ICP", icon: <img className="" src={icpIcon} alt="ICP Icon" />, available: true },
        { label: "ckUSDT", value: "ckUSDT", icon: <img src={ckUSDTIcon} alt="ckUSDT Icon" />, available: false },
        { label: "ckUSDC", value: "ckUSDC", icon: <img src={ckUSDCIcon} alt="ckUSDC Icon" />, available: false },
    ];

    const optionsToBuy = [
        {
            label: "ckBTC",
            value: "ckBTC",
            icon: <img className="" src={ckBTCIcon} alt="ckBTC Icon" />,
            available: true,
        },
        { label: "ckETH", value: "ckETH", icon: <img src={ckETHIcon} alt="ckETH Icon" />, available: false },
        { label: "CHAT", value: "CHAT", icon: <img src={CHATIcon} alt="CHAT Icon" />, available: false },
    ];

    return (
        <>
            <form className="form" onSubmit={handleSubmitForm}>
                <div className="select-input__container">
                    <label htmlFor="buy" className="select-input__label">
                        You buy:
                    </label>
                    <DropDownList
                        selectedOption={selectedBuyToken}
                        onChange={setSelectedBuyToken} // Применение состояния для выбора токена на покупку
                        options={optionsToBuy}
                        buttonTitle="Select token"
                        width="100%"
                    />
                </div>

                <div className="select-input__container select-input__container_last">
                    <label htmlFor="sell" className="select-input__label">
                        You sell:
                    </label>
                    <div className="select-input__controls">
                        <DropDownList
                            selectedOption={selectedSellToken}
                            onChange={setSelectedSellToken} // Применение состояния для выбора токена на продажу
                            options={optionsToSell}
                            buttonTitle="Select token"
                            width="40%"
                        />
                        <input
                            className="select-input__text-field"
                            type="number"
                            min={0.1}
                            ref={amountToSellRef}
                            placeholder="Amount"
                            value={amountToSell !== undefined ? amountToSell : 0}
                            onChange={handleAmountChange}
                            onInvalid={(e) => e.preventDefault()}
                        />
                    </div>
                    <div className="select-input__balance-info">
                        <span className="select-input__description">Minimum amount equals 0.1 ICP</span>
                        <BalanceInfo />
                    </div>
                </div>

                <RadioButtons ref={frequencyRef} onDataChange={handleFrequencyChange} />

                <div className="date-picker">
                    <label htmlFor="endDate" className="date-picker__label">
                        End date:
                    </label>
                    <input
                        className="date-picker__input"
                        type="date"
                        id="endDate"
                        value={endDate}
                        min={new Date().toISOString().split("T")[0]}
                        onChange={(e) => setEndDate(e.target.value)}
                    />
                </div>

                {isConnected ? (
                    <SubmitButton
                        isWalletConnected={isWalletConnected}
                        disabled={!isFormValid}
                        buyOption={"ckBTC"}
                        sellOption={"ICP"}
                        frequency={frequencyRef.current?.getFrequency() || ""}
                        endDate={endDate}
                        amount={amountToSell}
                        isFormValid={isFormValid}
                        tst={handleSubmitForm}
                    ></SubmitButton>
                ) : (
                    <ConnectWalletButton />
                )}
            </form>
        </>
    );
};

export default Form;
