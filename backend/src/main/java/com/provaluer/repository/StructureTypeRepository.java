package com.provaluer.repository;

import com.provaluer.model.StructureType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StructureTypeRepository extends JpaRepository<StructureType, Long> {
    List<StructureType> findByIsActiveTrueOrderBySortOrderAsc();
    Optional<StructureType> findByNameIgnoreCase(String name);
}
