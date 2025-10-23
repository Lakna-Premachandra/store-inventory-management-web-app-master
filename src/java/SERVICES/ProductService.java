package SERVICES;

import DAO.ProductDAO;
import DAO.StoreInventoryDAO;
import DAO.OnlineInventoryDAO;
import DAO.CartDAO;
import MODELS.Cart;
import MODELS.Product;
import MODELS.StoreInventory;
import MODELS.OnlineInventory;

import java.math.BigDecimal;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductService {
    private static final Logger LOGGER = Logger.getLogger(ProductService.class.getName());
    private final ProductDAO productDAO;
    private final StoreInventoryDAO storeInventoryDAO;
    private final OnlineInventoryDAO onlineInventoryDAO;
    private final CartDAO cartDAO;

    public ProductService() {
        this.productDAO = new ProductDAO();
        this.storeInventoryDAO = new StoreInventoryDAO();
        this.onlineInventoryDAO = new OnlineInventoryDAO();
        this.cartDAO = new CartDAO();
    }

    /**
     * Add a new product with validation
     */
    public boolean addProduct(Product product) {
        if (product == null) {
            LOGGER.warning("Cannot add null product");
            return false;
        }
        if (product.getProductCode() == null || product.getProductCode().isEmpty()) {
            LOGGER.warning("Product code is required");
            return false;
        }
        if (product.getName() == null || product.getName().isEmpty()) {
            LOGGER.warning("Product name is required");
            return false;
        }
        if (product.getUnitPrice() == null || product.getUnitPrice().compareTo(BigDecimal.ZERO) < 0) {
            LOGGER.warning("Product price is required and must be non-negative");
            return false;
        }

        if (product.getDiscount() == null) {
            product.setDiscount(BigDecimal.ZERO);
        }

        if (product.getDiscount().compareTo(BigDecimal.ZERO) < 0) {
            LOGGER.warning("Discount cannot be negative");
            return false;
        }

        boolean success = productDAO.addProduct(product);
        if (success) {
            LOGGER.info("Product added successfully: " + product.getProductCode());
        } else {
            LOGGER.warning("Failed to add product: " + product.getProductCode());
        }
        return success;
    }

    /**
     * Add a new product with initial stock
     */
    public boolean addProductWithStock(Product product, int initialStock) {
        if (initialStock < 0) {
            LOGGER.warning("Initial stock cannot be negative");
            return false;
        }

        boolean productAdded = addProduct(product);
        if (!productAdded) {
            return false;
        }

        if (initialStock > 0) {
            StoreInventory inventory = new StoreInventory();
            inventory.setProductCode(product.getProductCode());
            inventory.setProductName(product.getName());
            inventory.setQuantity(initialStock);

            boolean inventoryAdded = storeInventoryDAO.insert(inventory);
            if (inventoryAdded) {
                LOGGER.info("Product and inventory added successfully: " + product.getProductCode() + 
                           " with stock: " + initialStock);
                return true;
            } else {
                LOGGER.warning("Product added but failed to add initial inventory for: " + 
                              product.getProductCode());
                return false;
            }
        }

        return true;
    }

    /**
     * Fetch all products
     */
    public List<Product> getAllProducts() {
        List<Product> products = productDAO.getAllProducts();
        if (products.isEmpty()) {
            LOGGER.info("No products found in database");
        } else {
            LOGGER.info(products.size() + " products retrieved");
        }
        return products;
    }

    /**
     * Fetch product by product code
     */
    public Product getProductByCode(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required");
            return null;
        }

        Product product = productDAO.getProductByCode(productCode);
        if (product == null) {
            LOGGER.info("No product found with code: " + productCode);
        } else {
            LOGGER.info("Product retrieved: " + product.getProductCode());
        }
        return product;
    }

    /**
     * Update existing product
     */
    public boolean updateProduct(Product product) {
        if (product == null) {
            LOGGER.warning("Cannot update null product");
            return false;
        }
        if (product.getProductCode() == null || product.getProductCode().isEmpty()) {
            LOGGER.warning("Product code is required for update");
            return false;
        }
        if (product.getName() == null || product.getName().isEmpty()) {
            LOGGER.warning("Product name is required");
            return false;
        }
        if (product.getUnitPrice() == null || product.getUnitPrice().compareTo(BigDecimal.ZERO) < 0) {
            LOGGER.warning("Product price is required and must be non-negative");
            return false;
        }

        if (product.getDiscount() == null) {
            product.setDiscount(BigDecimal.ZERO);
        }

        if (product.getDiscount().compareTo(BigDecimal.ZERO) < 0) {
            LOGGER.warning("Discount cannot be negative");
            return false;
        }

        boolean success = productDAO.updateProduct(product);
        if (success) {
            StoreInventory inventory = storeInventoryDAO.getByCode(product.getProductCode());
            if (inventory != null && !inventory.getProductName().equals(product.getName())) {
                inventory.setProductName(product.getName());
                storeInventoryDAO.update(inventory);
                LOGGER.info("Updated product name in inventory as well");
            }
            
            LOGGER.info("Product updated successfully: " + product.getProductCode());
        } else {
            LOGGER.warning("Failed to update product: " + product.getProductCode());
        }
        return success;
    }

    /**
     * Delete product and related inventory from ALL tables
     */
    public boolean deleteProduct(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required for deletion");
            return false;
        }

        // Delete from store_inventory if exists
        StoreInventory storeInventory = storeInventoryDAO.getByCode(productCode);
        if (storeInventory != null) {
            boolean storeInventoryDeleted = storeInventoryDAO.delete(productCode);
            if (!storeInventoryDeleted) {
                LOGGER.warning("Failed to delete store inventory for product: " + productCode);
                return false;
            }
            LOGGER.info("Store inventory deleted for product: " + productCode);
        }

        // Delete from online_inventory if exists
        OnlineInventory onlineInventory = onlineInventoryDAO.getByCode(productCode);
        if (onlineInventory != null) {
            boolean onlineInventoryDeleted = onlineInventoryDAO.delete(productCode);
            if (!onlineInventoryDeleted) {
                LOGGER.warning("Failed to delete online inventory for product: " + productCode);
                return false;
            }
            LOGGER.info("Online inventory deleted for product: " + productCode);
        }
        
        // Delete from cart if exists
