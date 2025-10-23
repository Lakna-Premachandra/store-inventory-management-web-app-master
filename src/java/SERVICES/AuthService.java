package SERVICES;

import DAO.UserDAO;
import MODELS.User;
import UTILS.PasswordUtil;

import java.util.logging.Logger;
import java.util.regex.Pattern;

public class AuthService {
    private static final Logger LOGGER = Logger.getLogger(AuthService.class.getName());
    
    private final UserDAO userDAO;
    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@(.+)$");
    
    public AuthService() {
        this.userDAO = new UserDAO();
    }
    
    /**
     * Register a new user
     * @param user User object containing registration data
     * @return AuthResult with success status, message, and user data
     */
    public AuthResult signUp(User user) {
        try {
            LOGGER.info("Starting sign up process for user: " + (user != null ? user.getUsername() : "null"));
            
            // Validate input data
            AuthResult validationResult = validateSignUpData(user);
            if (!validationResult.isSuccess()) {
                LOGGER.warning("Sign up validation failed: " + validationResult.getMessage());
                return validationResult;
            }
            
            // Check if username already exists
            if (userDAO.usernameExists(user.getUsername())) {
                LOGGER.warning("Sign up failed - username already exists: " + user.getUsername());
                return new AuthResult(false, "Username already exists", null);
            }
            
            // Check if email already exists
            if (userDAO.emailExists(user.getEmail())) {
                LOGGER.warning("Sign up failed - email already exists: " + user.getEmail());
                return new AuthResult(false, "Email already exists", null);
            }
            
            // Hash the password before storing
            String hashedPassword = PasswordUtil.hashPassword(user.getPassword());
            user.setPassword(hashedPassword);
            
            // Create user in database
            boolean created = userDAO.createUser(user);
            if (created) {
                LOGGER.info("User created successfully: " + user.getUsername());
                // Return user data without password for security
                User safeUser = createSafeUser(user);
                return new AuthResult(true, "User created successfully", safeUser);
            } else {
                LOGGER.severe("Failed to create user in database: " + user.getUsername());
                return new AuthResult(false, "Failed to create user", null);
            }
            
        } catch (Exception e) {
            LOGGER.severe("Error during sign up for user: " + (user != null ? user.getUsername() : "null") + " - " + e.getMessage());
            return new AuthResult(false, "Internal server error", null);
        }
    }
    
    /**
     * Authenticate user login
     * @param username Username or email
     * @param password Plain text password
     * @return AuthResult with success status, message, and user data
     */
    public AuthResult signIn(String username, String password) {
        try {
            LOGGER.info("Starting sign in process for user: " + username);
            
            // Validate input
            if (username == null || username.trim().isEmpty()) {
                return new AuthResult(false, "Username is required", null);
            }
            
            if (password == null || password.trim().isEmpty()) {
                return new AuthResult(false, "Password is required", null);
            }
            
            // Get user from database
            User user = userDAO.getUserByUsername(username.trim());
            if (user == null) {
                LOGGER.warning("Sign in failed - user not found: " + username);
                return new AuthResult(false, "Invalid username or password", null);
            }
            
            // Check if user account is active
            if (!user.isActive()) {
                LOGGER.warning("Sign in failed - account deactivated: " + username);
                return new AuthResult(false, "Account is deactivated", null);
            }
            
            // Verify password
            if (!PasswordUtil.verifyPassword(password, user.getPassword())) {
                LOGGER.warning("Sign in failed - invalid password for user: " + username);
                return new AuthResult(false, "Invalid username or password", null);
            }
            
            // Update last login timestamp
            userDAO.updateLastLogin(user.getUsername());
            
            LOGGER.info("Sign in successful for user: " + username);
            
            // Return user data without password for security
            User safeUser = createSafeUser(user);
            return new AuthResult(true, "Login successful", safeUser);
            
        } catch (Exception e) {
            LOGGER.severe("Error during sign in for user: " + username + " - " + e.getMessage());
            return new AuthResult(false, "Internal server error", null);
        }
    }
    
    /**
     * Validate sign up data
     * @param user User object to validate
     * @return AuthResult with validation status and messages
     */
    private AuthResult validateSignUpData(User user) {
        if (user == null) {
            return new AuthResult(false, "User data is required", null);
        }
        
        // Validate username
        if (user.getUsername() == null || user.getUsername().trim().isEmpty()) {
            return new AuthResult(false, "Username is required", null);
        }
        
        String username = user.getUsername().trim();
        if (username.length() < 3) {
            return new AuthResult(false, "Username must be at least 3 characters long", null);
        }
        
        if (username.length() > 50) {
            return new AuthResult(false, "Username must be less than 50 characters", null);
        }
        
        // Validate email
        if (user.getEmail() == null || user.getEmail().trim().isEmpty()) {
            return new AuthResult(false, "Email is required", null);
        }
        
        if (!EMAIL_PATTERN.matcher(user.getEmail().trim()).matches()) {
            return new AuthResult(false, "Invalid email format", null);
        }
        
        // Validate password
        if (user.getPassword() == null || user.getPassword().trim().isEmpty()) {
            return new AuthResult(false, "Password is required", null);
        }
        
        if (!PasswordUtil.isValidPassword(user.getPassword())) {
            return new AuthResult(false, PasswordUtil.getPasswordRequirements(), null);
        }
        
        // Validate full name
        if (user.getFullName() == null || user.getFullName().trim().isEmpty()) {
            return new AuthResult(false, "Full name is required", null);
        }
        
        if (user.getFullName().trim().length() > 100) {
            return new AuthResult(false, "Full name must be less than 100 characters", null);
        }
        
        // Validate role if provided
        if (user.getRole() != null) {
            String role = user.getRole().toUpperCase();
            if (!role.equals("CUSTOMER") && !role.equals("ADMIN")) {
                return new AuthResult(false, "Invalid role. Must be CUSTOMER or ADMIN", null);
            }
            user.setRole(role);
        }
        
        return new AuthResult(true, "Validation successful", null);
    }
    
    /**
     * Create a safe user object without sensitive data
     * @param user Original user object
     * @return User object without password
     */
    private User createSafeUser(User user) {
        User safeUser = new User();
        safeUser.setUsername(user.getUsername());
        safeUser.setEmail(user.getEmail());
        safeUser.setFullName(user.getFullName());
        safeUser.setRole(user.getRole());
        safeUser.setCreatedAt(user.getCreatedAt());
        safeUser.setLastLogin(user.getLastLogin());
        safeUser.setActive(user.isActive());
        // Note: Password is intentionally NOT included for security
        return safeUser;
    }
    
    /**
     * Inner class for authentication results
     */
    public static class AuthResult {
        private boolean success;
        private String message;
        private User user;
        
        public AuthResult(boolean success, String message, User user) {
            this.success = success;
            this.message = message;
            this.user = user;
        }
        
        public boolean isSuccess() { 
            return success; 
        }
        
        public String getMessage() { 
            return message; 
        }
        
        public User getUser() { 
            return user; 
        }
        
        @Override
        public String toString() {
            return "AuthResult{" +
                    "success=" + success +
                    ", message='" + message + '\'' +
                    ", user=" + (user != null ? user.getUsername() : "null") +
                    '}';
        }
    }
}