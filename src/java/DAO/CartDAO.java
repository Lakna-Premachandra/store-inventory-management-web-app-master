package DAO;

import MODELS.Cart;
import UTILS.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CartDAO {
    private static final Logger LOGGER = Logger.getLogger(CartDAO.class.getName());

    private static final String INSERT_CART_ITEM = 
        "INSERT INTO online_cart (username, product_code, quantity) VALUES (?, ?, ?) " +
        "ON DUPLICATE KEY UPDATE quantity = quantity + ?";
    
    private static final String UPDATE_CART_ITEM = 
        "UPDATE online_cart SET quantity = ? WHERE username = ? AND product_code = ?";
    
    private static final String DELETE_CART_ITEM = 
        "DELETE FROM online_cart WHERE username = ? AND product_code = ?";
    
    private static final String DELETE_CART_ALL = 
        "DELETE FROM online_cart WHERE username = ?";
    
    private static final String SELECT_CART_ITEMS = 
        "SELECT c.username, c.product_code, c.quantity, p.name as product_name, " +
        "p.unit_price, p.discount " +
        "FROM online_cart c " +
        "JOIN products p ON c.product_code = p.product_code " +
        "WHERE c.username = ?";
    
    private static final String SELECT_CART_ITEM = 
        "SELECT c.username, c.product_code, c.quantity, p.name as product_name, " +
        "p.unit_price, p.discount " +
        "FROM online_cart c " +
        "JOIN products p ON c.product_code = p.product_code " +
        "WHERE c.username = ? AND c.product_code = ?";

    public boolean addToCart(String username, String productCode, int quantity) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(INSERT_CART_ITEM)) {
            
            stmt.setString(1, username);
            stmt.setString(2, productCode);
            stmt.setInt(3, quantity);
            stmt.setInt(4, quantity); // for ON DUPLICATE KEY UPDATE
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error adding item to cart", e);
            return false;
        }
    }

    public boolean updateCartItem(String username, String productCode, int quantity) {
        if (quantity <= 0) {
            return removeFromCart(username, productCode);
        }
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(UPDATE_CART_ITEM)) {
            
            stmt.setInt(1, quantity);
            stmt.setString(2, username);
            stmt.setString(3, productCode);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating cart item", e);
            return false;
        }
    }

    public boolean removeFromCart(String username, String productCode) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(DELETE_CART_ITEM)) {
            
            stmt.setString(1, username);
            stmt.setString(2, productCode);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error removing item from cart", e);
            return false;
        }
    }

    public boolean clearCart(String username) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(DELETE_CART_ALL)) {
            
            stmt.setString(1, username);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error clearing cart", e);
            return false;
        }
    }

    public List<Cart> getCartItems(String username) {
        List<Cart> cartItems = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_CART_ITEMS)) {
            
            stmt.setString(1, username);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    cartItems.add(mapResultSetToCart(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving cart items", e);
        }
        return cartItems;
    }

    public Cart getCartItem(String username, String productCode) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_CART_ITEM)) {
            
            stmt.setString(1, username);
            stmt.setString(2, productCode);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToCart(rs);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving cart item", e);
        }
        return null;
    }
    
    public boolean deleteByProductCode(String productCode) {
    String sql = "DELETE FROM online_cart WHERE product_code = ?";
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement stmt = conn.prepareStatement(sql)) {
        
        stmt.setString(1, productCode);
        return stmt.executeUpdate() > 0;
    } catch (SQLException e) {
        LOGGER.log(Level.SEVERE, "Error deleting cart items for product: " + productCode, e);
        return false;
    }
}

    private Cart mapResultSetToCart(ResultSet rs) throws SQLException {
        Cart cart = new Cart();
        cart.setUsername(rs.getString("username"));
        cart.setProductCode(rs.getString("product_code"));
        cart.setProductName(rs.getString("product_name"));
        cart.setQuantity(rs.getInt("quantity"));
        cart.setUnitPrice(rs.getBigDecimal("unit_price"));
        cart.setDiscount(rs.getBigDecimal("discount"));
        
        // Calculate discounted price and total amount
        BigDecimal unitPrice = cart.getUnitPrice();
        BigDecimal discount = cart.getDiscount() != null ? cart.getDiscount() : BigDecimal.ZERO;
        BigDecimal discountAmount = unitPrice.multiply(discount).divide(new BigDecimal("100"));
        BigDecimal discountedPrice = unitPrice.subtract(discountAmount);
        BigDecimal totalAmount = discountedPrice.multiply(new BigDecimal(cart.getQuantity()));
        
        cart.setDiscountedPrice(discountedPrice);
        cart.setTotalAmount(totalAmount);
        
        return cart;
    }
}