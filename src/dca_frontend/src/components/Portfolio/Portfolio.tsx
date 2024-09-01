import React, { useEffect, useState } from "react";
import "./Portfolio.css";
import { useAuth } from "../../context/AuthContext";
import { Position } from "../../../declarations/dca_backend/dca_backend.did.js";
import icpIcon from "../../images/internet-computer-icp-logo.svg";
import { useCryptoConvert } from "../../context/CryptoConvertContext";
import ckBTCIcon from "../../images/ckBTC.svg";
import inProgressIcon from "../../images/repeat-svgrepo-com.svg";
import doneIcon from "../../images/checkmark-xs-svgrepo-com.svg";
import PositionHistory from "../PositionHistory/PositionHistory"; // Импорт нового компонента

interface PortfolioProps {
    onDetailsClick: () => void;
}

const Portfolio: React.FC<PortfolioProps> = ({ onDetailsClick }) => {
    const { isConnected, actorBackend } = useAuth();
    const [positions, setPosition] = useState<Position[]>([]);
    const [showHistory, setShowHistory] = useState<boolean>(false); // Новое состояние для управления показом истории
    const [currentItem, setCurrentItem] = useState<Position | null>(null); // Состояние для хранения текущего элемента
    const convert = useCryptoConvert();

    useEffect(() => {
        const getAllPosition = async () => {
            try {
                const pos = await actorBackend.getAllPositions();
                if (pos.ok) {
                    setPosition(pos.ok);
                }
            } catch (error) {
                console.warn("Error fetching positions:", error);
            }
        };

        if (isConnected) {
            getAllPosition();
        } else {
            console.warn("II isn't connected");
        }
    }, [isConnected, actorBackend]);

    const [showPopup, setShowPopup] = useState<boolean>(false);
    const [selectedItem, setSelectedItem] = useState<number | null>(null);

    const convertToken = async (amountToConvert: BigInt) => {
        try {
            const convertedIcp = await convert.ICP.BTC(Number(amountToConvert));
            return convertedIcp;
        } catch (error) {
            console.warn("Error converting ICP to BTC:", error);
        }
    };

    const handleButtonClick = (id: number) => {
        setSelectedItem(id);
        setShowPopup(!showPopup);
    };

    const handleClosePosition = async () => {
        if (selectedItem !== null) {
            try {
                const indexBigInt = BigInt(selectedItem);
                const result = await actorBackend.closePosition(indexBigInt);

                if (result.ok) {
                    setPosition((prevPositions: Position[]) =>
                        prevPositions.filter((_, index) => index !== selectedItem)
                    );
                } else {
                    console.error("Error closing position:", result.err);
                }
            } catch (error) {
                console.error("Error calling closePosition:", error);
            }
        }
    };

    const handleCheckHistory = () => {
        if (selectedItem !== null) {
            setCurrentItem(positions[selectedItem]);
            setShowHistory(true);
        }
    };

    const castAmounts = (amount: BigInt): string => {
        const devidedAmount = Number(amount) / 100000000;
        return devidedAmount.toString();
    };

    function formatTimestamp(timestamp: number): string {
        if (timestamp === 0) {
            return "In a few minutes";
        }
        const formattedTimestamp = Math.floor(timestamp / 1_000_000);
        const date = new Date(formattedTimestamp);

        const day = String(date.getDate()).padStart(2, "0");
        const month = date.toLocaleString("default", { month: "long" });
        const year = String(date.getFullYear()).slice(-2);

        const hours = String(date.getHours()).padStart(2, "0");
        const minutes = String(date.getMinutes()).padStart(2, "0");

        return `${month} ${day}, ${year}, ${hours}:${minutes}`;
    }

    const getCurrentStatus = (purchasesLeft: BigInt): boolean => {
        if (Number(purchasesLeft) > 0) {
            return false;
        }
        return true;
    };

    if (showHistory && currentItem) {
        return (
            <PositionHistory
                item={currentItem}
                amountToSell={castAmounts(currentItem.amountToSell)}
                purchasesLeft={currentItem.purchasesLeft.toString()}
                onBackClick={() => setShowHistory(false)}
                nextRunTime={formatTimestamp(Number(currentItem.nextRunTime))}
            />
        );
    }

    return (
        <ul className={`portfolio ${!isConnected ? "portfolio_is-not-connected" : ""}`}>
            {!isConnected ? (
                <li className="portfolio-item portfolio-item_is-not-connected">
                    Connect wallet first and create contract
                </li>
            ) : (
                positions.map((item: Position, index: number) => (
                    <li className="portfolio-item" key={index}>
                        <div className="portfolio-item__status-container">
                            <div className="portfolio-item__status-sub-container">
                                <img
                                    className="portfolio-item__status-icon"
                                    src={getCurrentStatus(item.purchasesLeft) ? doneIcon : inProgressIcon}
                                    alt="Subscription status"
                                />
                                <span className="portfolio-item__value">{Object.keys(item.frequency)[0]}</span>
                            </div>
                            <span className="portfolio-item__warn-description">
                                {getCurrentStatus(item.purchasesLeft) ? "Done" : "In progress"}
                            </span>
                        </div>
                        <div className="portfolio-item__container">
                            <div className="portfolio-item__sub-container">
                                <span className="portfolio-item__key">Amount to sale:</span>
                                <div className="portfolio-item__details-container">
                                    <span className="portfolio-item__value">{castAmounts(item.amountToSell)} ICP</span>
                                    <img className="portfolio-item__image" src={icpIcon} alt="Internet Identity" />
                                </div>
                            </div>
                            <div className="portfolio-item__sub-container">
                                <span className="portfolio-item__key">Purchases left:</span>
                                <div className="portfolio-item__details-container">
                                    <span className="portfolio-item__value">{item.purchasesLeft.toString()}</span>
                                </div>
                            </div>
                            <div className="portfolio-item__sub-container">
                                <span className="portfolio-item__key">Next purchase:</span>
                                <div className="portfolio-item__details-container">
                                    <span className="portfolio-item__value">
                                        {formatTimestamp(Number(item.nextRunTime))}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <button className="portfolio-item__button" onClick={() => handleButtonClick(index)}>
                            ⋮
                            {showPopup && selectedItem === index && (
                                <div className="portfolio-item__popup">
                                    <span onClick={handleClosePosition}>Close position</span>
                                    <span onClick={handleCheckHistory}>Check history</span>
                                </div>
                            )}
                        </button>
                    </li>
                ))
            )}
        </ul>
    );
};

export default Portfolio;
