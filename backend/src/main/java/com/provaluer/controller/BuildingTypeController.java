package com.provaluer.controller;

import com.provaluer.model.AreaUnit;
import com.provaluer.model.BuildingType;
import com.provaluer.model.StructureType;
import com.provaluer.repository.AreaUnitRepository;
import com.provaluer.repository.BuildingTypeRepository;
import com.provaluer.repository.StructureTypeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class BuildingTypeController {

    @Autowired
    private BuildingTypeRepository buildingTypeRepository;

    @Autowired
    private AreaUnitRepository areaUnitRepository;

    @Autowired
    private StructureTypeRepository structureTypeRepository;

    // 1. Building Types
    @GetMapping("/building-types")
    public ResponseEntity<List<BuildingType>> getBuildingTypes() {
        return ResponseEntity.ok(buildingTypeRepository.findByIsActiveTrueOrderByNameAsc());
    }

    @GetMapping("/admin/building-types")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<List<BuildingType>> getAllBuildingTypes() {
        return ResponseEntity.ok(buildingTypeRepository.findAll());
    }

    @PostMapping("/admin/building-types")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<BuildingType> createBuildingType(@RequestBody BuildingType buildingType) {
        buildingType.setId(null);
        buildingType.setCreatedAt(LocalDateTime.now());
        buildingType.setUpdatedAt(LocalDateTime.now());
        return ResponseEntity.ok(buildingTypeRepository.save(buildingType));
    }

    @PutMapping("/admin/building-types/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<BuildingType> updateBuildingType(@PathVariable Long id, @RequestBody BuildingType update) {
        BuildingType existing = buildingTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Building type not found"));
        existing.setName(update.getName());
        existing.setDefaultUsefulLife(update.getDefaultUsefulLife());
        existing.setActive(update.isActive());
        existing.setUpdatedAt(LocalDateTime.now());
        return ResponseEntity.ok(buildingTypeRepository.save(existing));
    }

    @DeleteMapping("/admin/building-types/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> deleteBuildingType(@PathVariable Long id) {
        BuildingType existing = buildingTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Building type not found"));
        existing.setActive(!existing.isActive()); // Toggle active
        existing.setUpdatedAt(LocalDateTime.now());
        buildingTypeRepository.save(existing);
        return ResponseEntity.ok(Map.of("status", "SUCCESS", "isActive", existing.isActive()));
    }

    // 2. Area Units
    @GetMapping("/area-units")
    public ResponseEntity<List<AreaUnit>> getAreaUnits() {
        return ResponseEntity.ok(areaUnitRepository.findByIsActiveTrueOrderByUnitNameAsc());
    }

    @PostMapping("/admin/area-units")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<AreaUnit> createAreaUnit(@RequestBody AreaUnit areaUnit) {
        areaUnit.setId(null);
        areaUnit.setCreatedAt(LocalDateTime.now());
        areaUnit.setUpdatedAt(LocalDateTime.now());
        return ResponseEntity.ok(areaUnitRepository.save(areaUnit));
    }

    // 3. Structure Types
    @GetMapping("/structure-types")
    public ResponseEntity<List<StructureType>> getStructureTypes() {
        return ResponseEntity.ok(structureTypeRepository.findByIsActiveTrueOrderBySortOrderAsc());
    }

    @PostMapping("/admin/structure-types")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<StructureType> createStructureType(@RequestBody StructureType structureType) {
        structureType.setId(null);
        structureType.setCreatedAt(LocalDateTime.now());
        structureType.setUpdatedAt(LocalDateTime.now());
        return ResponseEntity.ok(structureTypeRepository.save(structureType));
    }
}
