package SERVICES;

import DAO.StoreInventoryDAO;
import DAO.ProductDAO;
import MODELS.StoreInventory;
import MODELS.Product;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class StoreInventoryService {
    private static final Logger LOGGER = Logger.getLogger(StoreInventoryService.class.getName());
    private final StoreInventoryDAO storeInventoryDAO;
    private final ProductDAO productDAO;

    public StoreInventoryService() {
        this.storeInventoryDAO = new StoreInventoryDAO();
        this.productDAO = new ProductDAO();
    }

    /**
     * Add new inventory entry for a product
     */
    public boolean addInventory(StoreInventory inventory) {
        if (inventory == null) {
            LOGGER.warning("Cannot add null inventory");
            return false;
        }
        
        if (inventory.getProductCode() == null || inventory.getProductCode().isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }

        // Validate that the product exists
        Product product = productDAO.getProductByCode(inventory.getProductCode());
        if (product == null) {
            LOGGER.warning("Product does not exist with code: " + inventory.getProductCode());
            return false;
        }

        // Set product name from the product table
        inventory.setProductName(product.getName());

        // Check if inventory already exists for this product
        StoreInventory existingInventory = storeInventoryDAO.getByCode(inventory.getProductCode());
        if (existingInventory != null) {
            LOGGER.warning("Inventory already exists for product: " + inventory.getProductCode());
            return false;
        }

        if (inventory.getQuantity() < 0) {
            LOGGER.warning("Quantity cannot be negative");
            return false;
        }

        boolean success = storeInventoryDAO.insert(inventory);
        if (success) {
            LOGGER.info("Inventory added successfully for product: " + inventory.getProductCode());
        } else {
            LOGGER.warning("Failed to add inventory for product: " + inventory.getProductCode());
        }
        return success;
    }

    /**
     * Get all inventory items
     */
    public List<StoreInventory> getAllInventory() {
        List<StoreInventory> inventoryList = storeInventoryDAO.getAll();
        if (inventoryList.isEmpty()) {
            LOGGER.info("No inventory items found");
        } else {
            LOGGER.info(inventoryList.size() + " inventory items retrieved");
        }
        return inventoryList;
    }

    /**
     * Get inventory by product code
     */
    public StoreInventory getInventoryByCode(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required");
            return null;
        }

        StoreInventory inventory = storeInventoryDAO.getByCode(productCode);
        if (inventory == null) {
            LOGGER.info("No inventory found for product code: " + productCode);
        } else {
            LOGGER.info("Inventory retrieved for product: " + inventory.getProductCode());
        }
        return inventory;
    }

    /**
     * Update inventory quantity and details
     */
    public boolean updateInventory(StoreInventory inventory) {
        if (inventory == null) {
            LOGGER.warning("Cannot update null inventory");
            return false;
        }
        
        if (inventory.getProductCode() == null || inventory.getProductCode().isEmpty()) {
            LOGGER.warning("Product code is required for update");
            return false;
        }

        // Validate that the product exists
        Product product = productDAO.getProductByCode(inventory.getProductCode());
        if (product == null) {
            LOGGER.warning("Product does not exist with code: " + inventory.getProductCode());
            return false;
        }

        // Check if inventory exists
        StoreInventory existingInventory = storeInventoryDAO.getByCode(inventory.getProductCode());
        if (existingInventory == null) {
            LOGGER.warning("Inventory does not exist for product: " + inventory.getProductCode());
            return false;
        }

        if (inventory.getQuantity() < 0) {
            LOGGER.warning("Quantity cannot be negative");
            return false;
        }

        // Update product name from the product table to ensure consistency
        inventory.setProductName(product.getName());

        boolean success = storeInventoryDAO.update(inventory);
        if (success) {
            LOGGER.info("Inventory updated successfully for product: " + inventory.getProductCode());
        } else {
            LOGGER.warning("Failed to update inventory for product: " + inventory.getProductCode());
        }
        return success;
    }

    /**
     * Add stock to existing inventory
     */
    public boolean addStock(String productCode, int quantityToAdd) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }

        if (quantityToAdd <= 0) {
            LOGGER.warning("Quantity to add must be positive");
            return false;
        }

        StoreInventory existingInventory = storeInventoryDAO.getByCode(productCode);
        if (existingInventory == null) {
            LOGGER.warning("Inventory does not exist for product: " + productCode);
            return false;
        }

        int newQuantity = existingInventory.getQuantity() + quantityToAdd;
        existingInventory.setQuantity(newQuantity);
        
        boolean success = storeInventoryDAO.update(existingInventory);
        if (success) {
            LOGGER.info("Added " + quantityToAdd + " units to product " + productCode + 
                       ". New quantity: " + newQuantity);
        }
        return success;
    }

    /**
     * Reduce stock from existing inventory
     */
    public boolean reduceStock(String productCode, int quantityToReduce) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }

        if (quantityToReduce <= 0) {
            LOGGER.warning("Quantity to reduce must be positive");
            return false;
        }

        StoreInventory existingInventory = storeInventoryDAO.getByCode(productCode);
        if (existingInventory == null) {
            LOGGER.warning("Inventory does not exist for product: " + productCode);
            return false;
        }

        if (existingInventory.getQuantity() < quantityToReduce) {
            LOGGER.warning("Insufficient stock. Available: " + existingInventory.getQuantity() + 
                          ", Required: " + quantityToReduce);
            return false;
        }

        int newQuantity = existingInventory.getQuantity() - quantityToReduce;
        existingInventory.setQuantity(newQuantity);
        
        boolean success = storeInventoryDAO.update(existingInventory);
        if (success) {
            LOGGER.info("Reduced " + quantityToReduce + " units from product " + productCode + 
                       ". New quantity: " + newQuantity);
        }
        return success;
    }

    /**
     * Delete inventory entry
     */
    public boolean deleteInventory(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required for deletion");
            return false;
        }

        boolean success = storeInventoryDAO.delete(productCode);
        if (success) {
            LOGGER.info("Inventory deleted successfully for product: " + productCode);
        } else {
            LOGGER.warning("Failed to delete inventory for product: " + productCode);
        }
        return success;
    }

    /**
     * Check if sufficient stock is available
     */
    public boolean isStockAvailable(String productCode, int requiredQuantity) {
        if (productCode == null || productCode.isEmpty() || requiredQuantity <= 0) {
            return false;
        }

        StoreInventory inventory = storeInventoryDAO.getByCode(productCode);
        return inventory != null && inventory.getQuantity() >= requiredQuantity;
    }

    /**
     * Get current stock level for a product
     */
    public int getStockLevel(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            return 0;
        }

        StoreInventory inventory = storeInventoryDAO.getByCode(productCode);
        return inventory != null ? inventory.getQuantity() : 0;
    }
}