package com.pharmacy.controller;

import com.pharmacy.dto.BatchRequest;
import com.pharmacy.dto.MedicineRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Batch;
import com.pharmacy.model.Medicine;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.InventoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;
    private final UserRepository userRepository;

    private User currentUser(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
    }

    // --- Medicines ---

    @PostMapping("/medicines")
    public Medicine addMedicine(@Valid @RequestBody MedicineRequest request, Authentication auth) {
        return inventoryService.addMedicine(request, currentUser(auth));
    }

    @GetMapping("/medicines")
    public List<Medicine> searchMedicines(@RequestParam(required = false) String query, Authentication auth) {
        return inventoryService.searchMedicines(query, currentUser(auth));
    }

    @PutMapping("/medicines/{id}")
    public Medicine updateMedicine(@PathVariable Long id, @Valid @RequestBody MedicineRequest request, Authentication auth) {
        return inventoryService.updateMedicine(id, request, currentUser(auth));
    }

    @DeleteMapping("/medicines/{id}")
    public ResponseEntity<Void> deleteMedicine(@PathVariable Long id, Authentication auth) {
        inventoryService.deleteMedicine(id, currentUser(auth));
        return ResponseEntity.noContent().build();
    }

    // --- Batches / stock ---

    @PostMapping("/batches")
    public Batch addBatch(@Valid @RequestBody BatchRequest request, Authentication auth) {
        return inventoryService.addBatch(request, currentUser(auth));
    }

    @GetMapping("/batches/low-stock")
    public List<Batch> lowStock(@RequestParam(defaultValue = "10") int threshold, Authentication auth) {
        return inventoryService.lowStockBatches(threshold, currentUser(auth));
    }

    @GetMapping("/batches/expiring")
    public List<Batch> expiringSoon(@RequestParam(defaultValue = "30") int days, Authentication auth) {
        return inventoryService.expiringBatches(days, currentUser(auth));
    }

    @GetMapping("/batches")
    public List<Batch> allBatches(@RequestParam(required = false) Long medicineId, Authentication auth) {
        return medicineId != null
                ? inventoryService.batchesForMedicine(medicineId, currentUser(auth))
                : inventoryService.allBatches(currentUser(auth));
    }

    @PutMapping("/batches/{id}")
    public Batch updateBatch(@PathVariable Long id, @Valid @RequestBody BatchRequest request, Authentication auth) {
        return inventoryService.updateBatch(id, request, currentUser(auth));
    }

    @DeleteMapping("/batches/{id}")
    public ResponseEntity<Void> deleteBatch(@PathVariable Long id, Authentication auth) {
        inventoryService.deleteBatch(id, currentUser(auth));
        return ResponseEntity.noContent().build();
    }
}
