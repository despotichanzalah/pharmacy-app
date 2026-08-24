package com.pharmacy.repository;

import com.pharmacy.model.SaleItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SaleItemRepository extends JpaRepository<SaleItem, Long> {
    List<SaleItem> findBySaleId(Long saleId);
    boolean existsByBatchId(Long batchId);
}
