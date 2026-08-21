package com.pharmacy.repository;

import com.pharmacy.model.Batch;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface BatchRepository extends JpaRepository<Batch, Long> {
    List<Batch> findByMedicineId(Long medicineId);
    List<Batch> findByShopId(Long shopId);
    List<Batch> findByShopIdAndExpiryDateBefore(Long shopId, LocalDate date);
    List<Batch> findByShopIdAndQuantityLessThanEqual(Long shopId, Integer quantity);
}
