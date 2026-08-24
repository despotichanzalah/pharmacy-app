package com.pharmacy.service;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${app.frontend-url}")
    private String frontendUrl;

    @Value("${app.mail-from}")
    private String fromAddress;

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
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);
            mailSender.send(message);
        } catch (Exception e) {
            // Never let an email failure break login/registration/reset flows.
            log.warn("Failed to send email to {}: {}", to, e.getMessage());
        }
    }
}
