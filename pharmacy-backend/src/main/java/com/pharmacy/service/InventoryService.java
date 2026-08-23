package com.pharmacy.service;

import com.pharmacy.dto.BatchRequest;
import com.pharmacy.dto.MedicineRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.*;
import com.pharmacy.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final MedicineRepository medicineRepository;
    private final CategoryRepository categoryRepository;
    private final BatchRepository batchRepository;
    private final SupplierRepository supplierRepository;
    private final GenericRepository genericRepository;

    // --- Medicines ---

    public Medicine addMedicine(MedicineRequest req, User currentUser) {
        Medicine medicine = new Medicine();
        medicine.setName(req.getName());
        medicine.setUnit(req.getUnit());
        medicine.setReorderLevel(req.getReorderLevel() != null ? req.getReorderLevel() : 10);
        medicine.setPackSize(req.getPackSize() != null && req.getPackSize() > 0 ? req.getPackSize() : 1);
        medicine.setShop(currentUser.getShop());

        if (req.getCategoryId() != null) {
            Category category = categoryRepository.findById(req.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            medicine.setCategory(category);
        }

        medicine.setGenerics(resolveGenerics(req.getGenericIds(), req.getNewGenerics()));

        return medicineRepository.save(medicine);
    }

    // Turns a mix of existing generic IDs and freshly-typed generic names into a single set,
    // creating any generic that doesn't already exist yet (case-insensitive match first).
    private Set<Generic> resolveGenerics(List<Long> genericIds, List<String> newGenerics) {
        Set<Generic> generics = new HashSet<>();

        if (genericIds != null) {
            for (Long id : genericIds) {
                genericRepository.findById(id).ifPresent(generics::add);
            }
        }

        if (newGenerics != null) {
            for (String rawName : newGenerics) {
                if (rawName == null || rawName.isBlank()) continue;
                String name = rawName.trim();
                Generic generic = genericRepository.findByNameIgnoreCase(name)
                        .orElseGet(() -> genericRepository.save(new Generic(null, name)));
                generics.add(generic);
            }
        }

        return generics;
    }

    public List<Medicine> searchMedicines(String query, User currentUser) {
        Long shopId = currentUser.getShop().getId();
        return query == null || query.isBlank()
                ? medicineRepository.findByShopId(shopId)
                : medicineRepository.searchByNameOrGeneric(shopId, query);
    }

    // --- Batches (stock) ---

    public Batch addBatch(BatchRequest req, User currentUser) {
        Medicine medicine = medicineRepository.findById(req.getMedicineId())
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Medicine does not belong to your shop");
        }

        Batch batch = new Batch();
        batch.setMedicine(medicine);
        batch.setBatchNumber(req.getBatchNumber());
        batch.setExpiryDate(req.getExpiryDate());
        batch.setQuantity(req.getQuantity());
        batch.setPurchasePrice(req.getPurchasePrice());
        batch.setSalePrice(req.getSalePrice());
        batch.setShop(currentUser.getShop());

        if (req.getSupplierId() != null) {
            Supplier supplier = supplierRepository.findById(req.getSupplierId())
                    .orElseThrow(() -> new ResourceNotFoundException("Supplier not found"));
            batch.setSupplier(supplier);
        }
        return batchRepository.save(batch);
    }

    public List<Batch> lowStockBatches(int threshold, User currentUser) {
        return batchRepository.findByShopIdAndQuantityLessThanEqual(currentUser.getShop().getId(), threshold);
    }

    public List<Batch> expiringBatches(int withinDays, User currentUser) {
        return batchRepository.findByShopIdAndExpiryDateBefore(
                currentUser.getShop().getId(), LocalDate.now().plusDays(withinDays));
    }

    // All batches for a single medicine, scoped to the caller's shop.
    public List<Batch> batchesForMedicine(Long medicineId, User currentUser) {
        Medicine medicine = medicineRepository.findById(medicineId)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Medicine does not belong to your shop");
        }

        return batchRepository.findByMedicineId(medicineId);
    }

    // Every batch belonging to the caller's shop, regardless of medicine.
    public List<Batch> allBatches(User currentUser) {
        return batchRepository.findByShopId(currentUser.getShop().getId());
    }
}