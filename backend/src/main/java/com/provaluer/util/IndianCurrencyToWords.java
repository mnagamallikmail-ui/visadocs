package com.provaluer.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class IndianCurrencyToWords {

    private static final String[] UNITS = {
            "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
            "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
            "Seventeen", "Eighteen", "Nineteen"
    };

    private static final String[] TENS = {
            "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    };

    /**
     * Converts an amount into banking standard words format:
     * e.g. 5,75,00,000 -> "Rupees Five Crore Seventy Five Lakh Only"
     */
    public static String convertToWords(BigDecimal amount) {
        if (amount == null) return "Rupees Zero Only";

        BigDecimal rounded = amount.setScale(2, RoundingMode.HALF_UP);
        if (rounded.signum() == 0) {
            return "Rupees Zero Only";
        }

        boolean isNegative = rounded.signum() < 0;
        BigDecimal absAmount = rounded.abs();

        long rupees = absAmount.longValue();
        int paise = absAmount.remainder(BigDecimal.ONE).movePointRight(2).intValue();

        StringBuilder sb = new StringBuilder();
        if (isNegative) {
            sb.append("Minus ");
        }

        sb.append("Rupees ");

        if (rupees > 0) {
            sb.append(convertNumberToWords(rupees));
        } else {
            sb.append("Zero");
        }

        if (paise > 0) {
            sb.append(" and ").append(convertTwoDigits(paise)).append(" Paise");
        }

        sb.append(" Only");

        return sb.toString().replaceAll("\\s+", " ").trim();
    }

    private static String convertNumberToWords(long n) {
        if (n == 0) return "";

        StringBuilder words = new StringBuilder();

        // Crores (1,00,00,000)
        long crore = n / 10000000L;
        long remCrore = n % 10000000L;
        if (crore > 0) {
            words.append(convertNumberToWords(crore)).append(" Crore ");
        }

        // Lakhs (1,00,000)
        long lakh = remCrore / 100000L;
        long remLakh = remCrore % 100000L;
        if (lakh > 0) {
            words.append(convertTwoDigits((int) lakh)).append(" Lakh ");
        }

        // Thousands (1,000)
        long thousand = remLakh / 1000L;
        long remThousand = remLakh % 1000L;
        if (thousand > 0) {
            words.append(convertTwoDigits((int) thousand)).append(" Thousand ");
        }

        // Hundreds (100)
        long hundred = remThousand / 100L;
        long remHundred = remThousand % 100L;
        if (hundred > 0) {
            words.append(UNITS[(int) hundred]).append(" Hundred ");
        }

        // Tens & Units
        if (remHundred > 0) {
            words.append(convertTwoDigits((int) remHundred)).append(" ");
        }

        return words.toString().trim();
    }

    private static String convertTwoDigits(int n) {
        if (n < 20) {
            return UNITS[n];
        }
        int ten = n / 10;
        int unit = n % 10;
        if (unit > 0) {
            return TENS[ten] + " " + UNITS[unit];
        } else {
            return TENS[ten];
        }
    }
}
