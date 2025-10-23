package DAO;

import MODELS.User;
import UTILS.DatabaseConnection;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

public class UserDAO {
    private static final Logger LOGGER = Logger.getLogger(UserDAO.class.getName());
    
    // SQL Queries
    private static final String INSERT_USER = 
        "INSERT INTO users (username, password, email, full_name, role, created_at, is_active) VALUES (?, ?, ?, ?, ?, NOW(), ?)";
    
    private static final String SELECT_USER_BY_USERNAME = 
        "SELECT * FROM users WHERE username = ?";
    
    private static final String SELECT_USER_BY_EMAIL = 
        "SELECT * FROM users WHERE email = ?";
    
    private static final String UPDATE_LAST_LOGIN = 
        "UPDATE users SET last_login = NOW() WHERE username = ?";
    
    private static final String CHECK_USERNAME_EXISTS = 
        "SELECT COUNT(*) FROM users WHERE username = ?";
    
    private static final String CHECK_EMAIL_EXISTS = 
        "SELECT COUNT(*) FROM users WHERE email = ?";

    /**
     * Create a new user in the database
     * @param user User object to create
     * @return true if user created successfully, false otherwise
     */
    public boolean createUser(User user) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(INSERT_USER)) {
            
            stmt.setString(1, user.getUsername());
            stmt.setString(2, user.getPassword());
            stmt.setString(3, user.getEmail());
            stmt.setString(4, user.getFullName());
            stmt.setString(5, user.getRole());
            stmt.setBoolean(6, user.isActive());
            
            int rowsAffected = stmt.executeUpdate();
            boolean success = rowsAffected > 0;
            
            if (success) {
                LOGGER.info("User created successfully: " + user.getUsername());
            } else {
                LOGGER.warning("Failed to create user: " + user.getUsername());
            }
            
            return success;
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error creating user: " + user.getUsername(), e);
            return false;
        }
    }
    
    /**
     * Retrieve user by username
     * @param username Username to search for
     * @return User object if found, null otherwise
     */
    public User getUserByUsername(String username) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_USER_BY_USERNAME)) {
            
            stmt.setString(1, username);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs);
                }
            }
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving user by username: " + username, e);
        }
        return null;
    }
    
    /**
     * Retrieve user by email
     * @param email Email to search for
     * @return User object if found, null otherwise
     */
    public User getUserByEmail(String email) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_USER_BY_EMAIL)) {
            
            stmt.setString(1, email);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs);
                }
            }
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving user by email: " + email, e);
        }
        return null;
    }
    
    /**
     * Update user's last login timestamp
     * @param username Username of user to update
     * @return true if updated successfully, false otherwise
     */
    public boolean updateLastLogin(String username) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(UPDATE_LAST_LOGIN)) {
            
            stmt.setString(1, username);
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating last login for user: " + username, e);
            return false;
        }
    }
    
    /**
     * Check if username already exists
     * @param username Username to check
     * @return true if username exists, false otherwise
     */
    public boolean usernameExists(String username) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(CHECK_USERNAME_EXISTS)) {
            
            stmt.setString(1, username);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error checking username existence: " + username, e);
        }
        return false;
    }
    
    /**
     * Check if email already exists
     * @param email Email to check
     * @return true if email exists, false otherwise
     */
    public boolean emailExists(String email) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(CHECK_EMAIL_EXISTS)) {
            
            stmt.setString(1, email);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error checking email existence: " + email, e);
        }
        return false;
    }
    
    /**
     * Map database ResultSet to User object
     * @param rs ResultSet from database query
     * @return User object
     * @throws SQLException if database error occurs
     */
    private User mapResultSetToUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUsername(rs.getString("username"));
        user.setPassword(rs.getString("password"));
        user.setEmail(rs.getString("email"));
        user.setFullName(rs.getString("full_name"));
        user.setRole(rs.getString("role"));
        user.setActive(rs.getBoolean("is_active"));
        
        // Handle timestamps - they might be null
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            user.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        Timestamp lastLogin = rs.getTimestamp("last_login");
        if (lastLogin != null) {
            user.setLastLogin(lastLogin.toLocalDateTime());
        }
        
        return user;
    }
}