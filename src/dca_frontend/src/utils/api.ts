import { useAuth } from "../context/AuthContext";

const { actorBackend } = useAuth();

export const getAllPosition = async () => {
    try {
        const pos = await actorBackend.getAllPositions();
        if (pos.ok) {
            return pos.ok;
        }
    } catch (error) {
        console.warn("Error fetching positions:", error);
        return undefined;
    }
};
