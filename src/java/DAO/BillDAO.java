package DAO;

import MODELS.Bill;
import UTILS.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class BillDAO {
    private static final Logger LOGGER = Logger.getLogger(BillDAO.class.getName());

    private static final String INSERT_BILL = 
        "INSERT INTO bill (amount, username, bill_type, cash_tendered, change_amount) VALUES (?, ?, ?, ?, ?)";
    
    private static final String SELECT_BILL_BY_ID = 
        "SELECT b.bill_id, b.bill_date, b.amount, b.username, u.full_name, b.bill_type, " +
        "b.cash_tendered, b.change_amount " +
        "FROM bill b " +
        "JOIN users u ON b.username = u.username " +
        "WHERE b.bill_id = ?";
    
    private static final String SELECT_ALL_BILLS = 
        "SELECT b.bill_id, b.bill_date, b.amount, b.username, u.full_name, b.bill_type, " +
        "b.cash_tendered, b.change_amount " +
        "FROM bill b " +
        "JOIN users u ON b.username = u.username " +
        "ORDER BY b.bill_date DESC";
    
    private static final String SELECT_BILLS_BY_USERNAME = 
        "SELECT b.bill_id, b.bill_date, b.amount, b.username, u.full_name, b.bill_type, " +
        "b.cash_tendered, b.change_amount " +
        "FROM bill b " +
        "JOIN users u ON b.username = u.username " +
        "WHERE b.username = ? " +
        "ORDER BY b.bill_date DESC";
    
    private static final String SELECT_BILLS_BY_TYPE = 
        "SELECT b.bill_id, b.bill_date, b.amount, b.username, u.full_name, b.bill_type, " +
        "b.cash_tendered, b.change_amount " +
        "FROM bill b " +
        "JOIN users u ON b.username = u.username " +
        "WHERE b.bill_type = ? " +
        "ORDER BY b.bill_date DESC";
    
    private static final String SELECT_BILLS_BY_DATE_RANGE = 
        "SELECT b.bill_id, b.bill_date, b.amount, b.username, u.full_name, b.bill_type, " +
        "b.cash_tendered, b.change_amount " +
        "FROM bill b " +
        "JOIN users u ON b.username = u.username " +
        "WHERE b.bill_date BETWEEN ? AND ? " +
        "ORDER BY b.bill_date DESC";

    /**
     * Save a new bill to database
     */
    public boolean saveBill(Bill bill) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(INSERT_BILL, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setBigDecimal(1, bill.getAmount());
            stmt.setString(2, bill.getUsername());
            stmt.setString(3, bill.getBillType());
            
            // Set cash_tendered and change_amount (can be null for ONLINE bills)
            if (bill.getCashTendered() != null) {
                stmt.setBigDecimal(4, bill.getCashTendered());
            } else {
                stmt.setNull(4, Types.DECIMAL);
            }
            
            if (bill.getChangeAmount() != null) {
                stmt.setBigDecimal(5, bill.getChangeAmount());
            } else {
                stmt.setNull(5, Types.DECIMAL);
            }
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows > 0) {
                try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        bill.setBillId(generatedKeys.getInt(1));
                    }
                }
                return true;
            }
            return false;
            
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error saving bill", e);
            return false;
        }
    }

    /**
     * Get bill by ID
     */
    public Bill getBillById(int billId) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_BILL_BY_ID)) {
            
            stmt.setInt(1, billId);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToBill(rs);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving bill by ID", e);
        }
        return null;
    }

    /**
     * Get all bills
     */
    public List<Bill> getAllBills() {
        List<Bill> bills = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_ALL_BILLS);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                bills.add(mapResultSetToBill(rs));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving all bills", e);
        }
        return bills;
    }

    /**
     * Get bills by username
     */
    public List<Bill> getBillsByUsername(String username) {
        List<Bill> bills = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_BILLS_BY_USERNAME)) {
            
            stmt.setString(1, username);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    bills.add(mapResultSetToBill(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving bills by username", e);
        }
        return bills;
    }

    /**
     * Get bills by bill type
     */
    public List<Bill> getBillsByType(String billType) {
        List<Bill> bills = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_BILLS_BY_TYPE)) {
            
            stmt.setString(1, billType);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    bills.add(mapResultSetToBill(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving bills by type", e);
        }
        return bills;
    }

    /**
     * Get bills within date range
     */
    public List<Bill> getBillsByDateRange(Timestamp startDate, Timestamp endDate) {
        List<Bill> bills = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_BILLS_BY_DATE_RANGE)) {
            
            stmt.setTimestamp(1, startDate);
            stmt.setTimestamp(2, endDate);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    bills.add(mapResultSetToBill(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving bills by date range", e);
        }
        return bills;
    }

    /**
     * Get total amount for a user
     */
    public BigDecimal getTotalAmountByUsername(String username) {
        String query = "SELECT SUM(amount) as total FROM bill WHERE username = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(query)) {
            
            stmt.setString(1, username);
            
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    BigDecimal total = rs.getBigDecimal("total");
                    return total != null ? total : BigDecimal.ZERO;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error calculating total amount", e);
        }
        return BigDecimal.ZERO;
    }

    /**
     * Map ResultSet to Bill object
     */
    private Bill mapResultSetToBill(ResultSet rs) throws SQLException {
        Bill bill = new Bill();
        bill.setBillId(rs.getInt("bill_id"));
        bill.setBillDate(rs.getTimestamp("bill_date"));
        bill.setAmount(rs.getBigDecimal("amount"));
        bill.setUsername(rs.getString("username"));
        bill.setFullName(rs.getString("full_name"));
        bill.setBillType(rs.getString("bill_type"));
        
        // Handle nullable cash_tendered and change_amount
        BigDecimal cashTendered = rs.getBigDecimal("cash_tendered");
        if (!rs.wasNull()) {
            bill.setCashTendered(cashTendered);
        }
        
        BigDecimal changeAmount = rs.getBigDecimal("change_amount");
        if (!rs.wasNull()) {
            bill.setChangeAmount(changeAmount);
        }
        
        return bill;
    }
}