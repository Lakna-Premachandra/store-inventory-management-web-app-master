package DAO;

import MODELS.OnlineInventory;
import UTILS.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class OnlineInventoryDAO {
    private static final Logger LOGGER = Logger.getLogger(OnlineInventoryDAO.class.getName());

    private static final String INSERT_ONLINE_INVENTORY =
        "INSERT INTO online_inventory (product_code, quantity) VALUES (?, ?)";
    private static final String SELECT_ALL_ONLINE_INVENTORY =
        "SELECT * FROM online_inventory";
    private static final String SELECT_BY_CODE =
        "SELECT * FROM online_inventory WHERE product_code = ?";
    private static final String UPDATE_ONLINE_INVENTORY =
        "UPDATE online_inventory SET quantity = ? WHERE product_code = ?";
    private static final String DELETE_ONLINE_INVENTORY =
        "DELETE FROM online_inventory WHERE product_code = ?";

    public boolean insert(OnlineInventory inventory) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(INSERT_ONLINE_INVENTORY)) {

            stmt.setString(1, inventory.getProductCode());
            stmt.setInt(2, inventory.getQuantity());

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error inserting online inventory", e);
            return false;
        }
    }

    public List<OnlineInventory> getAll() {
        List<OnlineInventory> inventoryList = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_ALL_ONLINE_INVENTORY);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                inventoryList.add(mapResultSetToInventory(rs));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving online inventory", e);
        }
        return inventoryList;
    }

    public OnlineInventory getByCode(String productCode) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_BY_CODE)) {

            stmt.setString(1, productCode);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToInventory(rs);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving online inventory by code", e);
        }
        return null;
    }

    public boolean update(OnlineInventory inventory) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(UPDATE_ONLINE_INVENTORY)) {

            stmt.setInt(1, inventory.getQuantity());
            stmt.setString(2, inventory.getProductCode());

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating online inventory", e);
            return false;
        }
    }

    public boolean delete(String productCode) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(DELETE_ONLINE_INVENTORY)) {

            stmt.setString(1, productCode);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error deleting online inventory", e);
            return false;
        }
    }

    private OnlineInventory mapResultSetToInventory(ResultSet rs) throws SQLException {
        OnlineInventory inventory = new OnlineInventory();
        inventory.setProductCode(rs.getString("product_code"));
        inventory.setQuantity(rs.getInt("quantity"));
        return inventory;
    }
}