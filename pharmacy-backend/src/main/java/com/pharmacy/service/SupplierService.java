package com.pharmacy.service;

import com.pharmacy.dto.SupplierRequest;
import com.pharmacy.model.Supplier;
import com.pharmacy.model.User;
import com.pharmacy.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SupplierService {

    private final SupplierRepository supplierRepository;

    public Supplier addSupplier(SupplierRequest req, User currentUser) {
        Supplier supplier = new Supplier();
        supplier.setName(req.getName());
        supplier.setContact(req.getContact());
        supplier.setAddress(req.getAddress());
        supplier.setShop(currentUser.getShop());
        return supplierRepository.save(supplier);
    }

    public List<Supplier> listSuppliers(User currentUser) {
        return supplierRepository.findByShopId(currentUser.getShop().getId());
    }
}
