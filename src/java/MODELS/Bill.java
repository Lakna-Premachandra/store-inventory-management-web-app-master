package MODELS;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Bill {
    private int billId;
    private Timestamp billDate;
    private BigDecimal amount;
    private String username;
    private String fullName;
    private String billType;
    private BigDecimal cashTendered;
    private BigDecimal changeAmount;
    
    // Constructors
    public Bill() {}
    
    public Bill(BigDecimal amount, String username, String fullName, String billType) {
        this.amount = amount;
        this.username = username;
        this.fullName = fullName;
        this.billType = billType;
    }
    
    public Bill(int billId, Timestamp billDate, BigDecimal amount, String username, 
                String fullName, String billType, BigDecimal cashTendered, BigDecimal changeAmount) {
        this.billId = billId;
        this.billDate = billDate;
        this.amount = amount;
        this.username = username;
        this.fullName = fullName;
        this.billType = billType;
        this.cashTendered = cashTendered;
        this.changeAmount = changeAmount;
    }
    
    // Getters and Setters
    public int getBillId() {
        return billId;
    }
    
    public void setBillId(int billId) {
        this.billId = billId;
    }
    
    public Timestamp getBillDate() {
        return billDate;
    }
    
    public void setBillDate(Timestamp billDate) {
        this.billDate = billDate;
    }
    
    public BigDecimal getAmount() {
        return amount;
    }
    
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getBillType() {
        return billType;
    }
    
    public void setBillType(String billType) {
        this.billType = billType;
    }
    
    public BigDecimal getCashTendered() {
        return cashTendered;
    }
    
    public void setCashTendered(BigDecimal cashTendered) {
        this.cashTendered = cashTendered;
        // Auto-calculate change if amount is set
        if (this.amount != null && cashTendered != null) {
            this.changeAmount = cashTendered.subtract(this.amount);
        }
    }
    
    public BigDecimal getChangeAmount() {
        return changeAmount;
    }
    
    public void setChangeAmount(BigDecimal changeAmount) {
        this.changeAmount = changeAmount;
    }
    
    @Override
    public String toString() {
        return "Bill{" +
                "billId=" + billId +
                ", billDate=" + billDate +
                ", amount=" + amount +
                ", username='" + username + '\'' +
                ", fullName='" + fullName + '\'' +
                ", billType='" + billType + '\'' +
                ", cashTendered=" + cashTendered +
                ", changeAmount=" + changeAmount +
                '}';
    }
}