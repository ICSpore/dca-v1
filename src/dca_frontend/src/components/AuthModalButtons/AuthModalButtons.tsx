import React, { useEffect } from "react";
import "./AuthModalButtons.css";
import InternetIdentityIcon from "../../images/internet-computer-icp-logo.svg";
import PlugIcon from "../../images/plugLogo.png";
import { handleInternetIdentityAuth, createActor, disconnectInternetIdentity } from "../../utils/auth";
import { useAuth } from "../../context/AuthContext";
import { idlFactory as backend } from "../../../declarations/dca_backend/dca_backend.did.js";
import { idlFactory as legger } from "../../../declarations/icp_ledger_canister/icp_ledger_canister.did.js";

const AuthModalButtons: React.FC = () => {
    const {
        authClient,
        isConnected,
        identity,
        whitelist,
        setAuthClient,
        setIsConnected,
        setIdentity,
        setPrincipal,
        setActorBackend,
        setActorLedger,
    } = useAuth();

    const handleLoginToInternetIdentity = async () => {
        try {
            const client = await handleInternetIdentityAuth();
            if (client) {
                setIsConnected(true);
                setAuthClient(client);
                const identity = client.getIdentity();
                const actorBackend = await createActor(whitelist[1], backend, identity);
                const actorLedger = await createActor(whitelist[2], legger, identity);

                setActorBackend(actorBackend);
                setActorLedger(actorLedger);
                setPrincipal(identity.getPrincipal());
                setIdentity(identity);
            }
        } catch (error) {
            console.warn(`Failed to auth to InternetIdentity: ${error}`);
        }
    };

    const handleLogout = async () => {
        if (isConnected && authClient && identity) {
            await disconnectInternetIdentity(authClient);
            setIsConnected(false);
            setPrincipal(undefined);
            setIdentity(undefined);
            setAuthClient(undefined);
            setActorBackend(null);
        }
    };

    return (
        <ul className="auth-modal-buttons__list">
            {isConnected ? (
                <li className="auth-modal-button__item">
                    <button onClick={handleLogout} className="auth-modal-button auth-modal-button_disconnect">
                        <span>Disconnect</span>
                    </button>
                </li>
            ) : (
                <>
                    <li className="auth-modal-button__item">
                        <button
                            onClick={handleLoginToInternetIdentity}
                            className="auth-modal-button auth-modal-button_ii"
                        >
                            <span>Internet Identity</span>
                            <img
                                className="auth-modal-button__image"
                                src={InternetIdentityIcon}
                                alt="Internet Identity"
                            />
                        </button>
                    </li>
                    <li className="auth-modal-button__item auth-modal-button__item_under-construction">
                        <button disabled className="auth-modal-button auth-modal-button_plug">
                            <span>Plug Wallet</span>
                            <img className="auth-modal-button__image" src={PlugIcon} alt="Plug Wallet" />
                        </button>
                    </li>
                </>
            )}
        </ul>
    );
};

export default AuthModalButtons;
