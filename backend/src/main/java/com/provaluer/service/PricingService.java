package com.provaluer.service;

import com.provaluer.model.PricingConfig;
import com.provaluer.repository.PricingConfigRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class PricingService {

    @Autowired
    private PricingConfigRepository pricingConfigRepository;

    public static final String KEY_VISA_FLAT_FEE         = "visa_flat_fee";
    public static final String KEY_STANDARD_FLAT_FEE     = "standard_flat_fee";
    public static final String KEY_HIGH_VALUE_THRESHOLD  = "high_value_threshold";
    public static final String KEY_HIGH_VALUE_RATE        = "high_value_rate";

    private BigDecimal getConfig(String key, BigDecimal fallback) {
        return pricingConfigRepository.findByConfigKey(key)
                .map(PricingConfig::getConfigValue)
                .orElse(fallback);
    }

    public BigDecimal calculateFee(String purpose, BigDecimal estimatedValue, BigDecimal finalValue) {
        BigDecimal visaFee       = getConfig(KEY_VISA_FLAT_FEE, new BigDecimal("3000"));
        BigDecimal standardFee   = getConfig(KEY_STANDARD_FLAT_FEE, new BigDecimal("10000"));
        BigDecimal hvThreshold   = getConfig(KEY_HIGH_VALUE_THRESHOLD, new BigDecimal("100000000"));
        BigDecimal hvRate        = getConfig(KEY_HIGH_VALUE_RATE, new BigDecimal("0.001"));

        if ("Visa".equalsIgnoreCase(purpose)) return visaFee;

        BigDecimal val = finalValue != null ? finalValue : (estimatedValue != null ? estimatedValue : BigDecimal.ZERO);
        if (val.compareTo(hvThreshold) > 0) return val.multiply(hvRate);
        return standardFee;
    }

    public List<PricingConfig> getAllConfigs() {
        return pricingConfigRepository.findAll();
    }

    public PricingConfig updateConfig(String key, BigDecimal value, Long updatedBy) {
        PricingConfig config = pricingConfigRepository.findByConfigKey(key)
                .orElseThrow(() -> new RuntimeException("Pricing config key not found: " + key));
        config.setConfigValue(value);
        config.setUpdatedBy(updatedBy);
        config.setUpdatedAt(LocalDateTime.now());
        return pricingConfigRepository.save(config);
    }
}
