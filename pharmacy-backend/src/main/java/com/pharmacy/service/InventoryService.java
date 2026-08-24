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
    private final SaleItemRepository saleItemRepository;

    // --- Medicines ---

    public Medicine addMedicine(MedicineRequest req, User currentUser) {
        Medicine medicine = new Medicine();
        medicine.setShop(currentUser.getShop());
        applyMedicineFields(medicine, req);
        return medicineRepository.save(medicine);
    }

    public Medicine updateMedicine(Long id, MedicineRequest req, User currentUser) {
        Medicine medicine = medicineRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Medicine does not belong to your shop");
        }

        applyMedicineFields(medicine, req);
        return medicineRepository.save(medicine);
    }

    private void applyMedicineFields(Medicine medicine, MedicineRequest req) {
        medicine.setName(req.getName());
        medicine.setUnit(req.getUnit());
        medicine.setReorderLevel(req.getReorderLevel() != null ? req.getReorderLevel() : 10);
        medicine.setPackSize(req.getPackSize() != null && req.getPackSize() > 0 ? req.getPackSize() : 1);

        if (req.getCategoryId() != null) {
            Category category = categoryRepository.findById(req.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            medicine.setCategory(category);
        }

        medicine.setGenerics(resolveGenerics(req.getGenericIds(), req.getNewGenerics()));
    }

    public void deleteMedicine(Long id, User currentUser) {
        Medicine medicine = medicineRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Medicine not found"));

        if (!medicine.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Medicine does not belong to your shop");
        }

        if (batchRepository.existsByMedicineId(id)) {
            throw new IllegalArgumentException("Cannot delete this medicine — it still has stock batches. Delete those first.");
        }

        // Clear the generics link table first so the delete doesn't hit a foreign-key error.
        medicine.getGenerics().clear();
        medicineRepository.save(medicine);
        medicineRepository.delete(medicine);
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
        batch.setShop(currentUser.getShop());
        applyBatchFields(batch, req);
        return batchRepository.save(batch);
    }

    public Batch updateBatch(Long id, BatchRequest req, User currentUser) {
        Batch batch = batchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Batch not found"));

        if (!batch.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Batch does not belong to your shop");
        }

        applyBatchFields(batch, req);
        return batchRepository.save(batch);
    }

    private void applyBatchFields(Batch batch, BatchRequest req) {
        batch.setBatchNumber(req.getBatchNumber());
        batch.setExpiryDate(req.getExpiryDate());
        batch.setQuantity(req.getQuantity());
        batch.setPurchasePrice(req.getPurchasePrice());
        batch.setSalePrice(req.getSalePrice());

        if (req.getSupplierId() != null) {
            Supplier supplier = supplierRepository.findById(req.getSupplierId())
                    .orElseThrow(() -> new ResourceNotFoundException("Supplier not found"));
            batch.setSupplier(supplier);
        }
    }

    public void deleteBatch(Long id, User currentUser) {
        Batch batch = batchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Batch not found"));

        if (!batch.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Batch does not belong to your shop");
        }

        if (saleItemRepository.existsByBatchId(id)) {
            throw new IllegalArgumentException("Cannot delete this batch — sales have already been recorded against it. You can still edit its quantity.");
        }

        batchRepository.delete(batch);
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
