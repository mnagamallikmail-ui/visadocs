package com.provaluer.repository;

import com.provaluer.model.SeoSite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface SeoSiteRepository extends JpaRepository<SeoSite, Long> {
    Optional<SeoSite> findByDomain(String domain);
}
