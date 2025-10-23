<%@page import="MODELS.Product"%>
<%@page import="SERVICES.ProductService"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="SERVICES.StoreInventoryService"%>
<%@page import="MODELS.StoreInventory"%>

<%
    // Initialize ProductService and load products server-side
    ProductService productService = new ProductService();
    List<Product> products = new ArrayList<>();
    String errorMessage = null;
    String successMessage = null;

    // Handle form submissions
    String action = request.getParameter("action");

    if ("add".equals(action)) {
        try {
            String productCode = request.getParameter("productCode");
            String productName = request.getParameter("productName");
            String unitPriceStr = request.getParameter("unitPrice");
            String discountStr = request.getParameter("discount");
            String initialStockStr = request.getParameter("initialStock");

            Product product = new Product();
            product.setProductCode(productCode);
            product.setName(productName);
            product.setUnitPrice(new java.math.BigDecimal(unitPriceStr));
            product.setDiscount(new java.math.BigDecimal(discountStr));

            boolean success;
            if (initialStockStr != null && !initialStockStr.trim().isEmpty()) {
                int initialStock = Integer.parseInt(initialStockStr);
                success = productService.addProductWithStock(product, initialStock);
            } else {
                success = productService.addProduct(product);
            }

            if (success) {
                successMessage = "Product added successfully!";
            } else {
                errorMessage = "Failed to add product. Product code may already exist.";
            }
        } catch (Exception e) {
            errorMessage = "Error adding product: " + e.getMessage();
        }
    } else if ("edit".equals(action)) {
        try {
            String productCode = request.getParameter("productCode");
            String productName = request.getParameter("productName");
            String unitPriceStr = request.getParameter("unitPrice");
            String discountStr = request.getParameter("discount");

            Product product = new Product();
            product.setProductCode(productCode);
            product.setName(productName);
            product.setUnitPrice(new java.math.BigDecimal(unitPriceStr));
            product.setDiscount(new java.math.BigDecimal(discountStr));

            boolean success = productService.updateProduct(product);
            if (success) {
                successMessage = "Product updated successfully!";
            } else {
                errorMessage = "Failed to update product.";
            }
        } catch (Exception e) {
            errorMessage = "Error updating product: " + e.getMessage();
        }
    } else if ("delete".equals(action)) {
        try {
            String productCode = request.getParameter("productCode");
            boolean success = productService.deleteProduct(productCode);
            if (success) {
                successMessage = "Product deleted successfully!";
            } else {
                errorMessage = "Failed to delete product.";
            }
        } catch (Exception e) {
            errorMessage = "Error deleting product: " + e.getMessage();
        }

    } else if ("updateStock".equals(action)) {
        try {
            String productCode = request.getParameter("productCode");
            String quantityStr = request.getParameter("quantity");

            if (productCode != null && quantityStr != null) {
                int newQuantity = Integer.parseInt(quantityStr);

                // Create StoreInventoryService instance
                StoreInventoryService inventoryService = new StoreInventoryService();

                // Create StoreInventory object
                StoreInventory inventory = new StoreInventory();
                inventory.setProductCode(productCode);
                inventory.setQuantity(newQuantity);

                // Update the stock
                boolean success = inventoryService.updateInventory(inventory);

                if (success) {
                    successMessage = "Stock updated successfully!";
                } else {
                    errorMessage = "Failed to update stock.";
                }
            } else {
                errorMessage = "Invalid stock update data.";
            }
        } catch (Exception e) {
            errorMessage = "Error updating stock: " + e.getMessage();
        }
    }

    // Load products after any operations
    try {
        products = productService.getAllProducts();
    } catch (Exception e) {
        if (errorMessage == null) {
            errorMessage = "Error loading products: " + e.getMessage();
        }
        e.printStackTrace();
    }
