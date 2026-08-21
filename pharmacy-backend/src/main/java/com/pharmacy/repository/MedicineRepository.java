package com.pharmacy.repository;

import com.pharmacy.model.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MedicineRepository extends JpaRepository<Medicine, Long> {
    List<Medicine> findByShopIdAndNameContainingIgnoreCase(Long shopId, String name);
    List<Medicine> findByShopId(Long shopId);
}
