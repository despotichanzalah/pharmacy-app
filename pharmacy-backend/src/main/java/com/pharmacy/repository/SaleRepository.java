package com.pharmacy.repository;

import com.pharmacy.model.Sale;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface SaleRepository extends JpaRepository<Sale, Long> {
    List<Sale> findByShopIdAndSaleDateBetween(Long shopId, LocalDateTime start, LocalDateTime end);
    List<Sale> findByShopIdOrderBySaleDateDesc(Long shopId);
}
