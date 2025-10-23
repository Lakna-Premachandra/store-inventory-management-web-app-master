package UTILS;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PasswordUtil {
    private static final Logger LOGGER = Logger.getLogger(PasswordUtil.class.getName());
    
    /**
     * Hash password using SHA-256 algorithm
     * @param password Plain text password
     * @return Hashed password as hexadecimal string
     */
    public static String hashPassword(String password) {
        if (password == null || password.isEmpty()) {
            throw new IllegalArgumentException("Password cannot be null or empty");
        }
        
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(password.getBytes("UTF-8"));
            
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error hashing password", e);
            throw new RuntimeException("Password hashing failed", e);
        }
    }
    
    /**
     * Verify if plain password matches hashed password
     * @param plainPassword Plain text password to verify
     * @param hashedPassword Stored hashed password
     * @return true if passwords match, false otherwise
     */
    public static boolean verifyPassword(String plainPassword, String hashedPassword) {
        if (plainPassword == null || hashedPassword == null) {
            return false;
        }
        
        try {
            String hashOfInput = hashPassword(plainPassword);
            return hashOfInput.equals(hashedPassword);
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Error verifying password", e);
            return false;
        }
    }
    
    /**
     * Validate password strength
     * @param password Password to validate
     * @return true if password meets requirements, false otherwise
     */
    public static boolean isValidPassword(String password) {
        if (password == null || password.length() < 6) {
            return false;
        }
        
        // Check for at least one digit and one letter
        boolean hasDigit = false;
        boolean hasLetter = false;
        
        for (char c : password.toCharArray()) {
            if (Character.isDigit(c)) {
                hasDigit = true;
            }
            if (Character.isLetter(c)) {
                hasLetter = true;
            }
            if (hasDigit && hasLetter) {
                break; // Early exit if both conditions met
            }
        }
        
        return hasDigit && hasLetter;
    }
    
    /**
     * Get password strength description
     * @param password Password to check
     * @return Description of password requirements
     */
    public static String getPasswordRequirements() {
        return "Password must be at least 6 characters long and contain both letters and numbers";
    }
}