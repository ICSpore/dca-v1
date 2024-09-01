import React, { useEffect, useState } from "react";
import "./FormSubtotal.css";
import icpIcon from "../../images/internet-computer-icp-logo.svg";
import ckBTCIcon from "../../images/ckBTC.svg";
import { useCryptoConvert } from "../../context/CryptoConvertContext";

interface FormSubtotalProps {
    buyOption: string;
    sellOption: string;
    frequency: string;
    endDate: string;
    amount: number;
    totalAmount: number;
    numberOfPayments: number;
}

const FormSubtotal: React.FC<FormSubtotalProps> = ({
    buyOption,
    sellOption,
    frequency,
    endDate,
    amount,
    totalAmount,
    numberOfPayments,
}) => {
    const [formattedDate, setFormattedDate] = useState<string>("");
    const [formattedTodayDate, setFormattedTodayDate] = useState<string>("");

    const [btcAmount, setBtcAmount] = useState<number | null>(null);
    const [totalBtcAmount, setTotalBtcAmount] = useState<number | null>(null);

    const convert = useCryptoConvert();

    useEffect(() => {
        const dateObj = new Date(endDate);
        const today = new Date();

        const options: Intl.DateTimeFormatOptions = {
            year: "numeric",
            month: "long",
            day: "numeric",
        };

        setFormattedDate(dateObj.toLocaleDateString("en-US", options));
        setFormattedTodayDate(today.toLocaleDateString("en-US", options));
    }, []);

    useEffect(() => {
        const convertToken = async () => {
            if (convert) {
                try {
                    const convertedIcp = await convert.ICP.BTC(amount);
                    if (convertedIcp) {
                        setBtcAmount(convertedIcp);
                    }
                    const convertedTotalIcp = await convert.ICP.BTC(totalAmount);
                    if (convertedTotalIcp) {
                        setTotalBtcAmount(convertedTotalIcp);
                    }
                } catch (error) {
                    console.warn("Error converting ICP to BTC:", error);
                }
            }
        };

        convertToken();
    }, []);

    return (
        <div className="form-subtotal">
            <ul className="form-subtotal__list">
                <li className="form-subtotal__element">
                    <span className="form-subtotal__element-description">For each sale you spend:</span>
                    <div className="form-subtotal__element-sub-container">
                        <span className="form-suntotal__element-value">
                            {amount} {sellOption}
                        </span>
                        <img className="auth-modal-button__image" src={icpIcon} alt="Internet Identity" />
                    </div>
                </li>
                <li className="form-subtotal__element">
                    <div className="form-subtotal__element-description-container">
                        <span className="form-subtotal__element-description">With every sale you buy:</span>
                        <span className="form-subtotal__element-warning">According to {formattedTodayDate} rate</span>
                    </div>
                    <div className="form-subtotal__element-sub-container">
                        <span className="form-suntotal__element-value">
                            {btcAmount ? btcAmount : ""} {buyOption}
                        </span>
                        <img className="auth-modal-button__image" src={ckBTCIcon} alt="Internet Identity" />
                    </div>
                </li>
                <li className="form-subtotal__element">
                    <span className="form-subtotal__element-description">How often:</span>
                    <span className="form-suntotal__element-value">{frequency}</span>
                </li>
                <li className="form-subtotal__element">
                    <span className="form-subtotal__element-description">Untill:</span>
                    <span className="form-suntotal__element-value"> {formattedDate}</span>
                </li>
            </ul>

            <div className="form-subtotal__result">
                <div className="form-subtotal__element-sub-container form-subtotal__element-sub-container_total-purchases">
                    <span className="form-subtotal__element-description">Number of purchases:</span>
                    <span className="form-suntotal__element-value"> {numberOfPayments}</span>
                </div>
                <div className="form-subtotal__element-sub-container form-subtotal__element-sub-container_total-to-sell">
                    <span className="form-subtotal__element-description">Total amount to sell:</span>
                    <div className="form-subtotal__element-sub-container">
                        <span className="form-suntotal__element-value">
                            {totalAmount} {sellOption}
                        </span>
                        <img className="auth-modal-button__image" src={icpIcon} alt="Internet Identity" />
                    </div>
                </div>
                <div className="form-subtotal__element-sub-container form-subtotal__element-sub-container_total-to-buy">
                    <div className="form-subtotal__element-description-container form-subtotal__element-description-container_result">
                        <span className="form-subtotal__element-description">Total amount to buy:</span>
                        <span className="form-suntotal__element-value">
                            {totalBtcAmount} {buyOption}
                        </span>
                        <img className="auth-modal-button__image" src={ckBTCIcon} alt="Internet Identity" />
                    </div>
                    <span className="form-subtotal__element-warning">According to {formattedTodayDate} rate</span>
                </div>
            </div>
        </div>
    );
};

export default FormSubtotal;
