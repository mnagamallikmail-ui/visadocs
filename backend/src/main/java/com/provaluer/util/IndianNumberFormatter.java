package com.provaluer.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class IndianNumberFormatter {

    /**
     * Formats a BigDecimal or Number into the standard Indian numbering system (e.g. 5,75,00,000 or 1,00,000.00).
     */
    public static String format(BigDecimal number) {
        if (number == null) return "0";
        return format(number, false);
    }

    public static String format(BigDecimal number, boolean includeDecimals) {
        if (number == null) return "0";
        BigDecimal rounded = number.setScale(2, RoundingMode.HALF_UP);
        boolean isNegative = rounded.signum() < 0;
        BigDecimal absVal = rounded.abs();

        long integerPart = absVal.longValue();
        int decimalPart = absVal.remainder(BigDecimal.ONE).movePointRight(2).intValue();

        String intStr = Long.toString(integerPart);
        StringBuilder sb = new StringBuilder();

        int len = intStr.length();
        if (len <= 3) {
            sb.append(intStr);
        } else {
            // Last 3 digits (Hundreds)
            String lastThree = intStr.substring(len - 3);
            String remaining = intStr.substring(0, len - 3);

            StringBuilder remFormatted = new StringBuilder();
            int count = 0;
            for (int i = remaining.length() - 1; i >= 0; i--) {
                remFormatted.insert(0, remaining.charAt(i));
                count++;
                if (count % 2 == 0 && i > 0) {
                    remFormatted.insert(0, ",");
                }
            }
            sb.append(remFormatted).append(",").append(lastThree);
        }

        if (isNegative) {
            sb.insert(0, "-");
        }

        if (includeDecimals && decimalPart > 0) {
            sb.append(String.format(".%02d", decimalPart));
        }

        return sb.toString();
    }

    public static String format(double value) {
        return format(BigDecimal.valueOf(value), false);
    }

    public static String format(long value) {
        return format(BigDecimal.valueOf(value), false);
    }
}
