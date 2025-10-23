package SERVICES;

import DAO.CartDAO;
import DAO.ProductDAO;
import MODELS.Cart;
import MODELS.Product;

import java.math.BigDecimal;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CartService {
    private static final Logger LOGGER = Logger.getLogger(CartService.class.getName());
    private final CartDAO cartDAO;
    private final ProductDAO productDAO;

    public CartService() {
        this.cartDAO = new CartDAO();
        this.productDAO = new ProductDAO();
    }

    /**
     * Add item to cart with validation
     */
    public boolean addToCart(String username, String productCode, int quantity) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return false;
        }
        if (productCode == null || productCode.trim().isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }
        if (quantity <= 0) {
            LOGGER.warning("Quantity must be greater than 0");
            return false;
        }

        // Verify product exists
        Product product = productDAO.getProductByCode(productCode);
        if (product == null) {
            LOGGER.warning("Product not found: " + productCode);
            return false;
        }

        boolean success = cartDAO.addToCart(username, productCode, quantity);
        if (success) {
            LOGGER.info("Item added to cart: " + username + " - " + productCode + " - " + quantity);
        } else {
            LOGGER.warning("Failed to add item to cart");
        }
        return success;
    }

    /**
     * Update cart item quantity
     */
    public boolean updateCartItem(String username, String productCode, int quantity) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return false;
        }
        if (productCode == null || productCode.trim().isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }
        if (quantity < 0) {
            LOGGER.warning("Quantity cannot be negative");
            return false;
        }

        boolean success = cartDAO.updateCartItem(username, productCode, quantity);
        if (success) {
            if (quantity == 0) {
                LOGGER.info("Item removed from cart: " + username + " - " + productCode);
            } else {
                LOGGER.info("Cart item updated: " + username + " - " + productCode + " - " + quantity);
            }
        } else {
            LOGGER.warning("Failed to update cart item");
        }
        return success;
    }

    /**
     * Remove item from cart
     */
    public boolean removeFromCart(String username, String productCode) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return false;
        }
        if (productCode == null || productCode.trim().isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }

        boolean success = cartDAO.removeFromCart(username, productCode);
        if (success) {
            LOGGER.info("Item removed from cart: " + username + " - " + productCode);
        } else {
            LOGGER.warning("Failed to remove item from cart");
        }
        return success;
    }

    /**
     * Clear all items from user's cart
     */
    public boolean clearCart(String username) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return false;
        }

        boolean success = cartDAO.clearCart(username);
        if (success) {
            LOGGER.info("Cart cleared for user: " + username);
        } else {
            LOGGER.warning("Failed to clear cart");
        }
        return success;
    }

    /**
     * Get all items in user's cart with calculated totals
     */
    public List<Cart> getCartItems(String username) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return null;
        }

        List<Cart> cartItems = cartDAO.getCartItems(username);
        if (cartItems.isEmpty()) {
            LOGGER.info("No items found in cart for user: " + username);
        } else {
            LOGGER.info("Retrieved " + cartItems.size() + " items from cart for user: " + username);
        }
        return cartItems;
    }

    /**
     * Get specific item from user's cart
     */
    public Cart getCartItem(String username, String productCode) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return null;
        }
        if (productCode == null || productCode.trim().isEmpty()) {
            LOGGER.warning("Product code is required");
            return null;
        }

        Cart cartItem = cartDAO.getCartItem(username, productCode);
        if (cartItem == null) {
            LOGGER.info("Item not found in cart: " + username + " - " + productCode);
        } else {
            LOGGER.info("Cart item retrieved: " + username + " - " + productCode);
        }
        return cartItem;
    }

    /**
     * Get cart summary with total calculations
     */
    public CartSummary getCartSummary(String username) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return null;
        }

        List<Cart> cartItems = cartDAO.getCartItems(username);
        
        CartSummary summary = new CartSummary();
        summary.setUsername(username);
        summary.setItems(cartItems);
        summary.setItemCount(cartItems.size());
        
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal totalDiscount = BigDecimal.ZERO;
        int totalQuantity = 0;
        
        for (Cart item : cartItems) {
            BigDecimal itemOriginalTotal = item.getUnitPrice().multiply(new BigDecimal(item.getQuantity()));
            BigDecimal itemDiscountAmount = itemOriginalTotal.subtract(item.getTotalAmount());
            
            subtotal = subtotal.add(itemOriginalTotal);
            totalDiscount = totalDiscount.add(itemDiscountAmount);
            totalQuantity += item.getQuantity();
        }
        
        summary.setSubtotal(subtotal);
        summary.setTotalDiscount(totalDiscount);
        summary.setTotalAmount(subtotal.subtract(totalDiscount));
        summary.setTotalQuantity(totalQuantity);
        
        LOGGER.info("Cart summary calculated for user: " + username + 
                   " - Items: " + summary.getItemCount() + 
                   " - Total: " + summary.getTotalAmount());
        
        return summary;
    }

    /**
     * Inner class for cart summary
     */
    public static class CartSummary {
        private String username;
        private List<Cart> items;
        private int itemCount;
        private int totalQuantity;
        private BigDecimal subtotal;
        private BigDecimal totalDiscount;
        private BigDecimal totalAmount;

        // Getters and Setters
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        
        public List<Cart> getItems() { return items; }
        public void setItems(List<Cart> items) { this.items = items; }
        
        public int getItemCount() { return itemCount; }
        public void setItemCount(int itemCount) { this.itemCount = itemCount; }
        
        public int getTotalQuantity() { return totalQuantity; }
        public void setTotalQuantity(int totalQuantity) { this.totalQuantity = totalQuantity; }
        
        public BigDecimal getSubtotal() { return subtotal; }
        public void setSubtotal(BigDecimal subtotal) { this.subtotal = subtotal; }
        
        public BigDecimal getTotalDiscount() { return totalDiscount; }
        public void setTotalDiscount(BigDecimal totalDiscount) { this.totalDiscount = totalDiscount; }
        
        public BigDecimal getTotalAmount() { return totalAmount; }
        public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    }
}