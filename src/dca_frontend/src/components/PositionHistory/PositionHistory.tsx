import React from "react";
import { Position } from "../../../declarations/dca_backend/dca_backend.did.js";
import "./PositionHistory.css";
import leftArrow from "../../images/left-arrow-svgrepo-com.svg";

interface PositionHistoryProps {
    item: Position;
    onBackClick: () => void;
    amountToSell: string;
    purchasesLeft: string;
    nextRunTime: string;
}

const PositionHistory: React.FC<PositionHistoryProps> = ({
    item,
    onBackClick,
    amountToSell,
    purchasesLeft,
    nextRunTime,
}) => {

    const castBtc = (amount: string) => {
        return Number(amount) / 1_00_000_000;
    }

    const parsePurchaseHistory = (item: Position) => {
        if (!item.purchaseHistory || item.purchaseHistory.length === 0 || !item.purchaseHistory[0]) {
            return <div>No purchase history available now</div>;
        }

        const history = item.purchaseHistory[0].map((entry, index) => {
            if ("ok" in entry) {
                return (
                    <li key={index} className="position-history__item">
                        <span className="position-history__item_success">Success: {castBtc(entry.ok)} ckBTC</span>
                    </li>
                );
            } else if ("err" in entry) {
                return (
                    <li key={index} className="position-history__item">
                        <span className="position-history__item_error">Error: {entry.err}</span>
                    </li>
                );
            } else {
                return (
                    <li key={index} className="position-history__item">
                        <span className="position-history__item_unknown">Unknown result</span>
                    </li>
                );
            }
        });

        return <ul className="purchase-history__list">{history}</ul>;
    };

    return (
        <div className="position-history">
            <button className="position-history__back-button" onClick={onBackClick}>
                <img className="position-history__back-icon" src={leftArrow} alt="Go back icon" />
                <span>Back to portfolio</span>
            </button>
            <div className="position-history__container">
                <h2 className="position-history__title">Position History</h2>
                {parsePurchaseHistory(item)}
            </div>
        </div>
    );
};

export default PositionHistory;