boolean cartDeleted = cartDAO.deleteByProductCode(productCode);
if (cartDeleted) {
    LOGGER.info("Cart items deleted for product: " + productCode);
} 

        // Finally delete the product
        boolean success = productDAO.deleteProduct(productCode);
        if (success) {
            LOGGER.info("Product deleted successfully: " + productCode);
        } else {
            LOGGER.warning("Failed to delete product: " + productCode);
        }
        return success;
    }

    /**
     * Check if product exists
     */
    public boolean productExists(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            return false;
        }
        return productDAO.getProductByCode(productCode) != null;
    }

    /**
     * Get product with current stock information
     */
    public ProductWithStock getProductWithStock(String productCode) {
        if (productCode == null || productCode.isEmpty()) {
            LOGGER.warning("Product code is required");
            return null;
        }

        Product product = productDAO.getProductByCode(productCode);
        if (product == null) {
            LOGGER.info("No product found with code: " + productCode);
            return null;
        }

        StoreInventory inventory = storeInventoryDAO.getByCode(productCode);
        int stockLevel = inventory != null ? inventory.getQuantity() : 0;

        return new ProductWithStock(product, stockLevel);
    }

    /**
     * Inner class to represent Product with Stock information
     */
    public static class ProductWithStock {
        private Product product;
        private int stockLevel;

        public ProductWithStock(Product product, int stockLevel) {
            this.product = product;
            this.stockLevel = stockLevel;
        }

        public Product getProduct() { return product; }
        public int getStockLevel() { return stockLevel; }
        public void setProduct(Product product) { this.product = product; }
        public void setStockLevel(int stockLevel) { this.stockLevel = stockLevel; }
    }
}