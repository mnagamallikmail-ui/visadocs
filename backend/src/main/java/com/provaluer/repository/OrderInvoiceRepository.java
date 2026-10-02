package com.provaluer.repository;

import com.provaluer.model.OrderInvoice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderInvoiceRepository extends JpaRepository<OrderInvoice, Long> {
    Optional<OrderInvoice> findByOrderId(Long orderId);
    Optional<OrderInvoice> findByInvoiceNumber(String invoiceNumber);
    List<OrderInvoice> findAllByOrderId(Long orderId);
    boolean existsByOrderId(Long orderId);
}
