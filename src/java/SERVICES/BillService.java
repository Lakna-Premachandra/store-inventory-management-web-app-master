package SERVICES;

import DAO.BillDAO;
import DAO.UserDAO;
import MODELS.Bill;
import MODELS.User;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;
import java.util.logging.Logger;

public class BillService {
    private static final Logger LOGGER = Logger.getLogger(BillService.class.getName());
    private final BillDAO billDAO;
    private final UserDAO userDAO;

    public BillService() {
        this.billDAO = new BillDAO();
        this.userDAO = new UserDAO();
    }

    /**
     * Create and save a new bill (overloaded for backward compatibility)
     */
    public boolean createBill(BigDecimal amount, String username, String billType) {
        return createBill(amount, username, billType, null);
    }

    /**
     * Create and save a new bill with cash tendered
     */
    public boolean createBill(BigDecimal amount, String username, String billType, BigDecimal cashTendered) {
        // Validation
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            LOGGER.warning("Amount must be greater than 0");
            return false;
        }
        
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return false;
        }
        
        if (billType == null || billType.trim().isEmpty()) {
            LOGGER.warning("Bill type is required");
            return false;
        }

        // Validate bill type
        String normalizedBillType = billType.toUpperCase().trim();
        if (!isValidBillType(normalizedBillType)) {
            LOGGER.warning("Invalid bill type: " + billType + ". Must be ONLINE or INSTORE");
            return false;
        }

        // Get user and validate role against bill type
        User user = userDAO.getUserByUsername(username.trim());
        if (user == null) {
            LOGGER.warning("User not found: " + username);
            return false;
        }

        // Validate bill type based on user role
        String userRole = user.getRole().toUpperCase();
        if ("CUSTOMER".equals(userRole) && !"ONLINE".equals(normalizedBillType)) {
            LOGGER.warning("Customer can only create ONLINE bills");
            return false;
        }
        
        if ("ADMIN".equals(userRole) && !"INSTORE".equals(normalizedBillType)) {
            LOGGER.warning("Admin can only create INSTORE bills");
            return false;
        }

        // Validate cash tendered for INSTORE bills
        if ("INSTORE".equals(normalizedBillType) && cashTendered != null) {
            if (cashTendered.compareTo(amount) < 0) {
                LOGGER.warning("Cash tendered is less than the bill amount");
                return false;
            }
        }

        // Create bill object
        Bill bill = new Bill(amount, username.trim(), user.getFullName(), normalizedBillType);
        
        // Set cash tendered and calculate change for INSTORE bills
        if ("INSTORE".equals(normalizedBillType) && cashTendered != null) {
            bill.setCashTendered(cashTendered);
            // Change is automatically calculated in the Bill model setCashTendered method
        }
        
        boolean success = billDAO.saveBill(bill);
        
        if (success) {
            LOGGER.info("Bill created successfully - ID: " + bill.getBillId() + 
                       ", Username: " + username + 
                       ", Amount: " + amount + 
                       ", Type: " + normalizedBillType +
                       ", Role: " + userRole +
                       (bill.getCashTendered() != null ? ", Cash Tendered: " + bill.getCashTendered() : "") +
                       (bill.getChangeAmount() != null ? ", Change: " + bill.getChangeAmount() : ""));
        } else {
            LOGGER.warning("Failed to create bill");
        }
        
        return success;
    }

    /**
     * Get bill by ID
     */
    public Bill getBillById(int billId) {
        if (billId <= 0) {
            LOGGER.warning("Invalid bill ID: " + billId);
            return null;
        }

        Bill bill = billDAO.getBillById(billId);
        
        if (bill == null) {
            LOGGER.info("Bill not found with ID: " + billId);
        } else {
            LOGGER.info("Bill retrieved: " + billId);
        }
        
        return bill;
    }

    /**
     * Get all bills
     */
    public List<Bill> getAllBills() {
        List<Bill> bills = billDAO.getAllBills();
        LOGGER.info("Retrieved " + bills.size() + " bills");
        return bills;
    }

    /**
     * Get bills by username
     */
    public List<Bill> getBillsByUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return null;
        }

        List<Bill> bills = billDAO.getBillsByUsername(username.trim());
        LOGGER.info("Retrieved " + bills.size() + " bills for user: " + username);
        return bills;
    }

    /**
     * Get bills by bill type
     */
    public List<Bill> getBillsByType(String billType) {
        if (billType == null || billType.trim().isEmpty()) {
            LOGGER.warning("Bill type is required");
            return null;
        }

        String normalizedType = billType.toUpperCase().trim();
        if (!isValidBillType(normalizedType)) {
            LOGGER.warning("Invalid bill type: " + billType);
            return null;
        }

        List<Bill> bills = billDAO.getBillsByType(normalizedType);
        LOGGER.info("Retrieved " + bills.size() + " bills for type: " + normalizedType);
        return bills;
    }

    /**
     * Get bills within date range
     */
    public List<Bill> getBillsByDateRange(Timestamp startDate, Timestamp endDate) {
        if (startDate == null || endDate == null) {
            LOGGER.warning("Start date and end date are required");
            return null;
        }
        
        if (startDate.after(endDate)) {
            LOGGER.warning("Start date cannot be after end date");
            return null;
        }

        List<Bill> bills = billDAO.getBillsByDateRange(startDate, endDate);
        LOGGER.info("Retrieved " + bills.size() + " bills between " + startDate + " and " + endDate);
        return bills;
    }

    /**
     * Get total amount spent by user
     */
    public BigDecimal getTotalAmountByUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            LOGGER.warning("Username is required");
            return BigDecimal.ZERO;
        }

        BigDecimal total = billDAO.getTotalAmountByUsername(username.trim());
        LOGGER.info("Total amount for user " + username + ": " + total);
        return total;
    }

    /**
     * Get bill statistics
     */
    public BillStatistics getBillStatistics() {
        List<Bill> allBills = billDAO.getAllBills();

        BillStatistics stats = new BillStatistics();
        stats.setTotalBills(allBills.size());

        BigDecimal totalAmount = BigDecimal.ZERO;
        int instoreCount = 0;
        int onlineCount = 0;

        for (Bill bill : allBills) {
            totalAmount = totalAmount.add(bill.getAmount());

            String type = bill.getBillType().toUpperCase();
            if ("INSTORE".equals(type)) {
                instoreCount++;
            } else if ("ONLINE".equals(type)) {
                onlineCount++;
            }
        }

        stats.setTotalAmount(totalAmount);
        stats.setInstoreBills(instoreCount);
        stats.setOnlineBills(onlineCount);

        stats.setAverageAmount(allBills.isEmpty() ? BigDecimal.ZERO :
            totalAmount.divide(new BigDecimal(allBills.size()), 2, BigDecimal.ROUND_HALF_UP));

        LOGGER.info("Bill statistics calculated - Total: " + stats.getTotalBills() +
                   ", Amount: " + stats.getTotalAmount() +
                   ", In-store: " + instoreCount +
                   ", Online: " + onlineCount);

        return stats;
    }

    /**
     * Validate bill type (only ONLINE or INSTORE allowed)
     */
    private boolean isValidBillType(String billType) {
        if (billType == null) return false;
        String upperType = billType.toUpperCase();
        return "ONLINE".equals(upperType) || "INSTORE".equals(upperType);
    }

    /**
     * Inner class for bill statistics
     */
    public static class BillStatistics {
        private int totalBills;
        private BigDecimal totalAmount;
        private BigDecimal averageAmount;
        private int instoreBills;
        private int onlineBills;

        public int getTotalBills() { return totalBills; }
        public void setTotalBills(int totalBills) { this.totalBills = totalBills; }

        public BigDecimal getTotalAmount() { return totalAmount; }
        public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }

        public BigDecimal getAverageAmount() { return averageAmount; }
        public void setAverageAmount(BigDecimal averageAmount) { this.averageAmount = averageAmount; }

        public int getInstoreBills() { return instoreBills; }
        public void setInstoreBills(int instoreBills) { this.instoreBills = instoreBills; }

        public int getOnlineBills() { return onlineBills; }
        public void setOnlineBills(int onlineBills) { this.onlineBills = onlineBills; }
    }
}