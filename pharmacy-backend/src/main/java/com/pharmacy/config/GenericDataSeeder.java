package com.pharmacy.config;

import com.pharmacy.model.Generic;
import com.pharmacy.repository.GenericRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

// Seeds a starter list of common generics on first run, so shops don't start from an empty list.
// Safe to leave in place — it only inserts when the table is empty.
@Component
@RequiredArgsConstructor
public class GenericDataSeeder implements CommandLineRunner {

    private final GenericRepository genericRepository;

    private static final List<String> STARTER_GENERICS = List.of(
        "Paracetamol", "Ibuprofen", "Aspirin", "Diclofenac", "Mefenamic Acid", "Naproxen",
        "Tramadol", "Codeine",
        "Amoxicillin", "Amoxicillin + Clavulanic Acid", "Azithromycin", "Ciprofloxacin",
        "Levofloxacin", "Ofloxacin", "Metronidazole", "Cefixime", "Ceftriaxone", "Doxycycline",
        "Erythromycin", "Clarithromycin", "Nitrofurantoin",
        "Omeprazole", "Esomeprazole", "Pantoprazole", "Lansoprazole", "Ranitidine",
        "Domperidone", "Metoclopramide", "Ondansetron", "Loperamide", "Simethicone",
        "Lactulose", "Bisacodyl", "Senna", "Hyoscine", "Aluminium Hydroxide", "Magnesium Hydroxide",
        "Cetirizine", "Loratadine", "Chlorpheniramine", "Diphenhydramine", "Promethazine",
        "Salbutamol", "Montelukast", "Dextromethorphan", "Guaifenesin", "Ambroxol", "Bromhexine",
        "Pseudoephedrine", "Caffeine",
        "Metformin", "Glimepiride", "Insulin Glargine", "Insulin NPH",
        "Amlodipine", "Atenolol", "Losartan", "Enalapril", "Nifedipine", "Verapamil",
        "Propranolol", "Metoprolol", "Carvedilol", "Furosemide", "Spironolactone",
        "Hydrochlorothiazide", "Digoxin",
        "Atorvastatin", "Simvastatin", "Rosuvastatin", "Clopidogrel", "Warfarin",
        "Tranexamic Acid",
        "Levothyroxine", "Prednisolone", "Dexamethasone", "Hydrocortisone", "Betamethasone",
        "Diazepam", "Alprazolam", "Sertraline", "Fluoxetine", "Amitriptyline",
        "Vitamin B Complex", "Vitamin C", "Vitamin D3", "Vitamin K", "Calcium Carbonate",
        "Ferrous Sulfate", "Folic Acid", "Multivitamins", "Zinc Sulfate",
        "Miconazole", "Clotrimazole", "Fluconazole", "Ketoconazole", "Mupirocin",
        "Chlorhexidine", "Povidone Iodine", "ORS (Oral Rehydration Salts)"
    );

    @Override
    public void run(String... args) {
        if (genericRepository.count() > 0) return; // already seeded — don't duplicate

        for (String name : STARTER_GENERICS) {
            genericRepository.findByNameIgnoreCase(name)
                    .orElseGet(() -> genericRepository.save(new Generic(null, name)));
        }
    }
}
