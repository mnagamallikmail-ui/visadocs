package com.provaluer.repository;

import com.provaluer.model.InspectionPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InspectionPhotoRepository extends JpaRepository<InspectionPhoto, Long> {

    List<InspectionPhoto> findAllByOrderIdAndIsDeletedFalseOrderByCategoryAscCaptureSequenceAsc(Long orderId);

    List<InspectionPhoto> findAllByInspectionIdAndIsDeletedFalse(Long inspectionId);

    long countByOrderIdAndIsDeletedFalse(Long orderId);

    long countByInspectionIdAndCategoryAndIsDeletedFalse(Long inspectionId, String category);

    long countByOrderIdAndCategoryAndIsDeletedFalse(Long orderId, String category);

    boolean existsByOrderIdAndMd5HashAndIsDeletedFalse(Long orderId, String md5Hash);

    Optional<InspectionPhoto> findByIdAndOrderId(Long id, Long orderId);

    Optional<InspectionPhoto> findByIdAndOrderIdAndIsDeletedFalse(Long id, Long orderId);
}
