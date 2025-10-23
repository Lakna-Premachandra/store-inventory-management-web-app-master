<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="MODELS.Cart"%>
<%@page import="SERVICES.CartService"%>
<%@page import="MODELS.Product"%>
<%@page import="SERVICES.ProductService"%>
<%@page import="DAO.StoreInventoryDAO"%>
<%@page import="MODELS.StoreInventory"%>

<%
    // Get username from session
    String username = (String) session.getAttribute("loggedInUsername");
    String role = (String) session.getAttribute("role");

    if (username == null || username.trim().isEmpty()) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Initialize services
    CartService cartService = new CartService();
    ProductService productService = new ProductService();
    StoreInventoryDAO storeInventoryDAO = new StoreInventoryDAO();

    // Get cart items from database via CartService
    List<Cart> cartItems = new ArrayList<>();
    String message = null;
    String messageType = "success"; // success, error, info

    // Handle cart operations
    String action = request.getParameter("action");
    String productCode = request.getParameter("productCode");
    String productName = request.getParameter("productName");
    String priceStr = request.getParameter("price");
    String quantityStr = request.getParameter("quantity");
    String redirectPage = request.getParameter("redirect");

    try {
        if (action != null) {
            switch (action) {
                case "add":
                    if (productCode != null && quantityStr != null) {
                        int quantity = Integer.parseInt(quantityStr);
                        
                        // Check stock availability
                        StoreInventory inventory = storeInventoryDAO.getByCode(productCode);
                        int availableStock = (inventory != null) ? inventory.getQuantity() : 0;
                        
                        if (availableStock <= 0) {
                            message = "Sorry! This product is currently out of stock.";
                            messageType = "error";
                        } else if (quantity > availableStock) {
                            message = "Sorry! Only " + availableStock + " units available in stock. You tried to add " + quantity + " units.";
                            messageType = "error";
                        } else {
                            boolean success = cartService.addToCart(username, productCode, quantity);
                            if (success) {
                                message = "Item added to cart successfully!";
                            } else {
                                message = "Failed to add item to cart!";
                                messageType = "error";
                            }
                        }

                        // Redirect back to main page if requested
                        if ("main".equals(redirectPage)) {
                            String redirectUrl = "main.jsp";
                            if (message != null) {
                                redirectUrl += "?message=" + java.net.URLEncoder.encode(message, "UTF-8") + 
                                             "&messageType=" + messageType;
                            }
                            response.sendRedirect(redirectUrl);
                            return;
                        }
                    }
                    break;

                case "update":
                    if (productCode != null && quantityStr != null) {
                        int newQuantity = Integer.parseInt(quantityStr);
                        
                        // Check stock availability for update
                        StoreInventory inventory = storeInventoryDAO.getByCode(productCode);
                        int availableStock = (inventory != null) ? inventory.getQuantity() : 0;
                        
                        if (newQuantity > availableStock) {
                            message = "Cannot update! Only " + availableStock + " units available in stock.";
                            messageType = "error";
                        } else {
                            boolean success = cartService.updateCartItem(username, productCode, newQuantity);
                            if (success) {
                                if (newQuantity == 0) {
                                    message = "Item removed from cart!";
                                } else {
                                    message = "Quantity updated successfully!";
                                }
                            } else {
                                message = "Failed to update cart item!";
                                messageType = "error";
                            }
                        }
                    }
                    break;

                case "remove":
                    if (productCode != null) {
                        boolean success = cartService.removeFromCart(username, productCode);
                        if (success) {
                            message = "Item removed from cart successfully!";
                        } else {
                            message = "Failed to remove item from cart!";
                            messageType = "error";
                        }
                    }
                    break;

                case "clear":
                    // Check for checkout success
                    String checkoutSuccess = request.getParameter("checkoutSuccess");
                    if ("true".equals(checkoutSuccess)) {
                        String orderNumber = request.getParameter("orderNumber");
                        message = "Order placed successfully! Order Number: #" + (orderNumber != null ? orderNumber : "N/A") + ". Your cart has been cleared.";
                        messageType = "success";
                    } else {
                        // Manual clear cart action
                        boolean success = cartService.clearCart(username);
                        if (success) {
                            message = "Cart cleared successfully!";
                            messageType = "success";
                        } else {
                            message = "Failed to clear cart!";
                            messageType = "error";
                        }
                    }
                    break;
            }

            // Redirect to avoid resubmission on page refresh
            if (action != null && !action.equals("add")) {
                String redirectUrl = "cart.jsp";
                if (message != null) {
                    redirectUrl += "?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&messageType=" + messageType;
                }
                response.sendRedirect(redirectUrl);
                return;
            }
        }

        // Load cart items from database
        cartItems = cartService.getCartItems(username);

        // Get message from URL parameters if redirected
        if (message == null) {
            message = request.getParameter("message");
            messageType = request.getParameter("messageType");
            if (messageType == null) {
                messageType = "info";
            }
        }

    } catch (NumberFormatException e) {
        message = "Invalid number format!";
        messageType = "error";
        cartItems = cartService.getCartItems(username);
    } catch (Exception e) {
        message = "An error occurred: " + e.getMessage();
        messageType = "error";
        cartItems = cartService.getCartItems(username);
    }

    // Calculate totals - CORRECTED VERSION
    double subtotal = 0;
    int totalItems = 0;
    Map<String, Product> productDetails = new HashMap<>();
    Map<String, Integer> stockLevels = new HashMap<>();

    // Get product details and stock levels for each cart item
    for (Cart cartItem : cartItems) {
        try {
            Product product = productService.getProductByCode(cartItem.getProductCode());
            if (product != null) {
                productDetails.put(cartItem.getProductCode(), product);
                
                // Get stock level
                StoreInventory inventory = storeInventoryDAO.getByCode(cartItem.getProductCode());
                int stock = (inventory != null) ? inventory.getQuantity() : 0;
                stockLevels.put(cartItem.getProductCode(), stock);
                
                // Use totalAmount from Cart object which already includes discount calculation
                double itemTotalAmount = cartItem.getTotalAmount() != null ? 
                    cartItem.getTotalAmount().doubleValue() : 0;
                
                subtotal += itemTotalAmount; // Add the discounted total amount
                totalItems += cartItem.getQuantity();
            }
        } catch (Exception e) {
            // Handle error getting product details
            System.err.println("Error getting product details for code: " + cartItem.getProductCode());
        }
    }

    double shipping = subtotal > 50 ? 0 : 10; // Free shipping over $50
    double total = subtotal + shipping;

    DecimalFormat df = new DecimalFormat("#0.00");
    
    // Store cart data in session for checkout
    List<Map<String, Object>> sessionCart = new ArrayList<>();
    for (Cart cartItem : cartItems) {
        String itemCode = cartItem.getProductCode();
        Product product = productDetails.get(itemCode);
        if (product != null) {
            Map<String, Object> item = new HashMap<>();
            item.put("code", itemCode);
            item.put("name", product.getName());
            item.put("price", product.getUnitPrice().doubleValue());
            item.put("quantity", cartItem.getQuantity());
            item.put("discount", cartItem.getDiscount() != null ? 
                cartItem.getDiscount().doubleValue() : 0.0);
            item.put("totalAmount", cartItem.getTotalAmount() != null ? 
                cartItem.getTotalAmount().doubleValue() : 0.0);
            sessionCart.add(item);
        }
    }

    session.setAttribute("cart", sessionCart);
    session.setAttribute("cartTotal", total);
    session.setAttribute("cartSubtotal", subtotal);
    session.setAttribute("cartShipping", shipping);
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Shopping Cart - Syops</title>
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

            .nav-btn {
                background-color: #3498db;
                color: white;
                border: none;
                padding: 0.5rem 1rem;
                border-radius: 5px;
                cursor: pointer;
                text-decoration: none;
                display: inline-block;
                transition: background-color 0.3s;
            }

            .nav-btn:hover {
                background-color: #2980b9;
            }

            .container {
                max-width: 1200px;
                margin: 2rem auto;
                padding: 0 1rem;
            }

            .message {
                padding: 1rem;
                border-radius: 5px;
                margin-bottom: 2rem;
                text-align: center;
                font-weight: bold;
            }

            .message.success {
                background-color: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
            }

            .message.error {
                background-color: #f8d7da;
                color: #721c24;
                border: 1px solid #f5c6cb;
            }

            .message.info {
                background-color: #d1ecf1;
                color: #0c5460;
                border: 1px solid #bee5eb;
            }

            .cart-section {
                background-color: white;
                padding: 2rem;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                margin-bottom: 2rem;
            }

            .cart-title {
                font-size: 2rem;
                margin-bottom: 2rem;
                color: #2c3e50;
                border-bottom: 2px solid #3498db;
                padding-bottom: 0.5rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .cart-stats {
                font-size: 1rem;
                color: #7f8c8d;
                font-weight: normal;
            }

            .empty-cart {
                text-align: center;
                padding: 3rem;
                color: #7f8c8d;
            }

            .empty-cart-icon {
                font-size: 4rem;
                margin-bottom: 1rem;
            }

            .cart-table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 2rem;
            }

            .cart-table th,
            .cart-table td {
                padding: 1rem;
                text-align: left;
                border-bottom: 1px solid #ddd;
                vertical-align: middle;
            }

            .cart-table th {
                background-color: #f8f9fa;
                font-weight: bold;
                color: #2c3e50;
                text-align: center;
            }

            .cart-table td {
                text-align: center;
            }

            .product-info {
                display: flex;
                align-items: center;
                gap: 1rem;
                text-align: left;
            }

            .product-image {
                width: 60px;
                height: 60px;
                background-color: #ecf0f1;
                border-radius: 5px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 1.5rem;
                flex-shrink: 0;
            }

            .product-details {
                flex-grow: 1;
            }

            .product-name {
                font-weight: bold;
                margin-bottom: 0.25rem;
                color: #2c3e50;
            }

            .product-code {
                font-size: 0.8rem;
                color: #7f8c8d;
                background-color: #ecf0f1;
                padding: 0.2rem 0.5rem;
                border-radius: 3px;
                display: inline-block;
            }

            .stock-info {
                font-size: 0.75rem;
                margin-top: 0.25rem;
                padding: 0.2rem 0.5rem;
                border-radius: 3px;
                display: inline-block;
            }

            .stock-low {
                background-color: #fff3cd;
                color: #856404;
                border: 1px solid #ffeaa7;
            }

            .stock-out {
                background-color: #f8d7da;
                color: #721c24;
                border: 1px solid #f5c6cb;
            }

            .stock-ok {
                background-color: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
            }

            .quantity-controls {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                justify-content: center;
            }

            .qty-btn {
                background-color: #3498db;
                color: white;
                border: none;
                width: 30px;
                height: 30px;
                border-radius: 3px;
                cursor: pointer;
                font-size: 1.2rem;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: background-color 0.3s;
            }

            .qty-btn:hover {
                background-color: #2980b9;
            }

            .qty-btn:disabled {
                background-color: #bdc3c7;
                cursor: not-allowed;
            }

            .qty-input {
                width: 60px;
                text-align: center;
                border: 1px solid #ddd;
                padding: 0.3rem;
                border-radius: 3px;
            }

            .remove-btn {
                background-color: #e74c3c;
                color: white;
                border: none;
                padding: 0.5rem 1rem;
                border-radius: 5px;
                cursor: pointer;
                transition: background-color 0.3s;
                font-size: 0.9rem;
                text-decoration: none;
                display: inline-block;
            }

            .remove-btn:hover {
                background-color: #c0392b;
            }

            .price-cell {
                font-weight: bold;
                color: #2c3e50;
            }

            .total-cell {
                font-weight: bold;
                color: #e74c3c;
                font-size: 1.1rem;
            }

            .cart-summary {
                background-color: #f8f9fa;
                padding: 1.5rem;
                border-radius: 10px;
                border: 1px solid #ddd;
                max-width: 400px;
                margin-left: auto;
            }

            .summary-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 0.5rem;
                padding: 0.25rem 0;
            }

            .summary-total {
                border-top: 2px solid #3498db;
                padding-top: 1rem;
                margin-top: 1rem;
                font-weight: bold;
                font-size: 1.2rem;
                color: #2c3e50;
            }

            .cart-actions {
                display: flex;
                gap: 1rem;
                justify-content: space-between;
                margin-top: 2rem;
                flex-wrap: wrap;
            }

            .action-btn {
                padding: 1rem 2rem;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1rem;
                transition: all 0.3s;
                text-decoration: none;
                display: inline-block;
                text-align: center;
                font-weight: bold;
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

            .continue-shopping {
                background-color: #95a5a6;
                color: white;
            }

            .continue-shopping:hover {
                background-color: #7f8c8d;
            }

            .clear-cart {
                background-color: #e67e22;
                color: white;
            }

            .clear-cart:hover {
                background-color: #d35400;
            }

            .checkout {
                background-color: #27ae60;
                color: white;
                flex-grow: 1;
                min-width: 200px;
            }

            .checkout:hover {
                background-color: #219a52;
            }

            .checkout:disabled {
                background-color: #bdc3c7;
                cursor: not-allowed;
            }

            .loading {
                opacity: 0.6;
                pointer-events: none;
            }

            @media (max-width: 768px) {
                .cart-table {
                    font-size: 0.9rem;
                }

                .cart-table th,
                .cart-table td {
                    padding: 0.5rem;
                }

                .product-info {
                    flex-direction: column;
                    text-align: center;
                }

                .cart-actions {
                    flex-direction: column;
                }

                .action-btn {
                    width: 100%;
                }

                .cart-summary {
                    max-width: 100%;
                    margin: 0;
                }

                .cart-title {
                    flex-direction: column;
                    gap: 0.5rem;
                    text-align: center;
                }
            }
        </style>
    </head>
    <body>
        <!-- Header Section -->
        <header class="header">
            <a href="<%= "ADMIN".equalsIgnoreCase(role) ? "admin.jsp" : "main.jsp"%>" class="logo">
                <%= "ADMIN".equalsIgnoreCase(role) ? "Syops Admin" : "Syops"%>
            </a>

            <div class="nav-options">
                <% if (username != null && !username.trim().isEmpty()) {%>
                <span class="username-display"><%= username%></span>
                <% }%>
                <a href="<%= "ADMIN".equalsIgnoreCase(role) ? "allProducts.jsp" : "main.jsp"%>" class="nav-btn">Continue Shopping</a>
                <span style="color: #ecf0f1;">Cart (<%= totalItems%>)</span>
                <a href="login.jsp" class="nav-btn">Logout</a>
            </div>
        </header>

        <!-- Cart Content -->
        <div class="container">
            <!-- Message Display -->
            <% if (message != null && !message.trim().isEmpty()) {%>
            <div class="message <%= messageType%>">
                <%= message%>
            </div>
            <% }%>

            <div class="cart-section">
                <h1 class="cart-title">
                    Shopping Cart 
                    <span class="cart-stats">
                        <%= totalItems%> items • Rs<%= df.format(total)%>
                    </span>
                </h1>

                <% if (cartItems.isEmpty()) {%>
                <div class="empty-cart">
                    <div class="empty-cart-icon">🛒</div>
                    <h3>Your cart is empty</h3>
                    <p>Looks like you haven't added any items to your cart yet.</p>
                    <br>
                    <a href="<%= "ADMIN".equalsIgnoreCase(role) ? "allProducts.jsp" : "main.jsp"%>" class="nav-btn">Continue Shopping</a>
                </div>
                <% } else { %>
                <table class="cart-table">
                    <thead>
                        <tr>
                            <th style="text-align: left;">Product</th>
                            <th>Price</th>
                            <th>Quantity</th>
                            <th>Discount</th>
                            <th>Total</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Cart cartItem : cartItems) {
                                String itemCode = cartItem.getProductCode();
                                Product product = productDetails.get(itemCode);
                                String itemName = product != null ? product.getName() : "Unknown Product";
                                double discount = cartItem.getDiscount() != null ? cartItem.getDiscount().doubleValue() : 0.0;
                                double itemPrice = product != null && product.getUnitPrice() != null
                                        ? product.getUnitPrice().doubleValue() : 0;
                                int itemQuantity = cartItem.getQuantity();
                                double totalAmount = cartItem.getTotalAmount()!= null ? cartItem.getTotalAmount().doubleValue() : 0.0;
                                
                                // Get stock level
                                Integer stockLevel = stockLevels.get(itemCode);
                                int availableStock = (stockLevel != null) ? stockLevel : 0;
                                boolean canIncrement = (itemQuantity < availableStock);

                                // Get product emoji based on name
                                String productEmoji = "📦";
                                if (itemName.toLowerCase().contains("phone") || itemName.toLowerCase().contains("mobile")) {
                                    productEmoji = "📱";
                                } else if (itemName.toLowerCase().contains("laptop") || itemName.toLowerCase().contains("computer")) {
                                    productEmoji = "💻";
                                } else if (itemName.toLowerCase().contains("headphone") || itemName.toLowerCase().contains("earphone")) {
                                    productEmoji = "🎧";
                                } else if (itemName.toLowerCase().contains("watch")) {
                                    productEmoji = "⌚";
                                } else if (itemName.toLowerCase().contains("camera")) {
                                    productEmoji = "📷";
                                }
                        %>
                        <tr>
                            <td>
                                <div class="product-info">
                                    <div class="product-image"><%= productEmoji%></div>
                                    <div class="product-details">
                                        <div class="product-name"><%= itemName%></div>
                                        <div class="product-code">Code: <%= itemCode%></div>
                                        <% if (availableStock <= 0) { %>
                                        <div class="stock-info stock-out">Out of Stock!</div>
                                        <% } else if (availableStock <= 5) { %>
                                        <div class="stock-info stock-low">Only <%= availableStock%> left</div>
                                        <% } else { %>
                                        <div class="stock-info stock-ok"><%= availableStock%> in stock</div>
                                        <% } %>
                                    </div>
                                </div>
                            </td>
                            <td class="price-cell">Rs<%= df.format(itemPrice)%></td>

                            <td>
                                <div class="quantity-controls">
                                    <!-- Decrease quantity form -->
                                    <% if (itemQuantity > 1) {%>
                                    <form method="POST" action="cart.jsp" style="display: inline;">
                                        <input type="hidden" name="action" value="update">
                                        <input type="hidden" name="productCode" value="<%= itemCode%>">
                                        <input type="hidden" name="quantity" value="<%= itemQuantity - 1%>">
                                        <button type="submit" class="qty-btn">-</button>
                                    </form>
                                    <% } else { %>
                                    <button class="qty-btn" disabled>-</button>
                                    <% }%>

                                    <!-- Quantity display -->
                                    <span style="padding: 0.3rem 0.8rem; border: 1px solid #ddd; border-radius: 3px; min-width: 60px; display: inline-block; text-align: center;"><%= itemQuantity%></span>

                                    <!-- Increase quantity form -->
                                    <% if (canIncrement) { %>
                                    <form method="POST" action="cart.jsp" style="display: inline;">
                                        <input type="hidden" name="action" value="update">
                                        <input type="hidden" name="productCode" value="<%= itemCode%>">
                                        <input type="hidden" name="quantity" value="<%= itemQuantity + 1%>">
                                        <button type="submit" class="qty-btn">+</button>
                                    </form>
                                    <% } else { %>
                                    <button class="qty-btn" disabled title="Maximum stock reached">+</button>
                                    <% } %>
                                </div>
                            </td>
                            <td>Rs<%=df.format(discount)%></td>

                            <td class="total-cell">Rs<%= df.format(totalAmount)%></td>
                            <td>
                                <!-- Remove item form -->
                                <form method="POST" action="cart.jsp" style="display: inline;" 
                                      onsubmit="return confirm('Are you sure you want to remove this item from your cart?')">
                                    <input type="hidden" name="action" value="remove">
                                    <input type="hidden" name="productCode" value="<%= itemCode%>">
                                    <button type="submit" class="remove-btn">Remove</button>
                                </form>
                            </td>
                        </tr>
                        <% }%>
                    </tbody>
                </table>

                <div class="cart-summary">
                    <div class="summary-row">
                        <span>Subtotal (<%= totalItems%> items):</span>
                        <span>Rs<%= df.format(subtotal)%></span>
                    </div>

                    <div class="summary-row">
                        <span>Shipping:</span>
                        <span><%= shipping == 0 ? "FREE" : "Rs" + df.format(shipping)%></span>
                    </div>
                    <% if (subtotal < 50 && shipping > 0) {%>
                    <div class="summary-row" style="color: #e67e22; font-size: 0.9rem;">
                        <span>Add Rs<%= df.format(50 - subtotal)%> for FREE shipping</span>
                    </div>
                    <% }%>
                    <div class="summary-row summary-total">
                        <span>Total:</span>
                        <span>Rs<%= df.format(total)%></span>
                    </div>
                </div>

                <div class="cart-actions">
                    <a href="main.jsp" class="action-btn continue-shopping">Continue Shopping</a>

                    <!-- Clear cart form -->
                    <form method="POST" action="cart.jsp" style="display: inline;" 
                          onsubmit="return confirm('Are you sure you want to clear your entire cart? This action cannot be undone.')">
                        <input type="hidden" name="action" value="clear">
                        <button type="submit" class="action-btn clear-cart">Clear Cart</button>
                    </form>
                    <form method="POST" action="checkout.jsp" style="display: inline;">
                        <input type="hidden" name="fromCart" value="true">
                        <input type="hidden" name="cartTotal" value="<%= total%>">
                        <input type="hidden" name="cartSubtotal" value="<%= subtotal%>">
                        <input type="hidden" name="cartShipping" value="<%= shipping%>">
                        <input type="hidden" name="totalItems" value="<%= totalItems%>">
                        <button type="submit" class="action-btn checkout">
                            Proceed to Checkout - Rs<%= df.format(total)%>
                        </button>
                    </form>
                </div>
                <% }%>
            </div>
        </div>
    </body>
</html>