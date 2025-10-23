package DAO;

import MODELS.StoreInventory;
import UTILS.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class StoreInventoryDAO {
    private static final Logger LOGGER = Logger.getLogger(StoreInventoryDAO.class.getName());

    private static final String INSERT_INVENTORY =
        "INSERT INTO store_inventory (product_code, product_name, quantity) VALUES (?, ?, ?)";
    private static final String UPDATE_INVENTORY =
        "UPDATE store_inventory SET product_name = ?, quantity = ? WHERE product_code = ?";
    private static final String GET_ALL =
        "SELECT * FROM store_inventory";
    private static final String GET_BY_CODE =
        "SELECT * FROM store_inventory WHERE product_code = ?";
    private static final String DELETE_INVENTORY =
        "DELETE FROM store_inventory WHERE product_code = ?";

    public boolean insert(StoreInventory inv) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(INSERT_INVENTORY)) {

            stmt.setString(1, inv.getProductCode());
            stmt.setString(2, inv.getProductName());
            stmt.setInt(3, inv.getQuantity());

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error inserting store inventory", e);
            return false;
        }
    }

    public boolean update(StoreInventory inv) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(UPDATE_INVENTORY)) {

            stmt.setString(1, inv.getProductName());
            stmt.setInt(2, inv.getQuantity());
            stmt.setString(3, inv.getProductCode());

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating store inventory", e);
            return false;
        }
    }

    public List<StoreInventory> getAll() {
        List<StoreInventory> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(GET_ALL);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                list.add(mapResultSetToInventory(rs));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving store inventory", e);
        }
        return list;
    }

    public StoreInventory getByCode(String code) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(GET_BY_CODE)) {

            stmt.setString(1, code);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToInventory(rs);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving store inventory", e);
        }
        return null;
    }

    public boolean delete(String code) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(DELETE_INVENTORY)) {

            stmt.setString(1, code);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error deleting store inventory", e);
            return false;
        }
    }

    private StoreInventory mapResultSetToInventory(ResultSet rs) throws SQLException {
        StoreInventory inv = new StoreInventory();
        inv.setProductCode(rs.getString("product_code"));
        inv.setProductName(rs.getString("product_name"));
        inv.setQuantity(rs.getInt("quantity"));
        return inv;
    }
}
