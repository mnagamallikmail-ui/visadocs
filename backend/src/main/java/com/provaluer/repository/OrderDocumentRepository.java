package com.provaluer.repository;

import com.provaluer.model.OrderDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface OrderDocumentRepository extends JpaRepository<OrderDocument, Long> {
    List<OrderDocument> findAllByOrderId(Long orderId);
}
