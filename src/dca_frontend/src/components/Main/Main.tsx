import React, { useState, useEffect, useRef } from "react";
import "./Main.css";
import FormContainer from "../FormContainer/FormContainer";
import FormNavigation from "../FormNavigation/FormNavigation";
import Form from "../Form/Form";
import { validateForm, FormErrors } from "../../utils/validation";
import Portfolio from "../Portfolio/Portfolio";
import SubscriptionDetails from "../SubscriptionDetails/SubscriptionDetails";
import { CryptoConvertProvider } from "../../context/CryptoConvertContext";
import { useAuth } from "../../context/AuthContext";
import { Position } from "../../../declarations/dca_backend/dca_backend.did.js";
import { idlFactory as ckbtcLedger } from "../../../declarations/ckBTC_ledger_canister/ckBTC_ledger_canister.did.js";

import {
    handleInternetIdentityAuth,
    createActor,
    disconnectInternetIdentity,
    checkIsInternetIdentityConnected,
} from "../../utils/auth";
import { AuthClient, LocalStorage } from "@dfinity/auth-client";

import { idlFactory as backend } from "../../../declarations/dca_backend/dca_backend.did.js";
import { idlFactory as legger } from "../../../declarations/icp_ledger_canister/icp_ledger_canister.did.js";

const Main: React.FC = () => {
    const {
        whitelist,
        setAuthClient,
        setIsConnected,
        setIdentity,
        setPrincipal,
        setActorBackend,
        setActorLedger,
        setActorCKBTCLedger,
        setWhitelist,
    } = useAuth();
    const [isWalletConnected, setIsWalletConnected] = useState<boolean>(false);
    const [errors, setErrors] = useState<FormErrors>({});
    const [isSubmitted, setIsSubmitted] = useState<boolean>(false);
    const [activeFormNavigationButton, setActiveFormNavigationButton] = useState<number>(0);
    const [showSubscriptionDetails, setShowSubscriptionDetails] = useState<boolean>(false);

    useEffect(() => {
        const id1 = process.env.CANISTER_ID_INTERNET_IDENTITY;
        const id2 = process.env.CANISTER_ID_DCA_BACKEND;
        const id3 = process.env.CANISTER_ID_ICP_LEDGER_CANISTER;
        const id4 = process.env.CANISTER_ID_CKBTC_LEDGER_CANISTER;

        const filteredWhitelist = [id1, id2, id3, id4].filter((id): id is string => !!id);
        setWhitelist(filteredWhitelist);
    }, [setWhitelist]);

    useEffect(() => {
        const initializeAuthClient = async () => {
            try {
                const authClient = await AuthClient.create({
                    storage: new LocalStorage(),
                    keyType: "Ed25519",
                    idleOptions: {
                        idleTimeout: 1000 * 60 * 30,
                        disableDefaultIdleCallback: true,
                    },
                });

                const isAuthenticated = await authClient.isAuthenticated();
                if (isAuthenticated) {
                    const identity = authClient.getIdentity();
                    setIsConnected(true);
                    setAuthClient(authClient);
                    setPrincipal(identity.getPrincipal());
                    setIdentity(identity);

                    const actorBackend = await createActor(whitelist[1], backend, identity);
                    const actorLedger = await createActor(whitelist[2], legger, identity);
                    const actorCkbtcCLedger = await createActor(whitelist[3], ckbtcLedger, identity);

                    setActorCKBTCLedger(actorCkbtcCLedger);
                    setActorBackend(actorBackend);
                    setActorLedger(actorLedger);
                }
            } catch (error) {
                console.error("Ошибка при инициализации AuthClient:", error);
            }
        };

        initializeAuthClient();
    }, [setAuthClient, setIsConnected, setIdentity, setPrincipal, setActorBackend, setActorLedger, whitelist]);

    useEffect(() => {
        const handleEsc = (event: KeyboardEvent) => {
            if (event.key === "Escape") {
                setShowSubscriptionDetails(false);
            }
        };
        window.addEventListener("keydown", handleEsc);

        return () => {
            window.removeEventListener("keydown", handleEsc);
        };
    }, []);

    return (
        <CryptoConvertProvider>
            <main className="main">
                <FormContainer>
                    {!showSubscriptionDetails ? (
                        <>
                            <FormNavigation
                                activeFormNavigationButton={activeFormNavigationButton}
                                onFormNavigationClick={setActiveFormNavigationButton}
                            />
                            {activeFormNavigationButton === 0 ? (
                                <Form isWalletConnected={isWalletConnected} />
                            ) : (
                                <Portfolio onDetailsClick={() => setShowSubscriptionDetails(true)} />
                            )}
                        </>
                    ) : (
                        <SubscriptionDetails />
                    )}
                </FormContainer>
            </main>
        </CryptoConvertProvider>
    );
};

export default Main;
