import { useState, useEffect } from "react";

export interface FormErrors {
    buyOption?: string;
    sellOption?: string;
    amount?: string;
    endDate?: string;
    frequency?: string;
}

export const validateForm = (
    buyOption: string,
    sellOption: string,
    amount: number,
    endDate: string,
    frequency: string
): FormErrors => {
    const errors: FormErrors = {};
    const today = new Date().toISOString().split("T")[0];

    if (!buyOption) {
        errors.buyOption = "Please select a token to buy.";
    }

    if (!sellOption) {
        errors.sellOption = "Please select a token to sell.";
    }

    if (!amount || amount <= 0) {
        errors.amount = "Amount must be greater than zero.";
    }

    if (!endDate) {
        errors.endDate = "Please select an end date.";
    } else if (endDate < today) {
        errors.endDate = "End date cannot be earlier than today.";
    }

    if (!frequency) {
        errors.frequency = "Please select a frequency.";
    }

    return errors;
};

export const useFormValidation = (
    buyOption: string,
    sellOption: string,
    amount: number,
    endDate: string,
    frequency: string
) => {
    const [errors, setErrors] = useState<FormErrors>({});

    useEffect(() => {
        const formErrors = validateForm(buyOption, sellOption, amount, endDate, frequency);
        setErrors(formErrors);
    }, [buyOption, sellOption, amount, endDate, frequency]);

    return errors;
};
