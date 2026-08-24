package com.pharmacy.exception;

import lombok.Getter;

// Thrown when a Google sign-in succeeds (the token is valid) but no account exists yet for
// that email — the frontend catches this and sends the person to finish registration.
@Getter
public class GoogleAccountNotRegisteredException extends RuntimeException {
    private final String email;
    private final String name;

    public GoogleAccountNotRegisteredException(String email, String name) {
        super("No account found for this Google email");
        this.email = email;
        this.name = name;
    }
}
