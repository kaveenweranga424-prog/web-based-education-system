package util;

import org.mindrot.jbcrypt.BCrypt;

public class PasswordUtil {

    private static final int SALT_ROUNDS = 12;

    private PasswordUtil() {
        // Prevent object creation
    }

    public static String hashPassword(
            String plainPassword
    ) {

        if (plainPassword == null ||
                plainPassword.isBlank()) {

            throw new IllegalArgumentException(
                    "Password cannot be empty."
            );
        }

        return BCrypt.hashpw(
                plainPassword,
                BCrypt.gensalt(SALT_ROUNDS)
        );
    }

    public static boolean checkPassword(
            String plainPassword,
            String hashedPassword
    ) {

        if (plainPassword == null ||
                hashedPassword == null ||
                plainPassword.isBlank() ||
                hashedPassword.isBlank()) {

            return false;
        }

        try {

            return BCrypt.checkpw(
                    plainPassword,
                    hashedPassword
            );

        } catch (IllegalArgumentException e) {

            return false;
        }
    }

    // Temporary test
    public static void main(String[] args) {

        String password = "Test123";

        String hashedPassword =
                hashPassword(password);

        System.out.println(
                "Original: " + password
        );

        System.out.println(
                "Hash: " + hashedPassword
        );

        System.out.println(
                "Correct password: "
                        + checkPassword(
                        password,
                        hashedPassword
                )
        );

        System.out.println(
                "Wrong password: "
                        + checkPassword(
                        "Wrong123",
                        hashedPassword
                )
        );
    }
}