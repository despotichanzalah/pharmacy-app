package com.pharmacy.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

// Verifies a Google "ID token" the frontend received from Google Sign-In, using Google's own
// tokeninfo endpoint — Google validates the signature/expiry for us, we just check it's really
// meant for our app and that the email is verified.
@Service
public class GoogleAuthService {

    private static final String TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo?id_token=";

    @Value("${google.client-id}")
    private String googleClientId;

    private final RestTemplate restTemplate = new RestTemplate();

    @SuppressWarnings("unchecked")
    public Map<String, Object> verify(String idToken) {
        Map<String, Object> tokenInfo;
        try {
            tokenInfo = restTemplate.getForObject(TOKENINFO_URL + idToken, Map.class);
        } catch (RestClientException e) {
            throw new IllegalArgumentException("Could not verify Google sign-in — the token may have expired. Please try again.");
        }

        if (tokenInfo == null) {
            throw new IllegalArgumentException("Could not verify Google sign-in.");
        }

        String aud = String.valueOf(tokenInfo.get("aud"));
        if (googleClientId == null || googleClientId.isBlank() || !googleClientId.equals(aud)) {
            throw new IllegalArgumentException("This Google sign-in was not issued for this app.");
        }

        if (!"true".equals(String.valueOf(tokenInfo.get("email_verified")))) {
            throw new IllegalArgumentException("Your Google email isn't verified.");
        }

        return tokenInfo; // contains "email", "name", etc.
    }
}
