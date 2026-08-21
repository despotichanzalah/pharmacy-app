package com.pharmacy.repository;

import com.pharmacy.model.Purchase;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PurchaseRepository extends JpaRepository<Purchase, Long> {
    List<Purchase> findByShopId(Long shopId);
}
