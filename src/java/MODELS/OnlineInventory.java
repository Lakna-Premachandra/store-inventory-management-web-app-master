package MODELS;

public class OnlineInventory {
    private String productCode;
    private int quantity;

    public OnlineInventory() {
    }

    public OnlineInventory(String productCode, int quantity) {
        this.productCode = productCode;
        this.quantity = quantity;
    }

    // Getters
    public String getProductCode() {
        return productCode;
    }

    public int getQuantity() {
        return quantity;
    }

    // Setters
    public void setProductCode(String productCode) {
        this.productCode = productCode;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    @Override
    public String toString() {
        return "OnlineInventory{" +
                "productCode='" + productCode + '\'' +
                ", quantity=" + quantity +
                '}';
    }
}