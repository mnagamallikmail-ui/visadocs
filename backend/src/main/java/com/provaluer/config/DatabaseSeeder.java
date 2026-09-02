package com.provaluer.config;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Arrays;

@Component
public class DatabaseSeeder {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    @Autowired
    private PricingConfigRepository pricingConfigRepository;

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @EventListener(ApplicationReadyEvent.class)
    public void seedDatabase() {
        // Seed users if empty
        if (userRepository.count() == 0) {
            String encodedPassword = passwordEncoder.encode("password");

            User superAdmin = new User("admin", "admin@provaluer.com", encodedPassword, UserRole.SUPER_ADMIN, "9000000000", "v1.0");
            superAdmin.setFullName("Master System Administrator");

            User pa = new User("poojitha", "poojitha@provaluer.com", encodedPassword, UserRole.PA, "9876543211", "v1.0");
            pa.setFullName("Poojitha Property Analyst");

            User spa = new User("divya", "divya@provaluer.com", encodedPassword, UserRole.SPA, "9876543212", "v1.0");
            spa.setFullName("Divya Senior Property Analyst");

            User client = new User("naga", "naga@provaluer.com", encodedPassword, UserRole.CLIENT, "9876543213", "v1.0");
            client.setFullName("Naga Client");

            userRepository.saveAll(Arrays.asList(superAdmin, pa, spa, client));

            // Seed performance ledger for PA and SPA
            // Reload from repo to get generated IDs
            User savedPa = userRepository.findByUsernameIgnoreCase("poojitha").orElse(null);
            User savedSpa = userRepository.findByUsernameIgnoreCase("divya").orElse(null);

            if (savedPa != null) {
                performanceLedgerRepository.save(new PerformanceLedger(savedPa.getId()));
            }
            if (savedSpa != null) {
                performanceLedgerRepository.save(new PerformanceLedger(savedSpa.getId()));
            }
        }

        // Seed system settings if empty
        if (systemSettingRepository.count() == 0) {
            systemSettingRepository.save(new SystemSetting("tc_version", "v1.0"));
            systemSettingRepository.save(new SystemSetting("system_version", "2.0.0"));
            systemSettingRepository.save(new SystemSetting("platform_name", "ProValuer Commercial"));
        }

        // Seed pricing config if empty
        if (pricingConfigRepository.count() == 0) {
            PricingConfig visaFee = new PricingConfig();
            visaFee.setConfigKey("visa_flat_fee");
            visaFee.setConfigValue(new BigDecimal("3000.0000"));
            visaFee.setDescription("Flat fee (INR) for Visa purpose valuations");
            pricingConfigRepository.save(visaFee);

            PricingConfig standardFee = new PricingConfig();
            standardFee.setConfigKey("standard_flat_fee");
            standardFee.setConfigValue(new BigDecimal("10000.0000"));
            standardFee.setDescription("Flat fee (INR) for standard valuations under high-value threshold");
            pricingConfigRepository.save(standardFee);

            PricingConfig highValThreshold = new PricingConfig();
            highValThreshold.setConfigKey("high_value_threshold");
            highValThreshold.setConfigValue(new BigDecimal("100000000.0000"));
            highValThreshold.setDescription("Property value threshold (INR) above which percentage fee applies");
            pricingConfigRepository.save(highValThreshold);

            PricingConfig highValRate = new PricingConfig();
            highValRate.setConfigKey("high_value_rate");
            highValRate.setConfigValue(new BigDecimal("0.0010"));
            highValRate.setDescription("Fee rate (e.g. 0.001 = 0.1%) applied to values above threshold");
            pricingConfigRepository.save(highValRate);
        }
    }
}
