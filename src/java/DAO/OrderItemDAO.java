package DAO;

import MODELS.OrderItem;
import UTILS.DatabaseConnection;

import java.sql.*;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class OrderItemDAO {
    private static final Logger LOGGER = Logger.getLogger(OrderItemDAO.class.getName());

    private static final String INSERT_ORDER_ITEM = 
        "INSERT INTO online_inventory (product_code, quantity) VALUES (?, ?) " +
        "ON DUPLICATE KEY UPDATE quantity = quantity + ?";
    
    private static final String UPDATE_STORE_INVENTORY = 
        "UPDATE store_inventory SET quantity = quantity - ? WHERE product_code = ?";
    
    private static final String CHECK_STORE_INVENTORY = 
        "SELECT quantity FROM store_inventory WHERE product_code = ?";

    public boolean processOrderItems(List<OrderItem> items, Connection conn) throws SQLException {
        try (PreparedStatement checkStmt = conn.prepareStatement(CHECK_STORE_INVENTORY);
             PreparedStatement insertStmt = conn.prepareStatement(INSERT_ORDER_ITEM);
             PreparedStatement updateStmt = conn.prepareStatement(UPDATE_STORE_INVENTORY)) {
            
            // Check if all items have sufficient quantity in store
            for (OrderItem item : items) {
                checkStmt.setString(1, item.getProductCode());
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next()) {
                        int availableQty = rs.getInt("quantity");
                        if (availableQty < item.getQuantity()) {
                            LOGGER.warning("Insufficient stock for " + item.getProductCode());
                            return false;
                        }
                    } else {
                        LOGGER.warning("Product not found: " + item.getProductCode());
                        return false;
                    }
                }
            }
            
            // Add to online inventory and reduce from store inventory
            for (OrderItem item : items) {
                insertStmt.setString(1, item.getProductCode());
                insertStmt.setInt(2, item.getQuantity());
                insertStmt.setInt(3, item.getQuantity());
                insertStmt.addBatch();
                
                updateStmt.setInt(1, item.getQuantity());
                updateStmt.setString(2, item.getProductCode());
                updateStmt.addBatch();
            }
            
            insertStmt.executeBatch();
            updateStmt.executeBatch();
            
            LOGGER.info("Processed " + items.size() + " order items");
            return true;
        }
    }
}