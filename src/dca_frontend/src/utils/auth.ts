import { AuthClient, LocalStorage } from "@dfinity/auth-client";
import { Actor, HttpAgent, Identity } from "@dfinity/agent";
import { IDL } from "@dfinity/candid";
import { Principal } from "@dfinity/principal";
import { DelegationIdentity, DelegationChain } from "@dfinity/identity";
import { Frequency } from "../../declarations/dca_backend/dca_backend.did";

// Utility to get identity provider URL
export const getIdentityProvider = (): string | undefined => {
    if (typeof window !== "undefined") {
        const isLocal = process.env.DFX_NETWORK !== "ic";
        const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
        if (isLocal && isSafari) {
            return `http://localhost:4943/?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`;
        } else if (isLocal) {
            return `http://${process.env.CANISTER_ID_INTERNET_IDENTITY}.localhost:4943`;
        } else {
            return `https://identity.ic0.app/#authorize`;
        }
    }
    return undefined;
};

// Handle authentication using Internet Identity
export const handleInternetIdentityAuth = async (): Promise<AuthClient | void> => {
    try {
        const authClient = await AuthClient.create({
            storage: new LocalStorage(),
            keyType: "Ed25519",
            idleOptions: {
                idleTimeout: 1000 * 60 * 30, // Set idle timeout to 30 minutes
                disableDefaultIdleCallback: true, // Disable the default reload behavior
            },
        });

        // Refresh login function for idle management
        const refreshLogin = () => {
            authClient.login({
                identityProvider: getIdentityProvider(),
                onSuccess: async () => {
                    const newIdentity = await authClient.getIdentity();
                    // Update any agents or objects associated with the new identity
                },
            });
        };

        // Register callback to handle user idle state
        authClient.idleManager?.registerCallback?.(refreshLogin);

        const identityProvider = getIdentityProvider();

        await new Promise<void>((resolve, reject) => {
            authClient.login({
                identityProvider,
                onSuccess: () => {
                    resolve();
                },
                onError: reject,
            });
        });

        return authClient;
    } catch (error) {
        console.error("Login to Internet Identity failed:", error);
    }
};

// Check if the Internet Identity is connected
export const checkIsInternetIdentityConnected = async (client: AuthClient): Promise<boolean | undefined> => {
    if (client) {
        return await client.isAuthenticated();
    } else {
        console.warn("Internet Identity is unavailable");
        return undefined;
    }
};

// Disconnect from Internet Identity
export const disconnectInternetIdentity = async (client: AuthClient) => {
    await client.logout();
};

// Function to create an actor for a given canister ID and IDL factory
export const createActor = async (canisterId: string, idlFactory: IDL.InterfaceFactory, identity: Identity) => {
    const host = process.env.DFX_NETWORK !== "local" ? window.location.href : "http://127.0.0.1:4943";
    const agent = new HttpAgent({ identity, host });

    if (process.env.DFX_NETWORK === "local") {
        await agent.fetchRootKey();
    }

    return Actor.createActor(idlFactory, { agent, canisterId });
};

// Function to handle opening a position
export const handleOpenPosition = async (
    actor: any,
    whitelist: string[],
    principal: Principal | undefined,
    amount: bigint,
    frequency: Frequency,
    purchasesLeft: bigint
) => {
    const position = {
        tokenToSell: Principal.fromText(whitelist[2]),
        beneficiary: principal,
        tokenToBuy: Principal.fromText(whitelist[3]),
        lastPurchaseResult: [],
        purchaseHistory: [],
        nextRunTime: [],
        amountToSell: amount,
        frequency: frequency,
        purchasesLeft: purchasesLeft,
    };

    try {
        if (actor.openPosition && principal) {
            return await actor.openPosition(position);
        }
    } catch (error) {
        console.warn("Error opening position:", error);
        throw error;
    }
};
