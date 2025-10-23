package SERVICES;

import DAO.BillDAO;
import DAO.CartDAO;
import DAO.OrderItemDAO;
import DAO.UserDAO;
import MODELS.Bill;
import MODELS.Cart;
import MODELS.OrderItem;
import MODELS.User;
import UTILS.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class CheckoutService {
    private static final Logger LOGGER = Logger.getLogger(CheckoutService.class.getName());
    private final BillDAO billDAO;
    private final CartDAO cartDAO;
    private final OrderItemDAO orderItemDAO;
    private final UserDAO userDAO;

    public CheckoutService() {
        this.billDAO = new BillDAO();
        this.cartDAO = new CartDAO();
        this.orderItemDAO = new OrderItemDAO();
        this.userDAO = new UserDAO();
    }

    public CheckoutResult processCheckout(String username) {
        return processCheckout(username, null);
    }

    public CheckoutResult processCheckout(String username, BigDecimal cashTendered) {
        CheckoutResult result = new CheckoutResult();
        
        if (username == null || username.trim().isEmpty()) {
            result.setSuccess(false);
            result.setMessage("Username is required");
            return result;
        }

        User user = userDAO.getUserByUsername(username.trim());
        if (user == null) {
            result.setSuccess(false);
            result.setMessage("User not found");
            return result;
        }

        List<Cart> cartItems = cartDAO.getCartItems(username.trim());
        if (cartItems == null || cartItems.isEmpty()) {
            result.setSuccess(false);
            result.setMessage("Cart is empty");
            return result;
        }

        BigDecimal totalAmount = BigDecimal.ZERO;
        for (Cart item : cartItems) {
            totalAmount = totalAmount.add(item.getTotalAmount());
        }

        String billType = "CUSTOMER".equals(user.getRole().toUpperCase()) ? "ONLINE" : "INSTORE";

        if ("INSTORE".equals(billType) && cashTendered != null) {
            if (cashTendered.compareTo(totalAmount) < 0) {
                result.setSuccess(false);
                result.setMessage("Cash tendered is less than the total amount");
                return result;
            }
        }

        List<OrderItem> orderItems = new ArrayList<>();
        for (Cart cartItem : cartItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.setProductCode(cartItem.getProductCode());
            orderItem.setProductName(cartItem.getProductName());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setUnitPrice(cartItem.getUnitPrice());
            orderItem.setDiscount(cartItem.getDiscount());
            orderItem.setTotalAmount(cartItem.getTotalAmount());
            orderItems.add(orderItem);
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            Bill bill = new Bill(totalAmount, username.trim(), user.getFullName(), billType);
            
            if ("INSTORE".equals(billType) && cashTendered != null) {
                bill.setCashTendered(cashTendered);
            }
            
            boolean billCreated = billDAO.saveBill(bill);
            
            if (!billCreated) {
                conn.rollback();
                result.setSuccess(false);
                result.setMessage("Failed to create bill");
                return result;
            }

            boolean itemsProcessed = orderItemDAO.processOrderItems(orderItems, conn);
            
            if (!itemsProcessed) {
                conn.rollback();
                result.setSuccess(false);
                result.setMessage("Failed to process order items - Insufficient stock");
                return result;
            }

            boolean cartCleared = cartDAO.clearCart(username.trim());
            
            if (!cartCleared) {
                conn.rollback();
                result.setSuccess(false);
                result.setMessage("Failed to clear cart");
                return result;
            }

            conn.commit();
            
            result.setSuccess(true);
            result.setMessage("Order placed successfully");
            result.setBillId(bill.getBillId());
            result.setTotalAmount(totalAmount);
            result.setBillType(billType);
            result.setOrderItems(orderItems);
            result.setCashTendered(bill.getCashTendered());
            result.setChangeAmount(bill.getChangeAmount());
            
            LOGGER.info("Checkout completed - Bill ID: " + bill.getBillId() + 
                       ", User: " + username + ", Amount: " + totalAmount +
                       (bill.getCashTendered() != null ? ", Cash: " + bill.getCashTendered() : "") +
                       (bill.getChangeAmount() != null ? ", Change: " + bill.getChangeAmount() : ""));
            
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            LOGGER.log(Level.SEVERE, "Checkout failed", e);
            result.setSuccess(false);
            result.setMessage("Checkout failed: " + e.getMessage());
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) { }
            }
        }
        
        return result;
    }

    public static class CheckoutResult {
        private boolean success;
        private String message;
        private int billId;
        private BigDecimal totalAmount;
        private String billType;
        private List<OrderItem> orderItems;
        private BigDecimal cashTendered;
        private BigDecimal changeAmount;

        public boolean isSuccess() { return success; }
        public void setSuccess(boolean success) { this.success = success; }
        
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        
        public int getBillId() { return billId; }
        public void setBillId(int billId) { this.billId = billId; }
        
        public BigDecimal getTotalAmount() { return totalAmount; }
        public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
        
        public String getBillType() { return billType; }
        public void setBillType(String billType) { this.billType = billType; }
        
        public List<OrderItem> getOrderItems() { return orderItems; }
        public void setOrderItems(List<OrderItem> orderItems) { this.orderItems = orderItems; }
        
        public BigDecimal getCashTendered() { return cashTendered; }
        public void setCashTendered(BigDecimal cashTendered) { this.cashTendered = cashTendered; }
        
        public BigDecimal getChangeAmount() { return changeAmount; }
        public void setChangeAmount(BigDecimal changeAmount) { this.changeAmount = changeAmount; }
    }
}