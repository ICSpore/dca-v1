import React, { useEffect, useState } from "react";
import "./BalanceInfo.css";
import { useAuth } from "../../context/AuthContext";

interface BalanceInfoProps {
    getBalance?: (balance: number | null) => void; // Изменен тип getBalance
}

const BalanceInfo: React.FC<BalanceInfoProps> = ({ getBalance }) => {
    const { isConnected, actorLedger, principal } = useAuth();

    const [balance, setBalance] = useState<number | null>(null);

    const fetchBalance = async () => {
        if (isConnected && actorLedger && principal) {
            try {
                const res = await actorLedger.icrc1_balance_of({ owner: principal, subaccount: [] });
                const updatedBalance = Number(res) / 100000000;
                setBalance(updatedBalance);

                if (getBalance) {
                    getBalance(updatedBalance);
                }
            } catch (error) {
                console.warn(`Error fetching balance: ${error}`);
            }
        }
    };

    useEffect(() => {
        fetchBalance();
    }, [isConnected, actorLedger, principal]);

    useEffect(() => {
        const intervalId = setInterval(() => {
            fetchBalance();
        }, 60000);

        return () => clearInterval(intervalId);
    }, []);

    return (
        <div className="balance-info">
            <span className="balance-info__description">In wallet: {balance !== null ? `${balance} ICP` : "-"} </span>
        </div>
    );
};
export default BalanceInfo;

//10000000000/100000000 1icp = 1 и 8 нулей
// portfolio getallpositions
//
//(viewContract = closePosition) func (positionId)