%>
<%
    // Handle stock view request
    String viewStock = request.getParameter("viewStock");
    String stockProductCode = request.getParameter("stockProductCode");

    if ("true".equals(viewStock) && stockProductCode != null) {
        try {
            ProductService.ProductWithStock productWithStock = productService.getProductWithStock(stockProductCode);

            request.setAttribute("productWithStock", productWithStock);
            request.setAttribute("stockProductCode", stockProductCode);
        } catch (Exception e) {
            request.setAttribute("stockError", "Error loading stock details: " + e.getMessage());
        }
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Admin Panel - Syops Retail Shop</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                min-height: 100vh;
            }

            .header {
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white;
                padding: 1.5rem 2rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            }

            .logo {
                font-size: 2.2rem;
                font-weight: bold;
                background: linear-gradient(135deg, #3498db, #e74c3c);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
            }

            .nav-options {
                display: flex;
                gap: 1rem;
                align-items: center;
            }

            .nav-btn {
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
                border: none;
                padding: 0.7rem 1.2rem;
                border-radius: 8px;
                cursor: pointer;
                font-size: 1rem;
                transition: all 0.3s ease;
                text-decoration: none;
                display: inline-block;
                font-weight: 500;
            }

            .nav-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4);
            }

            .container {
                max-width: 1400px;
                margin: 2rem auto;
                padding: 0 1rem;
            }

            .admin-section {
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(10px);
                padding: 2.5rem;
                border-radius: 20px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                margin-bottom: 2rem;
                border: 1px solid rgba(255,255,255,0.2);
            }

            .section-title {
                text-align: center;
                margin-bottom: 2.5rem;
                color: #2c3e50;
                font-size: 2.2rem;
                font-weight: 700;
                position: relative;
            }

            .section-title::after {
                content: '';
                position: absolute;
                bottom: -10px;
                left: 50%;
                transform: translateX(-50%);
                width: 100px;
                height: 4px;
                background: linear-gradient(135deg, #3498db, #e74c3c);
                border-radius: 2px;
            }

            .action-buttons {
                display: flex;
                gap: 1rem;
                margin-bottom: 2rem;
                justify-content: space-between;
                align-items: center;
            }

            .search-container {
                position: relative;
                flex: 1;
                max-width: 300px;
            }

            .search-input {
                width: 100%;
                padding: 0.8rem 1rem;
                border: 2px solid #e2e8f0;
                border-radius: 10px;
                font-size: 1rem;
                transition: all 0.3s ease;
            }

            .search-input:focus {
                outline: none;
                border-color: #3498db;
                box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
            }

            .add-btn {
                background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
                color: white;
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: 10px;
                cursor: pointer;
                font-size: 1rem;
                font-weight: 600;
                transition: all 0.3s ease;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .add-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(39, 174, 96, 0.3);
            }

            .refresh-btn {
                background: linear-gradient(135deg, #8e44ad 0%, #9b59b6 100%);
                color: white;
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: 10px;
                cursor: pointer;
                font-size: 1rem;
                font-weight: 600;
                transition: all 0.3s ease;
                text-decoration: none;
                display: inline-block;
            }

            .refresh-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(142, 68, 173, 0.3);
            }

            .products-table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 1rem;
                background: white;
                border-radius: 12px;
                overflow: hidden;
                box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            }

            .products-table th,
            .products-table td {
                padding: 1.2rem;
                text-align: left;
                border-bottom: 1px solid #f1f5f9;
            }

            .products-table th {
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white;
                font-weight: 600;
                font-size: 0.9rem;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .products-table tbody tr {
                transition: all 0.3s ease;
            }

            .products-table tbody tr:hover {
                background-color: #f8fafc;
                transform: scale(1.01);
            }

            .action-btn {
                padding: 0.5rem 1rem;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 0.85rem;
                margin-right: 0.5rem;
                transition: all 0.3s ease;
                font-weight: 500;
            }

            .edit-btn {
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
            }

            .edit-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(52, 152, 219, 0.3);
            }

            .delete-btn {
                background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
                color: white;
            }

            .delete-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(231, 76, 60, 0.3);
            }

            .price-cell {
                color: #e74c3c;
                font-weight: 700;
                font-size: 1.1rem;
            }

            .discount-cell {
                color: #f39c12;
                font-weight: 700;
            }
            .view-stock-btn {
                background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
                color: white;
            }

            .view-stock-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(243, 156, 18, 0.3);
            }

            .no-data {
                text-align: center;
                color: #7f8c8d;
                padding: 3rem;
                font-style: italic;
                font-size: 1.1rem;
            }

            .error-message {
                background: linear-gradient(135deg, #fed7d7 0%, #feb2b2 100%);
                color: #c53030;
                padding: 1rem 1.2rem;
                border-radius: 10px;
                margin-bottom: 1rem;
                font-weight: 500;
                border-left: 4px solid #e53e3e;
            }

            .success-message {
                background: linear-gradient(135deg, #c6f6d5 0%, #9ae6b4 100%);
                color: #2f855a;
                padding: 1rem 1.2rem;
                border-radius: 10px;
                margin-bottom: 1rem;
                font-weight: 500;
                border-left: 4px solid #38a169;
            }

            .stats-section {
                display: flex;
                gap: 1rem;
                margin-bottom: 2rem;
            }

            .stat-card {
                background: rgba(255, 255, 255, 0.9);
                backdrop-filter: blur(10px);
                padding: 1.5rem;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                flex: 1;
                text-align: center;
                border: 1px solid rgba(255,255,255,0.2);
            }

            .stat-number {
                font-size: 2rem;
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 0.5rem;
            }

            .stat-label {
                color: #7f8c8d;
                font-size: 0.9rem;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            /* Modal Styles */
            .modal {
                display: none;
                position: fixed;
                z-index: 1000;
                left: 0;
                top: 0;
                width: 100%;
                height: 100%;
                background-color: rgba(0,0,0,0.6);
                backdrop-filter: blur(5px);
                animation: fadeIn 0.3s ease;
            }

            @keyframes fadeIn {
                from {
                    opacity: 0;
                }
                to {
                    opacity: 1;
                }
            }

            @keyframes slideIn {
                from {
                    transform: translate(-50%, -60%);
                    opacity: 0;
                }
                to {
                    transform: translate(-50%, -50%);
                    opacity: 1;
                }
            }

            .modal-content {
                background: rgba(255, 255, 255, 0.98);
                backdrop-filter: blur(20px);
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                padding: 2.5rem;
                border-radius: 20px;
                width: 90%;
                max-width: 550px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                border: 1px solid rgba(255,255,255,0.2);
                animation: slideIn 0.3s ease;
            }

            .modal-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 2rem;
                color: #2c3e50;
            }

            .modal-header h3 {
                font-size: 1.8rem;
                font-weight: 700;
            }

            .close {
                color: #aaa;
                font-size: 32px;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s ease;
                width: 40px;
                height: 40px;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 50%;
            }

            .close:hover {
                color: #e74c3c;
                background: rgba(231, 76, 60, 0.1);
                transform: rotate(90deg);
            }

            .form-group {
                margin-bottom: 1.5rem;
            }

            .form-group label {
                display: block;
                margin-bottom: 0.7rem;
                color: #2c3e50;
                font-weight: 600;
                font-size: 0.9rem;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .form-group input {
                width: 100%;
                padding: 1rem;
                border: 2px solid #e2e8f0;
                border-radius: 10px;
                font-size: 1rem;
                transition: all 0.3s ease;
                background: rgba(247, 250, 252, 0.8);
            }

            .form-group input:focus {
                outline: none;
                border-color: #3498db;
                box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
                background: white;
                transform: translateY(-2px);
            }

            .form-group input:disabled {
                background-color: #f1f5f9;
                color: #64748b;
                cursor: not-allowed;
            }

            .form-buttons {
                display: flex;
                gap: 1rem;
                justify-content: flex-end;
                margin-top: 2rem;
            }

            .btn-primary {
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: 10px;
                cursor: pointer;
                font-size: 1rem;
                font-weight: 600;
                transition: all 0.3s ease;
            }

            .btn-primary:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(52, 152, 219, 0.3);
            }

            .btn-secondary {
                background: linear-gradient(135deg, #95a5a6 0%, #7f8c8d 100%);
                color: white;
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: 10px;
                cursor: pointer;
                font-size: 1rem;
                font-weight: 600;
                transition: all 0.3s ease;
            }

            .btn-secondary:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(149, 165, 166, 0.3);
            }

            .btn-danger {
                background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
                color: white;
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: 10px;
                cursor: pointer;
                font-size: 1rem;
                font-weight: 600;
                transition: all 0.3s ease;
            }

            .btn-danger:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(231, 76, 60, 0.3);
            }

            @media (max-width: 768px) {
                .container {
                    padding: 0 0.5rem;
                }

                .admin-section {
                    padding: 1.5rem;
                }

                .action-buttons {
                    flex-direction: column;
                    gap: 1rem;
                }

                .search-container {
                    max-width: 100%;
                }

                .products-table {
                    font-size: 0.85rem;
                }

                .products-table th,
                .products-table td {
                    padding: 0.8rem 0.5rem;
                }

                .stats-section {
                    flex-direction: column;
                }

                .modal-content {
                    width: 95%;
                    padding: 1.5rem;
                }
            }
        </style>
    </head>
    <body>
        <!-- Header Section -->
        <div class="header">
            <div class="logo">Syops Admin</div>
            <div class="nav-options">

                <a href="allProducts.jsp" class="nav-btn">All products</a>
                <a href="admin.jsp" class="nav-btn">Dashboard</a>

                <a href="adminBillDetails.jsp" class="nav-btn">Bill Details</a>
                <a href="reports.jsp" class="nav-btn">Reports</a>

                <a href="login.jsp" class="nav-btn">Logout</a>

            </div>
        </div>

        <!-- Main Content -->
        <div class="container">
            <!-- Statistics Section -->
            <div class="stats-section">
                <div class="stat-card">
                    <div class="stat-number"><%= products.size()%></div>
                    <div class="stat-label">Total Products</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">
                        <%= products.stream().filter(p -> p.getDiscount() != null && p.getDiscount().doubleValue() > 0).count()%>
                    </div>
                    <div class="stat-label">Products on Discount</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">
                        Rs<%= String.format("%.2f", products.stream().mapToDouble(p -> p.getUnitPrice() != null ? p.getUnitPrice().doubleValue() : 0).average().orElse(0))%>
                    </div>
                    <div class="stat-label">Average Price</div>
                </div>
            </div>

            <div class="admin-section">
                <h2 class="section-title">Product Management Dashboard</h2>

                <div class="action-buttons">
                    <div class="search-container">
                        <input type="text" class="search-input" id="searchInput" 
                               placeholder="Search products..." onkeyup="searchProducts()">
                    </div>
                    <div style="display: flex; gap: 1rem;">
                        <a href="admin.jsp" class="refresh-btn">Refresh</a>
                        <button class="add-btn" onclick="openAddModal()">
                            Add New Product
                        </button>
                    </div>
                </div>

                <!-- Error/Success Messages -->
                <% if (errorMessage != null) {%>
                <div class="error-message">
                    <%= errorMessage%>
                </div>
                <% } %>

                <% if (successMessage != null) {%>
                <div class="success-message">
                    <%= successMessage%>
                </div>
                <% } %>

                <!-- Products Table -->
                <table class="products-table" id="productsTable">
                    <thead>
                        <tr>
                            <th>Product Code</th>
                            <th>Name</th>
                            <th>Unit Price</th>
                            <th>Discount (%)</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="productsTableBody">
                        <% if (products.isEmpty()) { %>
                        <tr>
                            <td colspan="5" class="no-data">
                                <% if (errorMessage != null) { %>
                                No products could be loaded due to error
                                <% } else { %>
                                No products found. Click "Add New Product" to get started!
                                <% } %>
                            </td>
                        </tr>
                        <% } else { %>
                        <% for (Product product : products) {%>
                        <tr class="product-row" 
                            data-code="<%= product.getProductCode()%>"
                            data-name="<%= product.getName() != null ? product.getName().replace("\"", "&quot;") : ""%>"

                            data-price="<%= product.getUnitPrice() != null ? product.getUnitPrice() : "0"%>"
                            data-discount="<%= product.getDiscount() != null ? product.getDiscount() : "0"%>">
                            <td><strong><%= product.getProductCode() != null ? product.getProductCode() : "N/A"%></strong></td>
                            <td><%= product.getName() != null ? product.getName() : "N/A"%></td>
                            <td class="price-cell">
                                Rs<%= product.getUnitPrice() != null ? String.format("%.2f", product.getUnitPrice()) : "0.00"%>
                            </td>
                            <td class="discount-cell">
                                <%= product.getDiscount() != null ? String.format("%.1f", product.getDiscount()) : "0.0"%>%
                            </td>
                            <td>
                                <button class="action-btn edit-btn" onclick="openEditModal(
                                                '<%= product.getProductCode() != null ? product.getProductCode().replace("'", "\\'") : ""%>',
                                                '<%= product.getName() != null ? product.getName().replace("'", "\\'").replace("\"", "\\\"") : ""%>',
                                                '<%= product.getUnitPrice() != null ? product.getUnitPrice().toString() : "0"%>',
                                                '<%= product.getDiscount() != null ? product.getDiscount().toString() : "0"%>'
                                                )">Edit</button>
                                <button class="action-btn view-stock-btn" onclick="openStockModal('<%= product.getProductCode()%>', '<%= product.getName() != null ? product.getName().replace("'", "\\'").replace("\"", "\\\"") : ""%>')">
                                    View Stock
                                </button>
                                <button class="action-btn delete-btn" onclick="openDeleteModal('<%= product.getProductCode()%>', '<%= product.getName() != null ? product.getName().replace("'", "\\'").replace("\"", "\\\"") : ""%>')">
                                    Delete
                                </button>
                            </td>
                        </tr>
                        <% } %>
                        <% }%>
                    </tbody>
                </table>
            </div>
        </div>
        <!-- Stock Details Section (conditionally displayed) -->
        <% if (request.getParameter("viewStock") != null) { %>
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                document.getElementById('stockModal').style.display = 'block';
            });
        </script>
        <% }%>

        <!-- Stock Details Modal -->
        <div id="stockModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Stock Details</h3>
                    <span class="close" onclick="closeStockModal()">&times;</span>
                </div>

                <% if (request.getAttribute("stockError") != null) {%>
                <div class="error-message">
                    <%= request.getAttribute("stockError")%>
                </div>
                <% } else if (request.getAttribute("productWithStock") != null) {
                    ProductService.ProductWithStock productWithStock = (ProductService.ProductWithStock) request.getAttribute("productWithStock");
                %>
                <div style="margin-bottom: 2rem;">
                    <div class="form-group">
                        <label>Current Stock Level:</label>
                        <div style="background: #f8f9fa; padding: 1rem; border-radius: 8px; font-size: 1.2rem; font-weight: bold; color: <%= productWithStock.getStockLevel() > 0 ? "#27ae60" : "#e74c3c"%>;">
                            <%= productWithStock.getStockLevel()%> units
                        </div>
                    </div>
                </div>

                <!-- Form for updating stock - moved inside the if block -->
                <form method="post" action="admin.jsp" style="margin-top: 2rem;">
                    <input type="hidden" name="action" value="updateStock">
                    <input type="hidden" name="productCode" value="<%= request.getAttribute("stockProductCode")%>">

                    <div class="form-group">
                        <label for="newQuantity">New Stock Quantity:</label>
                        <input type="number" id="newQuantity" name="quantity" min="0" required 
                               value="<%= productWithStock.getStockLevel()%>"
                               placeholder="Enter new stock quantity">
                    </div>

                    <div class="form-buttons">
                        <button type="button" class="btn-secondary" onclick="closeStockModal()">Close</button>
                        <button type="submit" class="btn-primary">Update Stock</button>
                    </div>
                </form>

                <% } else { %>
                <div class="no-data">
                    <p>No stock information available for this product.</p>
                </div>
                <div class="form-buttons">
                    <button type="button" class="btn-secondary" onclick="closeStockModal()">Close</button>
                </div>
                <% }%>
            </div>
        </div>

        <!-- Add Product Modal -->
        <div id="addModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Add New Product</h3>
                    <span class="close" onclick="closeAddModal()">&times;</span>
                </div>
                <form method="post" action="admin.jsp">
                    <input type="hidden" name="action" value="add">
                    <div class="form-group">
                        <label for="addProductCode">Product Code:</label>
                        <input type="text" id="addProductCode" name="productCode" required 
                               placeholder="Enter unique product code">
                    </div>
                    <div class="form-group">
                        <label for="addProductName">Product Name:</label>
                        <input type="text" id="addProductName" name="productName" required 
                               placeholder="Enter product name">
                    </div>
                    <div class="form-group">
                        <label for="addUnitPrice">Unit Price (Rs):</label>
                        <input type="number" id="addUnitPrice" name="unitPrice" step="0.01" min="0" required 
                               placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label for="addDiscount">Discount (%):</label>
                        <input type="number" id="addDiscount" name="discount" step="0.01" min="0" max="100" required 
                               placeholder="0.00" value="0">
                    </div>
                    <div class="form-group">
                        <label for="addInitialStock">Initial Stock (Optional):</label>
                        <input type="number" id="addInitialStock" name="initialStock" min="0" 
                               placeholder="Enter initial stock quantity">
                    </div>
                    <div class="form-buttons">
                        <button type="button" class="btn-secondary" onclick="closeAddModal()">Cancel</button>
                        <button type="submit" class="btn-primary">Add Product</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Edit Product Modal -->
        <div id="editModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Edit Product</h3>
                    <span class="close" onclick="closeEditModal()">&times;</span>
                </div>
                <form method="post" action="admin.jsp">
                    <input type="hidden" name="action" value="edit">
                    <div class="form-group">
                        <label for="editProductCode">Product Code:</label>
                        <input type="text" id="editProductCode" name="productCode" readonly
                               style="background-color: #f1f5f9; color: #64748b;">
                    </div>
                    <div class="form-group">
                        <label for="editProductName">Product Name:</label>
                        <input type="text" id="editProductName" name="productName" required 
                               placeholder="Enter product name">
                    </div>
                    <div class="form-group">
                        <label for="editUnitPrice">Unit Price (Rs):</label>
                        <input type="number" id="editUnitPrice" name="unitPrice" step="0.01" min="0" required 
                               placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label for="editDiscount">Discount (%):</label>
                        <input type="number" id="editDiscount" name="discount" step="0.01" min="0" max="100" required 
                               placeholder="0.00">
                    </div>
                    <div class="form-buttons">
                        <button type="button" class="btn-secondary" onclick="closeEditModal()">Cancel</button>
                        <button type="submit" class="btn-primary">Update Product</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Delete Product Modal -->
        <div id="deleteModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Delete Product</h3>
                    <span class="close" onclick="closeDeleteModal()">&times;</span>
                </div>
                <div style="text-align: center; margin-bottom: 2rem;">
                    <p style="font-size: 1.1rem; color: #2c3e50; margin-bottom: 1rem;">
                        Are you sure you want to delete this product?
                    </p>
                    <strong id="deleteProductInfo"></strong>

                    <p style="color: #e74c3c; font-weight: 500;">
                        This will also delete all related inventory data and cannot be undone.
                    </p>
                </div>
                <form method="post" action="admin.jsp">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" id="deleteProductCode" name="productCode">
                    <div class="form-buttons">
                        <button type="button" class="btn-secondary" onclick="closeDeleteModal()">Cancel</button>
                        <button type="submit" class="btn-danger">Delete Product</button>
                    </div>
                </form>
            </div>
        </div>


        <script>
            // Store products data for search functionality
            const allRows = document.querySelectorAll('.product-row');

            // Search functionality
            function searchProducts() {
                const searchTerm = document.getElementById('searchInput').value.toLowerCase();
                const tbody = document.getElementById('productsTableBody');
                let visibleRows = 0;

                allRows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    const productCode = cells[0].textContent.toLowerCase();
                    const productName = cells[1].textContent.toLowerCase();

                    if (productCode.includes(searchTerm) || productName.includes(searchTerm)) {
                        row.style.display = '';
                        visibleRows++;
                    } else {
                        row.style.display = 'none';
                    }
                });

                // Show "no results" message if no rows visible
                if (visibleRows === 0 && allRows.length > 0 && searchTerm !== '') {
                    if (!document.getElementById('noSearchResults')) {
                        const noResultsRow = document.createElement('tr');
                        noResultsRow.id = 'noSearchResults';
                        noResultsRow.innerHTML = '<td colspan="5" class="no-data">No products found matching your search</td>';
                        tbody.appendChild(noResultsRow);
                    }
                } else {
                    const noResultsRow = document.getElementById('noSearchResults');
                    if (noResultsRow) {
                        noResultsRow.remove();
                    }
                }
            }

            // Modal functions
            function openAddModal() {
                document.getElementById('addModal').style.display = 'block';
                document.getElementById('addProductCode').focus();
            }

            function closeAddModal() {
                document.getElementById('addModal').style.display = 'none';
                document.getElementById('addModal').querySelector('form').reset();
            }

            function openEditModal(productCode, productName, unitPrice, discount) {
                // Direct parameter passing instead of data attribute lookup
                document.getElementById('editProductCode').value = productCode;
                document.getElementById('editProductName').value = productName;
                document.getElementById('editUnitPrice').value = parseFloat(unitPrice) || 0;
                document.getElementById('editDiscount').value = parseFloat(discount) || 0;

                document.getElementById('editModal').style.display = 'block';
                document.getElementById('editProductName').focus();
            }
            function closeEditModal() {
                document.getElementById('editModal').style.display = 'none';
                document.getElementById('editModal').querySelector('form').reset();
            }

            function openDeleteModal(productCode, productName) {
                document.getElementById('deleteProductCode').value = productCode;
                document.getElementById('deleteModal').style.display = 'block';
            }

            function closeDeleteModal() {
                document.getElementById('deleteModal').style.display = 'none';
            }

            // Close modals when clicking outside
            window.onclick = function (event) {
                const addModal = document.getElementById('addModal');
                const editModal = document.getElementById('editModal');
                const deleteModal = document.getElementById('deleteModal');

                if (event.target === addModal) {
                    closeAddModal();
                } else if (event.target === editModal) {
                    closeEditModal();
                } else if (event.target === deleteModal) {
                    closeDeleteModal();
                }
            }

            // Keyboard shortcuts
            document.addEventListener('keydown', function (e) {
                // Ctrl+N for new product
                if (e.ctrlKey && e.key === 'n') {
                    e.preventDefault();
                    openAddModal();
                }
                // Escape to close modals
                if (e.key === 'Escape') {
                    closeAddModal();
                    closeEditModal();
                    closeDeleteModal();
                }
                // Ctrl+R to refresh page
                if (e.ctrlKey && e.key === 'r') {
                    e.preventDefault();
                    window.location.reload();
                }
            });

            // Form validation
            document.addEventListener('DOMContentLoaded', function () {
                // Add form validation
                const forms = document.querySelectorAll('form');
                forms.forEach(form => {
                    form.addEventListener('submit', function (e) {
                        const inputs = this.querySelectorAll('input[required]');
                        let isValid = true;

                        inputs.forEach(input => {
                            if (!input.value.trim()) {
                                input.style.borderColor = '#e74c3c';
                                isValid = false;
                            } else {
                                input.style.borderColor = '#e2e8f0';
                            }
                        });

                        if (!isValid) {
                            e.preventDefault();
                            alert('Please fill in all required fields.');
                        }
                    });
                });

                // Auto-hide messages after 5 seconds
                const messages = document.querySelectorAll('.error-message, .success-message');
                messages.forEach(message => {
                    setTimeout(() => {
                        message.style.opacity = '0';
                        setTimeout(() => {
                            message.remove();
                        }, 300);
                    }, 5000);
                });

                // Auto-focus search input
                document.getElementById('searchInput').focus();
            });

            // Price formatting
            function formatPrice(input) {
                const value = parseFloat(input.value);
                if (!isNaN(value)) {
                    input.value = value.toFixed(2);
                }
            }

            // Add event listeners for price inputs
            document.getElementById('addUnitPrice').addEventListener('blur', function () {
                formatPrice(this);
            });

            document.getElementById('editUnitPrice').addEventListener('blur', function () {
                formatPrice(this);
            });

            // Discount validation
            function validateDiscount(input) {
                const value = parseFloat(input.value);
                if (value < 0) {
                    input.value = 0;
                } else if (value > 100) {
                    input.value = 100;
                }
            }

            document.getElementById('addDiscount').addEventListener('blur', function () {
                validateDiscount(this);
            });

            document.getElementById('editDiscount').addEventListener('blur', function () {
                validateDiscount(this);
            });
            function openStockModal(productCode, productName) {
                // Redirect to same page with stock view parameters
                window.location.href = 'admin.jsp?viewStock=true&stockProductCode=' + encodeURIComponent(productCode);
            }

            function closeStockModal() {
                document.getElementById('stockModal').style.display = 'none';
                // Remove stock parameters from URL
                window.location.href = 'admin.jsp';
            }

// Update the window click handler
            window.onclick = function (event) {
                const addModal = document.getElementById('addModal');
                const editModal = document.getElementById('editModal');
                const deleteModal = document.getElementById('deleteModal');
                const stockModal = document.getElementById('stockModal');

                if (event.target === addModal) {
                    closeAddModal();
                } else if (event.target === editModal) {
                    closeEditModal();
                } else if (event.target === deleteModal) {
                    closeDeleteModal();
                } else if (event.target === stockModal) {
                    closeStockModal();
                }
            }
        </script>
    </body>
</html>