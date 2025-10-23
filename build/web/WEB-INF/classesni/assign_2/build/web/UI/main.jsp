<%@page import="MODELS.Product"%>
<%@page import="SERVICES.ProductService"%>
<%@page import="SERVICES.ProductService.ProductWithStock"%>
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
    String role = (String) session.getAttribute("role");

    if (username == null || username.trim().isEmpty()) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Initialize ProductService and CartService
    ProductService productService = new ProductService();
    CartService cartService = new CartService();
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
        StoreInventoryDAO storeInventoryDAO = new StoreInventoryDAO();
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
                boolean success = cartService.addToCart(username, productCode, quantity);

                if (success) {
                    // Get product name for message
                    Product product = productService.getProductByCode(productCode);
                    String productName = product != null ? product.getName() : "Item";

                    // Redirect with success message
                    response.sendRedirect("main.jsp?added=" + java.net.URLEncoder.encode(productName, "UTF-8"));
                    return;
                } else {
                    message = "Failed to add item to cart!";
                    messageType = "error";
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
        <title>Syops - Retail Shop</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: Arial, sans-serif;
                background-color: #f5f5f5;
            }

            .header {
                background-color: #2c3e50;
                color: white;
                padding: 1rem 2rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            }

            .logo {
                font-size: 2rem;
                font-weight: bold;
                color: #3498db;
                text-decoration: none;
            }

            .logo:hover {
                color: #2980b9;
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

            .cart-btn, .logout-btn {
                background-color: #3498db;
                color: white;
                border: none;
                padding: 0.5rem 1rem;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1rem;
                transition: background-color 0.3s;
                text-decoration: none;
                display: inline-flex;
                align-items: center;
                gap: 0.5rem;
            }

            .cart-btn:hover, .logout-btn:hover {
                background-color: #2980b9;
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
                max-width: 1200px;
                margin: 2rem auto;
                padding: 0 1rem;
            }

            .success-message {
                background-color: #d4edda;
                color: #155724;
                padding: 1rem;
                border-radius: 5px;
                margin-bottom: 2rem;
                text-align: center;
                border: 1px solid #c3e6cb;
            }

            .error-message {
                background-color: #f8d7da;
                color: #721c24;
                padding: 1rem;
                border-radius: 5px;
                margin-bottom: 2rem;
                text-align: center;
                border: 1px solid #f5c6cb;
            }

            .products-section {
                background-color: white;
                padding: 2rem;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }

            .section-title {
                text-align: center;
                margin-bottom: 2rem;
                color: #2c3e50;
                font-size: 1.8rem;
            }

            .products-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 2rem;
            }

            .product-card {
                border: 1px solid #ddd;
                border-radius: 10px;
                padding: 1rem;
                text-align: center;
                transition: transform 0.3s, box-shadow 0.3s;
                position: relative;
            }

            .product-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 5px 20px rgba(0,0,0,0.1);
            }

            .product-card.out-of-stock {
                opacity: 0.6;
                background-color: #f8f9fa;
            }

            .product-card.out-of-stock:hover {
                transform: none;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }

            .product-image {
                width: 100%;
                height: 200px;
                background-color: #ecf0f1;
                border-radius: 5px;
                display: flex;
                align-items: center;
                justify-content: center;
                margin-bottom: 1rem;
                color: #7f8c8d;
                font-size: 3rem;
            }

            .product-card.out-of-stock .product-image {
                background-color: #dee2e6;
            }

            .product-code {
                position: absolute;
                top: 10px;
                right: 10px;
                background-color: #3498db;
                color: white;
                padding: 0.2rem 0.5rem;
                border-radius: 5px;
                font-size: 0.8rem;
                font-weight: bold;
            }

            .product-name {
                font-size: 1.2rem;
                font-weight: bold;
                margin-bottom: 0.5rem;
                color: #2c3e50;
                min-height: 2.4rem;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .product-price {
                font-size: 1.3rem;
                font-weight: bold;
                color: #e74c3c;
                margin-bottom: 1rem;
            }

            .original-price {
                text-decoration: line-through;
                color: #7f8c8d;
                font-size: 1rem;
                margin-right: 0.5rem;
            }

            .discounted-price {
                color: #27ae60;
                font-weight: bold;
            }

            .discount-badge {
                position: absolute;
                top: 10px;
                left: 10px;
                background-color: #e74c3c;
                color: white;
                padding: 0.3rem 0.6rem;
                border-radius: 15px;
                font-size: 0.8rem;
                font-weight: bold;
            }

            .out-of-stock-badge {
                position: absolute;
                top: 10px;
                left: 10px;
                background-color: #6c757d;
                color: white;
                padding: 0.3rem 0.6rem;
                border-radius: 15px;
                font-size: 0.8rem;
                font-weight: bold;
            }

            .add-to-cart-btn {
                background-color: #27ae60;
                color: white;
                border: none;
                padding: 0.8rem 1.5rem;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1rem;
                transition: background-color 0.3s;
                width: 100%;
            }

            .add-to-cart-btn:hover {
                background-color: #219a52;
            }

            .add-to-cart-btn:active {
                transform: scale(0.98);
            }

            .add-to-cart-btn:disabled {
                background-color: #95a5a6;
                cursor: not-allowed;
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
                transition: border-color 0.3s;
            }

            .search-input:focus {
                border-color: #3498db;
            }

            .loading {
                opacity: 0.6;
                pointer-events: none;
            }

            @media (max-width: 768px) {
                .container {
                    padding: 0 0.5rem;
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
                }
            }
        </style>
    </head>
    <body>
        <!-- Header Section -->
        <header class="header">
            <a href="main.jsp" class="logo">Syops</a>
            <div class="nav-options">
                <!-- Display username if logged in -->
                <% if (username != null && !username.trim().isEmpty()) {%>
                <span class="username-display"><%= username%></span>
                <% } %>
    
                <!--<span class="username-display"><%= role%></span>-->

                <a href="cart.jsp" class="cart-btn">
                    🛒 Cart 
                    <span class="cart-count" id="cartCount"><%= cartItemCount%></span>
                </a>
                <a class="logout-btn" href="login.jsp">Logout</a>
            </div>
        </header>

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

            <div class="products-section">
                <h2 class="section-title">Featured Products</h2>

                <!-- Search Section -->
                <% if (!products.isEmpty()) { %>
                <div class="search-section">
                    <input type="text" class="search-input" id="searchInput" 
                           placeholder="Search products..." onkeyup="searchProducts()">
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
                            // Calculate discounted price if discount exists
                            double originalPrice = product.getUnitPrice() != null ? product.getUnitPrice().doubleValue() : 0;
                            double discountPercent = product.getDiscount() != null ? product.getDiscount().doubleValue() : 0;
                            double discountedPrice = originalPrice * (1 - discountPercent / 100);
                            boolean hasDiscount = discountPercent > 0;
                            double finalPrice = hasDiscount ? discountedPrice : originalPrice;
                            
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

                        <!-- Product Image Placeholder -->
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
                        <form method="POST" action="main.jsp" onsubmit="addToCartLoading(this)">
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
                // Show loading state
                const button = form.querySelector('.add-to-cart-btn');
                
                // Don't proceed if button is disabled
                if (button.disabled) {
                    return false;
                }
                
                const originalText = button.textContent;
                button.textContent = 'Adding...';
                button.disabled = true;

                // Add loading class to the card
                const card = form.closest('.product-card');
                card.classList.add('loading');

                // Allow form submission to continue
                return true;
            }

            // Search functionality
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

                // Show no results message
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

            // Auto-hide success messages after 5 seconds
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

                // Clean up URL parameters
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