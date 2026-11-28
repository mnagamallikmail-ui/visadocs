package com.provaluer.service;

import com.maxmind.db.CHMCache;
import com.maxmind.geoip2.DatabaseReader;
import com.maxmind.geoip2.model.CityResponse;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;

/**
 * Local MaxMind GeoLite2 City IP-to-Location lookup service.
 * Zero external API calls and zero network latency on requests.
 */
@Service
public class GeoIpService {

    private static final Logger log = LoggerFactory.getLogger(GeoIpService.class);

    public record GeoLocation(String country, String state, String city) {
        public static final GeoLocation UNKNOWN = new GeoLocation("Unknown", "Unknown", "Unknown");
    }

    @Value("${app.geoip.database-path:storage/geoip/GeoLite2-City.mmdb}")
    private String databasePath;

    private DatabaseReader databaseReader;

    @PostConstruct
    public void init() {
        try {
            File dbFile = new File(databasePath);
            if (dbFile.exists() && dbFile.isFile()) {
                databaseReader = new DatabaseReader.Builder(dbFile)
                        .withCache(new CHMCache())
                        .build();
                log.info("Loaded MaxMind GeoLite2 City database from {}", dbFile.getAbsolutePath());
                return;
            }
            ClassPathResource classpathDb = new ClassPathResource("geoip/GeoLite2-City.mmdb");
            if (classpathDb.exists()) {
                try (InputStream is = classpathDb.getInputStream()) {
                    databaseReader = new DatabaseReader.Builder(is)
                            .withCache(new CHMCache())
                            .build();
                    log.info("Loaded MaxMind GeoLite2 City database from classpath:geoip/GeoLite2-City.mmdb");
                    return;
                }
            }
            log.warn("GeoLite2-City.mmdb not found at '{}' or classpath:geoip/GeoLite2-City.mmdb; location lookups will fall back to Unknown", databasePath);
        } catch (Exception e) {
            log.warn("Failed to initialize GeoLite2 database reader: {}; falling back to Unknown", e.getMessage());
        }
    }

    @PreDestroy
    public void close() {
        if (databaseReader != null) {
            try {
                databaseReader.close();
            } catch (IOException ignored) {
            }
        }
    }

    public boolean isDatabaseLoaded() {
        return databaseReader != null;
    }

    /**
     * Resolves client IP prioritizing X-Forwarded-For, then X-Real-IP, then remoteAddr.
     */
    public String extractClientIp(HttpServletRequest request) {
        if (request == null) return "";
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            for (String part : xff.split(",")) {
                String candidate = part.trim();
                if (!candidate.isEmpty() && !"unknown".equalsIgnoreCase(candidate)) {
                    return candidate;
                }
            }
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank() && !"unknown".equalsIgnoreCase(realIp)) {
            return realIp.trim();
        }
        String remoteAddr = request.getRemoteAddr();
        return remoteAddr != null ? remoteAddr.trim() : "";
    }

    public GeoLocation lookup(String ipAddress) {
        if (databaseReader == null || ipAddress == null || ipAddress.isBlank()) {
            return GeoLocation.UNKNOWN;
        }
        try {
            InetAddress addr = InetAddress.getByName(ipAddress.trim());
            if (addr.isAnyLocalAddress() || addr.isLoopbackAddress() || addr.isSiteLocalAddress()) {
                return GeoLocation.UNKNOWN;
            }
            CityResponse response = databaseReader.city(addr);
            return fromCityResponse(response);
        } catch (Exception e) {
            return GeoLocation.UNKNOWN;
        }
    }

    static GeoLocation fromCityResponse(CityResponse response) {
        if (response == null) return GeoLocation.UNKNOWN;
        String country = response.getCountry() != null && response.getCountry().getName() != null
                && !response.getCountry().getName().isBlank()
                ? response.getCountry().getName() : "Unknown";
        String state = response.getMostSpecificSubdivision() != null
                && response.getMostSpecificSubdivision().getName() != null
                && !response.getMostSpecificSubdivision().getName().isBlank()
                ? response.getMostSpecificSubdivision().getName() : "Unknown";
        String city = response.getCity() != null && response.getCity().getName() != null
                && !response.getCity().getName().isBlank()
                ? response.getCity().getName() : "Unknown";
        return new GeoLocation(country, state, city);
    }
}

