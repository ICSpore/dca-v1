import React, { useEffect, useState } from "react";
import "./BalanceInfo.css";
import { useAuth } from "../../context/AuthContext";

interface BalanceInfoProps {
    getBalance?: (balance: number | null) => void;
    token: string | null; // Добавляем новый пропс token
}

const BalanceInfo: React.FC<BalanceInfoProps> = ({ getBalance, token }) => {
    const { isConnected, actorLedger, actorCKBTCLedger, principal } = useAuth();
    const [balance, setBalance] = useState<number | null>(null);

    const fetchBalance = async () => {
        if (!isConnected || !principal) return;

        try {
            let res;
            if (token === "ICP" && actorLedger) {
                res = await actorLedger.icrc1_balance_of({ owner: principal, subaccount: [] });
            } else if (token === "ckBTC" && actorCKBTCLedger) {
                res = await actorCKBTCLedger.icrc1_balance_of({ owner: principal, subaccount: [] });
            } else if (token === null) {
                setBalance(null);
                if (getBalance) getBalance(null);
                return;
            }

            if (res >= 0) {
                const updatedBalance = Number(res) / 100000000;
                setBalance(updatedBalance);
                if (getBalance) getBalance(updatedBalance);
            }
        } catch (error) {
            console.warn(`Error fetching balance: ${error}`);
        }
    };

    useEffect(() => {
        fetchBalance();
    }, [isConnected, token, actorLedger, actorCKBTCLedger, principal]);

    useEffect(() => {
        const intervalId = setInterval(() => {
            fetchBalance();
        }, 60000);

        return () => clearInterval(intervalId);
    }, [token]);

    return (
        <div className="balance-info">
            <span className="balance-info__description">
                In wallet: {balance !== null ? `${balance} ${token}` : "-"}
            </span>
        </div>
    );
};

export default BalanceInfo;
