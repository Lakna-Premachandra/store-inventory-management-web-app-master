<%@page import="MODELS.Product"%>
<%@page import="SERVICES.ProductService"%>
<%@page import="DAO.StoreInventoryDAO"%>
<%@page import="MODELS.StoreInventory"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="MODELS.Cart"%>
<%@page import="SERVICES.CartService"%>

<%
    // Get username from session
    String username = (String) session.getAttribute("loggedInUsername");
    if (username == null || username.trim().isEmpty()) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Initialize ProductService and CartService
    ProductService productService = new ProductService();
    CartService cartService = new CartService();
    StoreInventoryDAO storeInventoryDAO = new StoreInventoryDAO();
    List<Product> products = new ArrayList<>();
    String errorMessage = null;

    // Load products from database
    try {
        products = productService.getAllProducts();
    } catch (Exception e) {
        errorMessage = "Error loading products: " + e.getMessage();
        e.printStackTrace();
    }

    // Get inventory quantities from store_inventory using DAO
    Map<String, Integer> inventoryMap = new HashMap<>();
    try {
        List<StoreInventory> inventoryList = storeInventoryDAO.getAll();
        
        for (StoreInventory inventory : inventoryList) {
            inventoryMap.put(inventory.getProductCode(), inventory.getQuantity());
        }
    } catch (Exception e) {
        System.err.println("Error loading inventory: " + e.getMessage());
    }

    // Get cart item count from database
    int cartItemCount = 0;
    try {
        List<Cart> cartItems = cartService.getCartItems(username);
        for (Cart item : cartItems) {
            cartItemCount += item.getQuantity();
        }
    } catch (Exception e) {
        System.err.println("Error loading cart items: " + e.getMessage());
    }

    // Handle add to cart action
    String action = request.getParameter("action");
    String message = null;
    String messageType = "success";

    if ("add".equals(action)) {
        String productCode = request.getParameter("productCode");
        String quantityStr = request.getParameter("quantity");

        if (productCode != null && quantityStr != null) {
            try {
                int quantity = Integer.parseInt(quantityStr);
                
                // Check stock availability
                Integer stockQuantity = inventoryMap.get(productCode);
                int availableStock = (stockQuantity != null) ? stockQuantity : 0;
                
                if (availableStock <= 0) {
                    message = "Sorry! This product is currently out of stock.";
                    messageType = "error";
                } else if (quantity > availableStock) {
                    message = "Sorry! Only " + availableStock + " units available in stock.";
                    messageType = "error";
                } else {
                    boolean success = cartService.addToCart(username, productCode, quantity);

                    if (success) {
                        Product product = productService.getProductByCode(productCode);
                        String productName = product != null ? product.getName() : "Item";

                        response.sendRedirect("allProducts.jsp?added=" + java.net.URLEncoder.encode(productName, "UTF-8"));
                        return;
                    } else {
                        message = "Failed to add item to cart!";
                        messageType = "error";
                    }
                }
            } catch (NumberFormatException e) {
                message = "Invalid quantity format!";
                messageType = "error";
            } catch (Exception e) {
                message = "Error adding item to cart: " + e.getMessage();
                messageType = "error";
            }
        }
    }

    // Get success message if item was added
    String addedProduct = request.getParameter("added");

    // Recalculate cart count after potential update
    if (addedProduct != null) {
        try {
            List<Cart> cartItems = cartService.getCartItems(username);
            cartItemCount = 0;
            for (Cart item : cartItems) {
                cartItemCount += item.getQuantity();
            }
        } catch (Exception e) {
            System.err.println("Error recalculating cart count: " + e.getMessage());
        }
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Admin - All Products</title>
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
                text-decoration: none;
            }

            .nav-options {
                display: flex;
                gap: 1rem;
                align-items: center;
            }

            .username-display {
                color: #ecf0f1;
                font-size: 1rem;
                font-weight: 500;
                padding: 0.5rem 1rem;
                background-color: rgba(52, 152, 219, 0.2);
                border-radius: 20px;
                border: 1px solid rgba(52, 152, 219, 0.3);
            }

            .username-display::before {
                content: "👤 ";
                margin-right: 0.3rem;
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
                display: inline-flex;
                align-items: center;
                gap: 0.5rem;
                font-weight: 500;
            }

            .nav-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4);
            }

            .cart-count {
                background-color: #e74c3c;
                color: white;
                border-radius: 50%;
                padding: 0.2rem 0.5rem;
                font-size: 0.8rem;
                min-width: 20px;
                text-align: center;
                display: <%= cartItemCount > 0 ? "inline-block" : "none"%>;
            }

            .container {
                max-width: 1400px;
                margin: 2rem auto;
                padding: 0 1rem;
            }

            .success-message {
                background: linear-gradient(135deg, #c6f6d5 0%, #9ae6b4 100%);
                color: #2f855a;
                padding: 1rem 1.2rem;
                border-radius: 10px;
                margin-bottom: 2rem;
                font-weight: 500;
                border-left: 4px solid #38a169;
                text-align: center;
            }

            .error-message {
                background: linear-gradient(135deg, #fed7d7 0%, #feb2b2 100%);
                color: #c53030;
                padding: 1rem 1.2rem;
                border-radius: 10px;
                margin-bottom: 1rem;
                font-weight: 500;
                border-left: 4px solid #e53e3e;
                text-align: center;
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

            .search-section {
                margin-bottom: 2rem;
                text-align: center;
            }

            .search-input {
                width: 100%;
                max-width: 400px;
                padding: 0.8rem 1rem;
                border: 2px solid #e2e8f0;
                border-radius: 25px;
                font-size: 1rem;
                outline: none;
                transition: all 0.3s ease;
            }

            .search-input:focus {
                border-color: #3498db;
                box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
            }

            .products-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 2rem;
            }

            .product-card {
                background: white;
                border-radius: 15px;
                padding: 1.5rem;
                text-align: center;
                transition: transform 0.3s, box-shadow 0.3s;
                position: relative;
                box-shadow: 0 5px 15px rgba(0,0,0,0.08);
                border: 1px solid rgba(0,0,0,0.05);
            }

            .product-card:hover {
                transform: translateY(-8px);
                box-shadow: 0 15px 35px rgba(0,0,0,0.15);
            }

            .product-card.out-of-stock {
                opacity: 0.6;
                background-color: #f8f9fa;
            }

            .product-card.out-of-stock:hover {
                transform: translateY(-4px);
            }

            .product-image {
                width: 100%;
                height: 200px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                display: flex;
                align-items: center;
                justify-content: center;
                margin-bottom: 1rem;
                font-size: 3rem;
            }

            .product-card.out-of-stock .product-image {
                background: linear-gradient(135deg, #95a5a6 0%, #7f8c8d 100%);
            }

            .product-code {
                position: absolute;
                top: 15px;
                right: 15px;
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
                padding: 0.3rem 0.7rem;
                border-radius: 8px;
                font-size: 0.8rem;
                font-weight: bold;
                box-shadow: 0 2px 8px rgba(52, 152, 219, 0.3);
            }

            .discount-badge {
                position: absolute;
                top: 15px;
                left: 15px;
                background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
                color: white;
                padding: 0.4rem 0.8rem;
                border-radius: 20px;
                font-size: 0.85rem;
                font-weight: bold;
                box-shadow: 0 2px 8px rgba(231, 76, 60, 0.3);
            }

            .out-of-stock-badge {
                position: absolute;
                top: 15px;
                left: 15px;
                background: linear-gradient(135deg, #6c757d 0%, #5a6268 100%);
                color: white;
                padding: 0.4rem 0.8rem;
                border-radius: 20px;
                font-size: 0.85rem;
                font-weight: bold;
                box-shadow: 0 2px 8px rgba(108, 117, 125, 0.3);
            }

            .product-name {
                font-size: 1.3rem;
                font-weight: bold;
                margin-bottom: 0.8rem;
                color: #2c3e50;
                min-height: 2.6rem;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .product-price {
                font-size: 1.4rem;
                font-weight: bold;
                color: #e74c3c;
                margin-bottom: 1.2rem;
            }

            .original-price {
                text-decoration: line-through;
                color: #7f8c8d;
                font-size: 1.1rem;
                margin-right: 0.5rem;
            }

            .discounted-price {
                color: #27ae60;
                font-weight: bold;
            }

            .add-to-cart-btn {
                background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
                color: white;
                border: none;
                padding: 0.9rem 1.8rem;
                border-radius: 10px;
                cursor: pointer;
                font-size: 1rem;
                font-weight: 600;
                transition: all 0.3s ease;
                width: 100%;
            }

            .add-to-cart-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(39, 174, 96, 0.3);
            }

            .add-to-cart-btn:active {
                transform: scale(0.98);
            }

            .add-to-cart-btn:disabled {
                background: linear-gradient(135deg, #95a5a6 0%, #7f8c8d 100%);
                cursor: not-allowed;
                transform: none;
            }

            .add-to-cart-btn:disabled:hover {
                box-shadow: none;
            }

            .no-products {
                text-align: center;
                color: #7f8c8d;
                font-size: 1.2rem;
                padding: 3rem;
                background-color: #f8f9fa;
                border-radius: 10px;
                border: 2px dashed #dee2e6;
            }

            .loading {
                opacity: 0.6;
                pointer-events: none;
            }

            @media (max-width: 768px) {
                .container {
                    padding: 0 0.5rem;
                }

                .admin-section {
                    padding: 1.5rem;
                }

                .products-grid {
                    grid-template-columns: 1fr;
                }

                .header {
                    flex-direction: column;
                    gap: 1rem;
                }

                .nav-options {
                    width: 100%;
                    justify-content: center;
                    flex-wrap: wrap;
                }
            }
        </style>
    </head>
    <body>
        <!-- Header Section -->
        <div class="header">
            <a href="allProducts.jsp" class="logo">Syops Admin</a>
            <div class="nav-options">
                <% if (username != null && !username.trim().isEmpty()) {%>
                <span class="username-display"><%= username%></span>
                <% }%>

                <a href="cart.jsp" class="nav-btn">
                    🛒 Cart 
                    <span class="cart-count" id="cartCount"><%= cartItemCount%></span>
                </a>
                <a href="admin.jsp" class="nav-btn">Dashboard</a>


                <a href="allProducts.jsp" class="nav-btn">All products</a>

                <a href="adminBillDetails.jsp" class="nav-btn">Bill Details</a>
                <a href="reports.jsp" class="nav-btn">Reports</a>

                <a href="login.jsp" class="nav-btn">Logout</a>
            </div>
        </div>

        <!-- Main Content -->
        <div class="container">
            <!-- Success Message -->
            <% if (addedProduct != null) {%>
            <div class="success-message">
                ✅ "<%= addedProduct%>" has been added to your cart successfully!
            </div>
            <% } %>

            <!-- Error Message -->
            <% if (message != null && "error".equals(messageType)) {%>
            <div class="error-message">
                <%= message%>
            </div>
            <% } %>

            <div class="admin-section">
                <h2 class="section-title">All Products</h2>

                <!-- Search Section -->
                <% if (!products.isEmpty()) { %>
                <div class="search-section">
                    <input type="text" class="search-input" id="searchInput" 
                           placeholder="🔍 Search products by name or code..." onkeyup="searchProducts()">
                </div>
                <% } %>

                <!-- Error Message for product loading -->
                <% if (errorMessage != null) {%>
                <div class="error-message">
                    <%= errorMessage%>
                </div>
                <% } %>

                <!-- Products Grid -->
                <% if (products.isEmpty()) { %>
                <div class="no-products">
                    <% if (errorMessage != null) { %>
                    Unable to load products. Please try again later.
                    <% } else { %>
                    No products available at the moment.
                    <% } %>
                </div>
                <% } else { %>
                <div class="products-grid" id="productsGrid">
                    <% for (Product product : products) {
                            double originalPrice = product.getUnitPrice() != null ? product.getUnitPrice().doubleValue() : 0;
                            double discountPercent = product.getDiscount() != null ? product.getDiscount().doubleValue() : 0;
                            double discountedPrice = originalPrice * (1 - discountPercent / 100);
                            boolean hasDiscount = discountPercent > 0;
                            
                            // Check if product is out of stock from inventory map
                            String productCode = product.getProductCode();
                            Integer stockQuantity = inventoryMap.get(productCode);
                            int stock = (stockQuantity != null) ? stockQuantity : 0;
                            boolean isOutOfStock = stock <= 0;
                    %>
                    <div class="product-card <%= isOutOfStock ? "out-of-stock" : ""%>" 
                         data-name="<%= product.getName() != null ? product.getName().toLowerCase() : ""%>" 
                         data-code="<%= product.getProductCode() != null ? product.getProductCode().toLowerCase() : ""%>">

                        <!-- Product Code Badge -->
                        <div class="product-code"><%= product.getProductCode() != null ? product.getProductCode() : "N/A"%></div>

                        <!-- Out of Stock Badge or Discount Badge -->
                        <% if (isOutOfStock) {%>
                        <div class="out-of-stock-badge">OUT OF STOCK</div>
                        <% } else if (hasDiscount) {%>
                        <div class="discount-badge"><%= String.format("%.0f%% OFF", discountPercent)%></div>
                        <% }%>

                        <!-- Product Image -->
                        <div class="product-image">📦</div>

                        <!-- Product Name -->
                        <div class="product-name"><%= product.getName() != null ? product.getName() : "Unnamed Product"%></div>

                        <!-- Product Price -->
                        <div class="product-price">
                            <% if (hasDiscount) {%>
                            <span class="original-price">Rs<%= String.format("%.2f", originalPrice)%></span>
                            <span class="discounted-price">Rs<%= String.format("%.2f", discountedPrice)%></span>
                            <% } else {%>
                            Rs<%= String.format("%.2f", originalPrice)%>
                            <% }%>
                        </div>

                        <!-- Add to Cart Form -->
                        <form method="POST" action="allProducts.jsp" onsubmit="addToCartLoading(this)">
                            <input type="hidden" name="action" value="add">
                            <input type="hidden" name="productCode" value="<%= product.getProductCode() != null ? product.getProductCode() : ""%>">
                            <input type="hidden" name="quantity" value="1">
                            <button type="submit" class="add-to-cart-btn" <%= isOutOfStock ? "disabled" : ""%>>
                                <%= isOutOfStock ? "Out of Stock" : "Add to Cart"%>
                            </button>
                        </form>
                    </div>
                    <% } %>
                </div>
                <% }%>
            </div>
        </div>

        <script>
            function addToCartLoading(form) {
                const button = form.querySelector('.add-to-cart-btn');
                
                // Don't proceed if button is disabled
                if (button.disabled) {
                    return false;
                }
                
                const originalText = button.textContent;
                button.textContent = 'Adding...';
                button.disabled = true;

                const card = form.closest('.product-card');
                card.classList.add('loading');

                return true;
            }

            function searchProducts() {
                const searchTerm = document.getElementById('searchInput').value.toLowerCase();
                const productCards = document.querySelectorAll('.product-card');
                let visibleCount = 0;

                productCards.forEach(card => {
                    const productName = card.getAttribute('data-name') || '';
                    const productCode = card.getAttribute('data-code') || '';

                    if (productName.includes(searchTerm) || productCode.includes(searchTerm)) {
                        card.style.display = 'block';
                        visibleCount++;
                    } else {
                        card.style.display = 'none';
                    }
                });

                const grid = document.getElementById('productsGrid');
                let noResultsMsg = document.getElementById('noSearchResults');

                if (visibleCount === 0 && searchTerm !== '') {
                    if (!noResultsMsg) {
                        noResultsMsg = document.createElement('div');
                        noResultsMsg.id = 'noSearchResults';
                        noResultsMsg.className = 'no-products';
                        noResultsMsg.innerHTML = 'No products found matching "' + searchTerm + '"';
                        grid.appendChild(noResultsMsg);
                    }
                } else if (noResultsMsg) {
                    noResultsMsg.remove();
                }
            }

            document.addEventListener('DOMContentLoaded', function () {
                const successMessages = document.querySelectorAll('.success-message');
                successMessages.forEach(function (message) {
                    setTimeout(function () {
                        message.style.opacity = '0';
                        setTimeout(function () {
                            message.style.display = 'none';
                        }, 300);
                    }, 5000);
                });

                const urlParams = new URLSearchParams(window.location.search);
                if (urlParams.has('added')) {
                    const url = new URL(window.location);
                    url.searchParams.delete('added');
                    window.history.replaceState({}, '', url);
                }
            });
        </script>
    </body>
</html>