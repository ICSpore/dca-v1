import React, { useEffect, useState } from "react";
import "./OpenPosition.css";
import { handleOpenPosition } from "../../utils/auth";
import { Position, Frequency } from "../../../declarations/dca_backend/dca_backend.did.js";
import { useAuth } from "../../context/AuthContext";
import { Principal } from "@dfinity/principal";

interface OpenPositionProps {
    children: React.ReactNode;
    buyOption: string;
    sellOption: string;
    frequency: string;
    endDate: string;
    amount: number;
    onClose: () => void;
    numberOfPayments: number;
    isPopupOpen: boolean;
}

const OpenPosition: React.FC<OpenPositionProps> = ({
    children,
    buyOption,
    sellOption,
    frequency,
    endDate,
    amount,
    onClose,
    numberOfPayments,
    isPopupOpen,
}) => {
    const { isConnected, actorBackend, actorLedger, whitelist, principal } = useAuth();
    const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
    const [isPositionCreated, setIsPositionCreated] = useState<boolean>(false);
    const [isApproveError, setIsApproveError] = useState<boolean>(false);

    const getAllPosition = async () => {
        try {
            const pos = await actorBackend.getAllPositions();
            if (pos.ok) {
                return pos.ok;
            }
        } catch (error) {
            console.warn("Error fetching positions:", error);
        }
    };

    const mapToFrequency = (frequency: string): Frequency => {
        switch (frequency) {
            case "Weekly":
                return { Weekly: null };
            case "Daily":
                return { Daily: null };
            case "Monthly":
                return { Monthly: null };
            default:
                throw new Error("Invalid frequency");
        }
    };

    const calculateFullAllowance = async (oppenedPositions: Position[], currentAmount: number) => {
        if (oppenedPositions.length > 0) {
            const totalAmount = oppenedPositions.reduce((total, position) => total + position.amountToSell, BigInt(0));
            const totalAllowance = Number(totalAmount) + currentAmount; // Преобразуем BigInt в number для расчета

            return totalAllowance;
        }

        return currentAmount; // Если нет открытых позиций, возвращаем текущее значение
    };

    useEffect(() => {
        setIsApproveError(false);
    }, [isPopupOpen]);

    const openPosition = async () => {
        setIsSubmitting(true);

        try {
            const allowanceArgs = {
                account: {
                    owner: principal,
                    subaccount: [],
                },
                spender: {
                    owner: Principal.fromText(whitelist[1]),
                    subaccount: [],
                },
            };

            const allowanceResult = await actorLedger.icrc2_allowance(allowanceArgs);

            const allowanceInNumber = Number(allowanceResult.allowance);

            const totalPurchasesAmmount = (amount * 100000000 + 10_000) * numberOfPayments + allowanceInNumber;

            const approveArgs = {
                amount: totalPurchasesAmmount,
                spender: {
                    owner: Principal.fromText(whitelist[1]),
                    subaccount: [],
                },
                fee: [],
                memo: [],
                from_subaccount: [],
                created_at_time: [],
                expected_allowance: [],
                expires_at: [],
            };

            const approve = await actorLedger.icrc2_approve(approveArgs);
            if (approve.Ok) {
                const mappedFrequency = mapToFrequency(frequency);
                const response = await handleOpenPosition(
                    actorBackend,
                    whitelist,
                    principal,
                    BigInt(amount * 100000000),
                    mappedFrequency,
                    BigInt(numberOfPayments)
                );
                if (response.ok) {
                    setIsPositionCreated(true);
                    setIsApproveError(false);
                } else if (response.err) {
                    setIsApproveError(true);
                }
            }
        } catch (error) {
            setIsPositionCreated(false);
            setIsApproveError(true);
            console.error(error);
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="open-position">
            <p className="open-position__description">Once confirmed, this subscription will be created:</p>
            <div className="open-position__children">{children}</div>
            <p className="open-position__warn-text">Your first purchase will proceed right away</p>
            {isApproveError && <p className="open-position__error-message">Approve not received</p>}
            <ul className="open-position__buttons">
                <li className={`open-position__button open-position__button_approve ${isApproveError ? "error" : ""}`}>
                    <button onClick={openPosition} disabled={isSubmitting}>
                        {isPositionCreated ? "Position created" : isSubmitting ? "Creating..." : "Create subscription"}
                    </button>
                </li>
                <li className="open-position__button open-position__button_change" onClick={onClose}>
                    <button disabled={isSubmitting}>Correct form</button>
                </li>
            </ul>
        </div>
    );
};

export default OpenPosition;
