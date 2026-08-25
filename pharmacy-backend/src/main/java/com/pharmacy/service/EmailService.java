package com.pharmacy.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private static final String BREVO_API_URL = "https://api.brevo.com/v3/smtp/email";

    @Value("${brevo.api-key}")
    private String apiKey;

    @Value("${app.mail-from}")
    private String fromAddress;

    @Value("${app.frontend-url}")
    private String frontendUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    @Async
    public void sendPasswordResetEmail(String toEmail, String token) {
        String resetLink = frontendUrl + "/reset-password?token=" + token;
        String body = "We received a request to reset your Huny Pharmacy password.\n\n"
                + "Click the link below to choose a new password. This link expires in 1 hour:\n"
                + resetLink + "\n\n"
                + "If you didn't request this, you can safely ignore this email.";
        send(toEmail, "Reset your password", body);
    }

    @Async
    public void sendLoginAlertEmail(String adminEmail, String staffName, String staffEmail, String role) {
        String time = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd MMM yyyy, hh:mm a"));
        String body = staffName + " (" + staffEmail + ", " + role + ") just signed in to your shop.\n\n"
                + "Time: " + time + "\n\n"
                + "If this wasn't expected, consider removing their account from the Staff page.";
        send(adminEmail, "New sign-in to your shop", body);
    }

    private void send(String to, String subject, String body) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("BREVO_API_KEY is not set — skipping email to {}", to);
            return;
        }
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("api-key", apiKey);
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("accept", "application/json");

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("sender", Map.of("email", fromAddress, "name", "Huny Pharmacy"));
            payload.put("to", List.of(Map.of("email", to)));
            payload.put("subject", subject);
            payload.put("textContent", body);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(payload, headers);
            restTemplate.postForEntity(BREVO_API_URL, request, String.class);
        } catch (Exception e) {
            log.warn("Failed to send email to {}: {}", to, e.getMessage());
        }
    }
}