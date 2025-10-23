package SERVELETS;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/ProductSalesReportServlet")
public class ProductSalesReportServlet extends HttpServlet {
    private Gson gson;

    @Override
    public void init() throws ServletException {
        gson = new GsonBuilder().setPrettyPrinting().create();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();

        try {
            ProductSalesReport report = generateProductSalesReport();
            out.print(gson.toJson(report));
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }

    private ProductSalesReport generateProductSalesReport() throws SQLException {
        ProductSalesReport report = new ProductSalesReport();
        Connection conn = null;

        try {
            conn = getConnection();

            // Get total products count
            report.totalProducts = getTotalProductsCount(conn);

            // Get products with sales
            report.productsWithSales = getProductsWithSalesCount(conn);

            // Get products without sales
            report.productsWithoutSales = report.totalProducts - report.productsWithSales;

            // Get best selling products
            report.bestSellingProducts = getBestSellingProducts(conn);

            // Get products not sold
            report.notSoldProducts = getNotSoldProducts(conn);

            // Get total revenue
            report.totalRevenue = getTotalRevenue(conn);

            // Get total discount given
            report.totalDiscountGiven = getTotalDiscountGiven(conn);

            // Get current stock value
            report.currentStockValue = getCurrentStockValue(conn);

            // Get all products with sales details
            report.allProductsSales = getAllProductsSalesDetails(conn);

        } finally {
            if (conn != null) conn.close();
        }

        return report;
    }

    private int getTotalProductsCount(Connection conn) throws SQLException {
        String sql = "SELECT COUNT(*) as count FROM products";
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt("count");
            }
        }
        return 0;
    }

    private int getProductsWithSalesCount(Connection conn) throws SQLException {
        String sql = "SELECT COUNT(DISTINCT product_code) as count FROM online_inventory WHERE quantity > 0";
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt("count");
            }
        }
        return 0;
    }

    private List<ProductSalesDetail> getBestSellingProducts(Connection conn) throws SQLException {
        String sql = "SELECT p.product_code, p.name, p.unit_price, p.discount, " +
                     "COALESCE(oi.quantity, 0) as total_sold, " +
                     "COALESCE(si.quantity, 0) as current_stock, " +
                     "(p.unit_price - p.discount) as discounted_price, " +
                     "(COALESCE(oi.quantity, 0) * (p.unit_price - p.discount)) as total_revenue " +
                     "FROM products p " +
                     "LEFT JOIN online_inventory oi ON p.product_code = oi.product_code " +
                     "LEFT JOIN store_inventory si ON p.product_code = si.product_code " +
                     "WHERE COALESCE(oi.quantity, 0) > 0 " +
                     "ORDER BY total_sold DESC, total_revenue DESC " +
                     "LIMIT 10";

        List<ProductSalesDetail> products = new ArrayList<>();
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                ProductSalesDetail detail = new ProductSalesDetail();
                detail.productCode = rs.getString("product_code");
                detail.productName = rs.getString("name");
                detail.unitPrice = rs.getBigDecimal("unit_price");
                detail.discount = rs.getBigDecimal("discount");
                detail.totalSold = rs.getInt("total_sold");
                detail.currentStock = rs.getInt("current_stock");
                detail.discountedPrice = rs.getBigDecimal("discounted_price");
                detail.totalRevenue = rs.getBigDecimal("total_revenue");
                products.add(detail);
            }
        }
        return products;
    }

    private List<ProductSalesDetail> getNotSoldProducts(Connection conn) throws SQLException {
        String sql = "SELECT p.product_code, p.name, p.unit_price, p.discount, " +
                     "COALESCE(si.quantity, 0) as current_stock, " +
                     "(p.unit_price - p.discount) as discounted_price " +
                     "FROM products p " +
                     "LEFT JOIN online_inventory oi ON p.product_code = oi.product_code " +
                     "LEFT JOIN store_inventory si ON p.product_code = si.product_code " +
                     "WHERE COALESCE(oi.quantity, 0) = 0 " +
                     "ORDER BY p.name";

        List<ProductSalesDetail> products = new ArrayList<>();
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                ProductSalesDetail detail = new ProductSalesDetail();
                detail.productCode = rs.getString("product_code");
                detail.productName = rs.getString("name");
                detail.unitPrice = rs.getBigDecimal("unit_price");
                detail.discount = rs.getBigDecimal("discount");
                detail.totalSold = 0;
                detail.currentStock = rs.getInt("current_stock");
                detail.discountedPrice = rs.getBigDecimal("discounted_price");
                detail.totalRevenue = BigDecimal.ZERO;
                products.add(detail);
            }
        }
        return products;
    }

    private BigDecimal getTotalRevenue(Connection conn) throws SQLException {
        String sql = "SELECT SUM(oi.quantity * (p.unit_price - p.discount)) as total " +
                     "FROM online_inventory oi " +
                     "JOIN products p ON oi.product_code = p.product_code";
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                BigDecimal total = rs.getBigDecimal("total");
                return total != null ? total : BigDecimal.ZERO;
            }
        }
        return BigDecimal.ZERO;
    }

    private BigDecimal getTotalDiscountGiven(Connection conn) throws SQLException {
        String sql = "SELECT SUM(oi.quantity * p.discount) as total " +
                     "FROM online_inventory oi " +
                     "JOIN products p ON oi.product_code = p.product_code";
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                BigDecimal total = rs.getBigDecimal("total");
                return total != null ? total : BigDecimal.ZERO;
            }
        }
        return BigDecimal.ZERO;
    }

    private BigDecimal getCurrentStockValue(Connection conn) throws SQLException {
        String sql = "SELECT SUM(si.quantity * (p.unit_price - p.discount)) as total " +
                     "FROM store_inventory si " +
                     "JOIN products p ON si.product_code = p.product_code";
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                BigDecimal total = rs.getBigDecimal("total");
                return total != null ? total : BigDecimal.ZERO;
            }
        }
        return BigDecimal.ZERO;
    }

    private List<ProductSalesDetail> getAllProductsSalesDetails(Connection conn) throws SQLException {
        String sql = "SELECT p.product_code, p.name, p.unit_price, p.discount, " +
                     "COALESCE(oi.quantity, 0) as total_sold, " +
                     "COALESCE(si.quantity, 0) as current_stock, " +
                     "(p.unit_price - p.discount) as discounted_price, " +
                     "(COALESCE(oi.quantity, 0) * (p.unit_price - p.discount)) as total_revenue " +
                     "FROM products p " +
                     "LEFT JOIN online_inventory oi ON p.product_code = oi.product_code " +
                     "LEFT JOIN store_inventory si ON p.product_code = si.product_code " +
                     "ORDER BY total_sold DESC, p.name";

        List<ProductSalesDetail> products = new ArrayList<>();
        try (Statement stmt = conn.createStatement(); 
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                ProductSalesDetail detail = new ProductSalesDetail();
                detail.productCode = rs.getString("product_code");
                detail.productName = rs.getString("name");
                detail.unitPrice = rs.getBigDecimal("unit_price");
                detail.discount = rs.getBigDecimal("discount");
                detail.totalSold = rs.getInt("total_sold");
                detail.currentStock = rs.getInt("current_stock");
                detail.discountedPrice = rs.getBigDecimal("discounted_price");
                detail.totalRevenue = rs.getBigDecimal("total_revenue");
                products.add(detail);
            }
        }
        return products;
    }

    private Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/finalsyosdb", 
                "root", 
                "your_password"
            );
        } catch (ClassNotFoundException e) {
            throw new SQLException("Database driver not found", e);
        }
    }

    // Inner classes for JSON response
    public static class ProductSalesReport {
        public int totalProducts;
        public int productsWithSales;
        public int productsWithoutSales;
        public List<ProductSalesDetail> bestSellingProducts;
        public List<ProductSalesDetail> notSoldProducts;
        public BigDecimal totalRevenue;
        public BigDecimal totalDiscountGiven;
        public BigDecimal currentStockValue;
        public List<ProductSalesDetail> allProductsSales;
    }

    public static class ProductSalesDetail {
        public String productCode;
        public String productName;
        public BigDecimal unitPrice;
        public BigDecimal discount;
        public int totalSold;
        public int currentStock;
        public BigDecimal discountedPrice;
        public BigDecimal totalRevenue;
    }
}