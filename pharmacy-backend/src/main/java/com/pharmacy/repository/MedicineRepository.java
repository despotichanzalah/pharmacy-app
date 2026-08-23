package com.pharmacy.repository;

import com.pharmacy.model.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface MedicineRepository extends JpaRepository<Medicine, Long> {

    List<Medicine> findByShopId(Long shopId);

    // Matches on the brand name OR any attached generic name (e.g. searching "paracetamol"
    // should also surface "Panadol", "Calpol", etc.)
    @Query("""
        SELECT DISTINCT m FROM Medicine m
        LEFT JOIN m.generics g
        WHERE m.shop.id = :shopId
        AND (LOWER(m.name) LIKE LOWER(CONCAT('%', :query, '%'))
             OR LOWER(g.name) LIKE LOWER(CONCAT('%', :query, '%')))
        """)
    List<Medicine> searchByNameOrGeneric(@Param("shopId") Long shopId, @Param("query") String query);
}
