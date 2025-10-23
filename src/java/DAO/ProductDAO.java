package DAO;

import MODELS.Product;
import UTILS.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ProductDAO {
    private static final Logger LOGGER = Logger.getLogger(ProductDAO.class.getName());

    private static final String INSERT_PRODUCT =
        "INSERT INTO products (product_code, name, unit_price, discount) VALUES (?, ?, ?, ?)";
    private static final String SELECT_ALL_PRODUCTS =
        "SELECT * FROM products ORDER BY name";
    private static final String SELECT_PRODUCT_BY_CODE =
        "SELECT * FROM products WHERE product_code = ?";
    private static final String UPDATE_PRODUCT =
        "UPDATE products SET name = ?, unit_price = ?, discount = ? WHERE product_code = ?";
    private static final String DELETE_PRODUCT =
        "DELETE FROM products WHERE product_code = ?";

    public boolean addProduct(Product product) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(INSERT_PRODUCT)) {

            stmt.setString(1, product.getProductCode());
            stmt.setString(2, product.getName());
            stmt.setBigDecimal(3, product.getUnitPrice());
            stmt.setBigDecimal(4, product.getDiscount());

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error inserting product", e);
            return false;
        }
    }

    public List<Product> getAllProducts() {
        List<Product> products = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_ALL_PRODUCTS);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                products.add(mapResultSetToProduct(rs));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving products", e);
        }
        return products;
    }

    public Product getProductByCode(String code) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(SELECT_PRODUCT_BY_CODE)) {

            stmt.setString(1, code);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToProduct(rs);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving product by code", e);
        }
        return null;
    }

    public boolean updateProduct(Product product) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(UPDATE_PRODUCT)) {

            stmt.setString(1, product.getName());
            stmt.setBigDecimal(2, product.getUnitPrice());
            stmt.setBigDecimal(3, product.getDiscount());
            stmt.setString(4, product.getProductCode());

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating product", e);
            return false;
        }
    }

    public boolean deleteProduct(String code) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(DELETE_PRODUCT)) {

            stmt.setString(1, code);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error deleting product", e);
            return false;
        }
    }

    private Product mapResultSetToProduct(ResultSet rs) throws SQLException {
        Product product = new Product();
        product.setProductCode(rs.getString("product_code"));
        product.setName(rs.getString("name"));
        product.setUnitPrice(rs.getBigDecimal("unit_price"));
        product.setDiscount(rs.getBigDecimal("discount"));
        return product;
    }
}
