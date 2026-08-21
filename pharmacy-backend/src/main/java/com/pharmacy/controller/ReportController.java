package com.pharmacy.controller;

import com.pharmacy.dto.DailySalesResponse;
import com.pharmacy.dto.ProfitReportResponse;
import com.pharmacy.dto.TopMedicineResponse;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;
    private final UserRepository userRepository;

    private User currentUser(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
    }

    // e.g. GET /api/reports/profit?month=2026-08
    @GetMapping("/profit")
    public ProfitReportResponse monthlyProfit(
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month, Authentication auth) {
        return reportService.monthlyProfit(month, currentUser(auth));
    }

    // e.g. GET /api/reports/top-medicines?month=2026-08&limit=5
    @GetMapping("/top-medicines")
    public List<TopMedicineResponse> topMedicines(
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month,
            @RequestParam(defaultValue = "5") int limit,
            Authentication auth) {
        return reportService.topMedicines(month, currentUser(auth), limit);
    }

    // e.g. GET /api/reports/daily-sales?days=7
    @GetMapping("/daily-sales")
    public List<DailySalesResponse> dailySales(
            @RequestParam(defaultValue = "7") int days, Authentication auth) {
        return reportService.dailySales(days, currentUser(auth));
    }
}
