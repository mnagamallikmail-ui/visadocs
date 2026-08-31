package com.provaluer.repository;

import com.provaluer.model.AreaUnit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AreaUnitRepository extends JpaRepository<AreaUnit, Long> {
    List<AreaUnit> findByIsActiveTrueOrderByUnitNameAsc();
    Optional<AreaUnit> findByUnitNameIgnoreCase(String unitName);
}
