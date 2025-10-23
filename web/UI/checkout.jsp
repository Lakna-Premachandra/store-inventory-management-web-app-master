<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="java.math.BigDecimal"%>
<%@page import="java.net.http.*"%>
<%@page import="java.net.URI"%>
<%@page import="java.time.Duration"%>
<%@page import="com.google.gson.*"%>
<%@page import="java.io.IOException"%>
<%@page import="SERVICES.CartService"%>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    String username = (String) session.getAttribute("loggedInUsername");
    String userRole = (String) session.getAttribute("role");

    if (username == null || username.trim().isEmpty()) {
        response.sendRedirect("login.jsp");
        return;
    }

    String billType = "ONLINE";
    if (userRole != null && "ADMIN".equalsIgnoreCase(userRole.trim())) {
        billType = "INSTORE";
    }

    List<Map<String, Object>> cart = (List<Map<String, Object>>) session.getAttribute("cart");

    if (cart == null || cart.isEmpty()) {
        response.sendRedirect("main.jsp");
        return;
    }

    double subtotal = 0;
    int totalItems = 0;
    for (Map<String, Object> item : cart) {
        double price = (Double) item.get("price");
        int quantity = (Integer) item.get("quantity");
        subtotal += price * quantity;
        totalItems += quantity;
    }

    double shipping = subtotal > 50 ? 0 : 10;
    double total = subtotal + shipping;

    DecimalFormat df = new DecimalFormat("#0.00");

    String errorMessage = null;
    String successMessage = null;
    boolean orderSuccess = false;
    String orderNumber = null;
    String billId = null;
    String billDate = null;
    String billUsername = null;
    String finalBillType = null;
    BigDecimal billAmount = null;
    BigDecimal cashTendered = null;
    BigDecimal changeAmount = null;

    String action = request.getParameter("action");
    if ("process".equals(action)) {
        String fullName = request.getParameter("fullName");
        String paymentMethod = request.getParameter("paymentMethod");
        String cardNumber = request.getParameter("cardNumber");
        String expiryDate = request.getParameter("expiryDate");
        String cvv = request.getParameter("cvv");
        String cardName = request.getParameter("cardName");
        String cashAmountStr = request.getParameter("cashAmount");

        boolean isValid = true;
        StringBuilder validationErrors = new StringBuilder();

        if (fullName == null || fullName.trim().isEmpty()) {
            validationErrors.append("Full name is required. ");
            isValid = false;
        }

        if (paymentMethod == null || paymentMethod.trim().isEmpty()) {
            validationErrors.append("Payment method is required. ");
            isValid = false;
        }

        if ("card".equals(paymentMethod) && isValid) {
            if (cardNumber == null || cardNumber.trim().isEmpty()) {
                validationErrors.append("Card number is required. ");
                isValid = false;
            } else {
                String cleanCardNumber = cardNumber.replaceAll("\\s+", "");
                if (cleanCardNumber.length() < 13 || cleanCardNumber.length() > 19 || !cleanCardNumber.matches("\\d+")) {
                    validationErrors.append("Invalid card number format. ");
                    isValid = false;
                }
            }

            if (expiryDate == null || expiryDate.trim().isEmpty()) {
                validationErrors.append("Expiry date is required. ");
                isValid = false;
            } else if (!expiryDate.matches("\\d{2}/\\d{2}")) {
                validationErrors.append("Invalid expiry date format (MM/YY required). ");
                isValid = false;
            }

            if (cvv == null || cvv.trim().isEmpty()) {
                validationErrors.append("CVV is required. ");
                isValid = false;
            } else if (!cvv.matches("\\d{3,4}")) {
                validationErrors.append("Invalid CVV format. ");
                isValid = false;
            }

            if (cardName == null || cardName.trim().isEmpty()) {
                validationErrors.append("Name on card is required. ");
                isValid = false;
            }
        }

        if ("cash".equals(paymentMethod) && "ADMIN".equalsIgnoreCase(userRole) && isValid) {
            if (cashAmountStr == null || cashAmountStr.trim().isEmpty()) {
                validationErrors.append("Cash amount is required. ");
                isValid = false;
            } else {
                try {
                    double cashAmt = Double.parseDouble(cashAmountStr);
                    if (cashAmt < total) {
                        validationErrors.append("Cash tendered (Rs" + df.format(cashAmt) + ") is less than total amount (Rs" + df.format(total) + "). ");
                        isValid = false;
                    }
                } catch (NumberFormatException e) {
                    validationErrors.append("Invalid cash amount format. ");
                    isValid = false;
                }
            }
        }

        if (!isValid) {
            errorMessage = validationErrors.toString();
        } else {
            try {
                HttpClient client = HttpClient.newBuilder()
                        .connectTimeout(Duration.ofSeconds(10))
                        .build();

                String baseUrl = request.getScheme() + "://" + request.getServerName() + ":"
                        + request.getServerPort() + request.getContextPath();

                JsonObject checkoutData = new JsonObject();
                checkoutData.addProperty("username", username);
                
                if ("cash".equals(paymentMethod) && "ADMIN".equalsIgnoreCase(userRole) && cashAmountStr != null) {
                    checkoutData.addProperty("cashTendered", new BigDecimal(cashAmountStr));
                }

                HttpRequest checkoutRequest = HttpRequest.newBuilder()
                        .uri(URI.create(baseUrl + "/CheckoutServlet"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(checkoutData.toString()))
                        .build();

                HttpResponse<String> checkoutResponse = client.send(checkoutRequest,
                        HttpResponse.BodyHandlers.ofString());
                String checkoutResponseBody = checkoutResponse.body();

                if (checkoutResponse.statusCode() == 201) {
                    JsonObject responseJson = JsonParser.parseString(checkoutResponseBody)
                            .getAsJsonObject();

                    orderSuccess = responseJson.get("success").getAsBoolean();

                    if (orderSuccess) {
                        if (responseJson.has("billId")) {
                            billId = responseJson.get("billId").getAsString();
                        }
                        if (responseJson.has("billType")) {
                            finalBillType = responseJson.get("billType").getAsString();
                        }
                        if (responseJson.has("amount")) {
                            billAmount = responseJson.get("amount").getAsBigDecimal();
                        }
                        if (responseJson.has("cashTendered")) {
                            cashTendered = responseJson.get("cashTendered").getAsBigDecimal();
                        }
                        if (responseJson.has("changeAmount")) {
                            changeAmount = responseJson.get("changeAmount").getAsBigDecimal();
                        }

                        orderNumber = "ORD" + System.currentTimeMillis();

                        session.setAttribute("lastOrderNumber", orderNumber);
                        session.setAttribute("lastOrderTotal", total);
                        session.setAttribute("lastOrderCustomer", fullName);
                        session.setAttribute("lastOrderPayment", paymentMethod);
                        session.setAttribute("lastOrderItems", new ArrayList<>(cart));
                        session.setAttribute("lastBillId", billId);
                        session.setAttribute("lastBillType", finalBillType);
                        session.setAttribute("lastBillAmount", billAmount);
                        session.setAttribute("lastCashTendered", cashTendered);
                        session.setAttribute("lastChangeAmount", changeAmount);

                        cart.clear();
                        session.setAttribute("cart", cart);

                        successMessage = "Order placed successfully!";
                    } else {
                        String message = responseJson.has("message")
                                ? responseJson.get("message").getAsString()
                                : "Failed to process checkout";
                        errorMessage = message;
                    }
                } else {
                    JsonObject errorJson = JsonParser.parseString(checkoutResponseBody)
                            .getAsJsonObject();
                    errorMessage = errorJson.has("error")
                            ? errorJson.get("error").getAsString()
                            : "Failed to process checkout. Please try again.";
                }

            } catch (Exception e) {
                errorMessage = "An error occurred while processing your order: " + e.getMessage();
                e.printStackTrace();
            }
        }
    }

    boolean showSuccess = "true".equals(request.getParameter("success")) || orderSuccess;
    
    if (showSuccess && !orderSuccess) {
        orderNumber = (String) session.getAttribute("lastOrderNumber");
        Double lastTotal = (Double) session.getAttribute("lastOrderTotal");
        if (lastTotal != null) {
            total = lastTotal;
        }
        billId = (String) session.getAttribute("lastBillId");
        billDate = (String) session.getAttribute("lastBillDate");
        billUsername = (String) session.getAttribute("lastBillUsername");
        finalBillType = (String) session.getAttribute("lastBillType");
        billAmount = (BigDecimal) session.getAttribute("lastBillAmount");
        cashTendered = (BigDecimal) session.getAttribute("lastCashTendered");
        changeAmount = (BigDecimal) session.getAttribute("lastChangeAmount");

        session.removeAttribute("lastOrderNumber");
        session.removeAttribute("lastOrderTotal");
        session.removeAttribute("lastOrderCustomer");
        session.removeAttribute("lastOrderPayment");
        session.removeAttribute("lastOrderItems");
        session.removeAttribute("lastBillId");
        session.removeAttribute("lastBillDate");
        session.removeAttribute("lastBillUsername");
        session.removeAttribute("lastBillType");
        session.removeAttribute("lastBillAmount");
        session.removeAttribute("lastCashTendered");
        session.removeAttribute("lastChangeAmount");
    } else if (orderSuccess) {
        billId = (String) session.getAttribute("lastBillId");
        billDate = (String) session.getAttribute("lastBillDate");
        billUsername = (String) session.getAttribute("lastBillUsername");
        finalBillType = (String) session.getAttribute("lastBillType");
        billAmount = (BigDecimal) session.getAttribute("lastBillAmount");
        cashTendered = (BigDecimal) session.getAttribute("lastCashTendered");
        changeAmount = (BigDecimal) session.getAttribute("lastChangeAmount");
    }
%>
<%
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    String currentDateTime = sdf.format(new java.util.Date());
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Checkout - Syops</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: Arial, sans-serif;
                background-color: #f5f5f5;
                line-height: 1.6;
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

            .checkout-header {
                text-align: center;
                margin-bottom: 2rem;
            }

            .checkout-title {
                font-size: 2.5rem;
                color: #2c3e50;
                margin-bottom: 0.5rem;
            }

            .checkout-subtitle {
                color: #7f8c8d;
                font-size: 1.1rem;
            }

            .error-message {
                background-color: #e74c3c;
                color: white;
                padding: 1rem;
                border-radius: 5px;
                margin-bottom: 2rem;
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

            .role-badge {
                display: inline-block;
                padding: 0.3rem 0.8rem;
                border-radius: 15px;
                font-size: 0.85rem;
                font-weight: bold;
                margin-left: 0.5rem;
            }

            .role-admin {
                background-color: #e74c3c;
                color: white;
            }

            .role-user {
                background-color: #27ae60;
                color: white;
            }

            .checkout-container {
                display: grid;
                grid-template-columns: 1fr 400px;
                gap: 2rem;
                margin-bottom: 2rem;
            }

            .checkout-form {
                background-color: white;
                padding: 2rem;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }

            .form-section {
                margin-bottom: 2rem;
            }

            .section-title {
                font-size: 1.3rem;
                color: #2c3e50;
                margin-bottom: 1rem;
                padding-bottom: 0.5rem;
                border-bottom: 2px solid #3498db;
            }

            .form-group {
                margin-bottom: 1rem;
            }

            .form-group label {
                display: block;
                margin-bottom: 0.5rem;
                color: #2c3e50;
                font-weight: bold;
            }

            .form-group input,
            .form-group select {
                width: 100%;
                padding: 0.8rem;
                border: 1px solid #ddd;
                border-radius: 5px;
                font-size: 1rem;
                transition: border-color 0.3s;
            }

            .form-group input:focus,
            .form-group select:focus {
                outline: none;
                border-color: #3498db;
                box-shadow: 0 0 5px rgba(52, 152, 219, 0.3);
            }

            .form-row {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 1rem;
            }

            .order-summary {
                background-color: white;
                padding: 2rem;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                height: fit-content;
                position: sticky;
                top: 2rem;
            }

            .summary-title {
                font-size: 1.5rem;
                color: #2c3e50;
                margin-bottom: 1.5rem;
                text-align: center;
            }

            .order-items {
                margin-bottom: 1.5rem;
            }

            .order-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 0.5rem 0;
                border-bottom: 1px solid #ecf0f1;
            }

            .item-info {
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .item-emoji {
                font-size: 1.2rem;
            }

            .item-details {
                font-size: 0.9rem;
            }

            .item-name {
                font-weight: bold;
                color: #2c3e50;
            }

            .item-qty {
                color: #7f8c8d;
                font-size: 0.8rem;
            }

            .item-price {
                font-weight: bold;
                color: #e74c3c;
            }

            .summary-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 0.5rem;
                padding: 0.5rem 0;
            }

            .summary-total {
                border-top: 2px solid #3498db;
                padding-top: 1rem;
                margin-top: 1rem;
                font-weight: bold;
                font-size: 1.3rem;
                color: #2c3e50;
            }

            .place-order-btn {
                width: 100%;
                background-color: #27ae60;
                color: white;
                border: none;
                padding: 1rem;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1.1rem;
                font-weight: bold;
                transition: background-color 0.3s;
                margin-top: 1rem;
            }

            .place-order-btn:hover {
                background-color: #219a52;
            }

            .place-order-btn:active {
                transform: scale(0.98);
            }

            .success-message {
                background-color: white;
                padding: 3rem;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                text-align: center;
                margin-bottom: 2rem;
            }

            .success-icon {
                font-size: 4rem;
                color: #27ae60;
                margin-bottom: 1rem;
            }

            .success-title {
                font-size: 2rem;
                color: #27ae60;
                margin-bottom: 1rem;
            }

            .success-message p {
                color: #7f8c8d;
                font-size: 1.1rem;
                margin-bottom: 2rem;
            }

            .success-message h3 {
                margin-bottom: 1rem;
                color: #2c3e50;
            }

            .success-message strong {
                color: #2c3e50;
            }

            .back-to-shop {
                background-color: #3498db;
                color: white;
                border: none;
                padding: 1rem 2rem;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1rem;
                text-decoration: none;
                display: inline-block;
                transition: background-color 0.3s;
            }

            .back-to-shop:hover {
                background-color: #2980b9;
            }

            .security-info {
                background-color: #ecf0f1;
                padding: 1rem;
                border-radius: 5px;
                margin-top: 1rem;
                border-left: 4px solid #27ae60;
            }

            .security-info h4 {
                color: #27ae60;
                margin-bottom: 0.5rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .security-info p {
                color: #7f8c8d;
                font-size: 0.9rem;
            }

            .cash-info {
                background-color: #ecf0f1;
                padding: 1rem;
                border-radius: 5px;
                margin-top: 1rem;
                border-left: 4px solid #f39c12;
            }

            .cash-info h4 {
                color: #f39c12;
                margin-bottom: 0.5rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .cash-info p {
                color: #7f8c8d;
                font-size: 0.9rem;
            }

            .payment-fields {
                display: none;
            }

            .payment-fields.show {
                display: block;
            }

            .admin-cash-amount {
                background-color: #fff3cd;
                border: 2px solid #f39c12;
                padding: 1rem;
                border-radius: 5px;
                margin-top: 1rem;
            }

            .admin-cash-amount label {
                color: #856404;
                font-weight: bold;
            }

            .admin-cash-amount input {
                border: 2px solid #f39c12;
            }

            .admin-cash-amount input:focus {
                border-color: #e67e22;
                box-shadow: 0 0 5px rgba(243, 156, 18, 0.5);
            }

            .change-display {
                background-color: #d4edda;
                border: 2px solid #28a745;
                padding: 1rem;
                border-radius: 5px;
                margin-top: 1rem;
                text-align: center;
            }

            .change-display h4 {
                color: #155724;
                margin-bottom: 0.5rem;
                font-size: 1.1rem;
            }

            .change-amount-value {
                font-size: 1.8rem;
                font-weight: bold;
                color: #28a745;
            }

            @media (max-width: 768px) {
                .checkout-container {
                    grid-template-columns: 1fr;
                }

                .form-row {
                    grid-template-columns: 1fr;
                }

                .order-summary {
                    position: static;
                }

                .container {
                    padding: 0 0.5rem;
                }

                .checkout-form,
                .order-summary {
                    padding: 1rem;
                }
            }
        </style>
    </head>
    <body>
        <header class="header">
            <a href="main.jsp" class="logo">Syops</a>
            <div class="nav-options">
                <% if (username != null && !username.trim().isEmpty()) {%>
                <span class="username-display">
                    <%= username%>
                    <% if (userRole != null && !userRole.trim().isEmpty()) {%>
                    <span class="role-badge <%= "ADMIN".equalsIgnoreCase(userRole) ? "role-admin" : "role-user"%>">
                        <%= userRole.toUpperCase()%>
                    </span>
                    <% } %>
                </span>
                <% }%>
                <a href="<%= "ADMIN".equalsIgnoreCase(userRole) ? "allProducts.jsp" : "main.jsp"%>" class="nav-btn">Continue Shopping</a>
                <a href="cart.jsp" class="nav-btn">Back to Cart</a>
                <a href="login.jsp" class="nav-btn">Logout</a>
            </div>
        </header>

        <div class="container">
            <% if ((showSuccess && orderNumber != null) || orderSuccess) {%>
            <div class="success-message">
                <div class="success-icon">✅</div>
                <h1 class="success-title">Order Placed Successfully!</h1>
                <p>Thank you for your purchase. Your order has been confirmed and will be processed shortly.</p>

                <div style="background-color: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin: 1rem 0; text-align: left;">
                    <h3 style="color: #2c3e50; margin-bottom: 1rem; text-align: center;">Order Details</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                        <div>
                            <p><strong>Order Number:</strong> #<%= orderNumber%></p>
                            <p><strong>Total Amount:</strong> Rs<%= df.format(total)%></p>
                        </div>
                        <div>
                            <p><strong>Payment Method:</strong> <%= request.getParameter("paymentMethod") != null ? request.getParameter("paymentMethod").toUpperCase() : "N/A"%></p>
                            <p><strong>Customer:</strong> <%= request.getParameter("fullName") != null ? request.getParameter("fullName") : "N/A"%></p>
                        </div>
                    </div>
                </div>

                <% if (billId != null) {%>
                <div style="background-color: <%= "INSTORE".equals(finalBillType) ? "#fff3cd" : "#e8f5e8"%>; padding: 1.5rem; border-radius: 8px; margin: 1rem 0; text-align: left; border-left: 4px solid <%= "INSTORE".equals(finalBillType) ? "#f39c12" : "#27ae60"%>;">
                    <h3 style="color: <%= "INSTORE".equals(finalBillType) ? "#f39c12" : "#27ae60"%>; margin-bottom: 1rem; text-align: center;">📄 Bill Generated</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                        <div>
                            <p><strong>Bill ID:</strong> <%= billId%></p>
                            <p><strong>Bill Type:</strong> <span style="background-color: <%= "INSTORE".equals(finalBillType) ? "#f39c12" : "#27ae60"%>; color: white; padding: 0.2rem 0.8rem; border-radius: 10px; font-size: 0.9rem;"><%= finalBillType != null ? finalBillType : "N/A"%></span></p>
                        </div>
                        <div>
                            <p><strong>Generated On:</strong> <%= currentDateTime %></p>
                            <p><strong>Amount:</strong> Rs<%= billAmount != null ? df.format(billAmount) : df.format(total)%></p>
                        </div>
                    </div>
                    
                    <% if ("INSTORE".equals(finalBillType) && cashTendered != null) { %>
                    <div style="margin-top: 1.5rem; padding: 1rem; background-color: #d4edda; border-left: 4px solid #28a745; border-radius: 5px;">
                        <h4 style="color: #155724; margin-bottom: 0.8rem; font-size: 1.1rem;">💵 Cash Payment Details</h4>
                        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; text-align: center;">
                            <div>
                                <p style="margin: 0; color: #666; font-size: 0.9rem;">Total Bill</p>
                                <p style="margin: 0.3rem 0 0 0; font-weight: bold; font-size: 1.2rem; color: #2c3e50;">Rs<%= df.format(billAmount)%></p>
                            </div>
                            <div>
                                <p style="margin: 0; color: #666; font-size: 0.9rem;">Cash Tendered</p>
                                <p style="margin: 0.3rem 0 0 0; font-weight: bold; font-size: 1.2rem; color: #f39c12;">Rs<%= df.format(cashTendered)%></p>
                            </div>
                            <div>
                                <p style="margin: 0; color: #666; font-size: 0.9rem;">Change</p>
                                <p style="margin: 0.3rem 0 0 0; font-weight: bold; font-size: 1.2rem; color: #28a745;">Rs<%= changeAmount != null ? df.format(changeAmount) : "0.00"%></p>
                            </div>
                        </div>
                    </div>
                    <% } %>
                    
                    <% if ("INSTORE".equals(finalBillType)) { %>
                    <div style="margin-top: 1rem; padding: 0.8rem; background-color: rgba(243, 156, 18, 0.1); border-radius: 5px;">
                        <p style="margin: 0; font-size: 0.9rem; color: #856404;">
                            <strong>ℹ️ Note:</strong> This is an in-store purchase processed by an administrator.
                        </p>
                    </div>
                    <% } %>
                </div>
                <% } %>

                <a href="main.jsp" class="back-to-shop">Continue Shopping</a>
            </div>
            <% } else { %>
            <div class="checkout-header">
                <h1 class="checkout-title">Checkout</h1>
                <p class="checkout-subtitle">Complete your order details below</p>
                <% if (userRole != null && "ADMIN".equalsIgnoreCase(userRole)) { %>
                <p style="color: #e74c3c; font-weight: bold; margin-top: 0.5rem;">
                    🏪 Processing as INSTORE purchase (Admin)
                </p>
                <% } else { %>
                <p style="color: #27ae60; font-weight: bold; margin-top: 0.5rem;">
                    🌐 Processing as ONLINE purchase
                </p>
                <% } %>
            </div>

            <% if (errorMessage != null) {%>
            <div class="error-message">
                <%= errorMessage%>
            </div>
            <% }%>

            <div class="checkout-container">
                <div class="checkout-form">
                    <form action="checkout.jsp" method="post" id="checkoutForm">
                        <input type="hidden" name="action" value="process">

                        <div class="form-section">
                            <h2 class="section-title">Billing Information</h2>
                            <div class="form-group">
                                <label for="fullName">Username *</label>
                                <input type="text" id="fullName" name="fullName" 
                                       value="<%= request.getParameter("fullName") != null ? request.getParameter("fullName") : ""%>" required>
                            </div>
                        </div>

                        <div class="form-section">
                            <h2 class="section-title">Payment Information</h2>
                            <div class="form-group">
                                <label for="paymentMethod">Payment Method *</label>
                                <select id="paymentMethod" name="paymentMethod" required onchange="togglePaymentFields()">
                                    <option value="">Select Payment Method</option>
                                    <option value="card" <%= "card".equals(request.getParameter("paymentMethod")) ? "selected" : ""%>>Card</option>
                                    <option value="cash" <%= "cash".equals(request.getParameter("paymentMethod")) ? "selected" : ""%>>Cash</option>
                                </select>
                            </div>

                            <div id="cardFields" class="payment-fields <%= "card".equals(request.getParameter("paymentMethod")) ? "show" : ""%>">
                                <div class="form-group">
                                    <label for="cardNumber">Card Number *</label>
                                    <input type="text" id="cardNumber" name="cardNumber" placeholder="1234 5678 9012 3456" maxlength="19"
                                           value="<%= request.getParameter("cardNumber") != null ? request.getParameter("cardNumber") : ""%>">
                                </div>
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="expiryDate">Expiry Date *</label>
                                        <input type="text" id="expiryDate" name="expiryDate" placeholder="MM/YY" maxlength="5"
                                               value="<%= request.getParameter("expiryDate") != null ? request.getParameter("expiryDate") : ""%>">
                                    </div>
                                    <div class="form-group">
                                        <label for="cvv">CVV *</label>
                                        <input type="text" id="cvv" name="cvv" placeholder="123" maxlength="4"
                                               value="<%= request.getParameter("cvv") != null ? request.getParameter("cvv") : ""%>">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="cardName">Name on Card *</label>
                                    <input type="text" id="cardName" name="cardName"
                                           value="<%= request.getParameter("cardName") != null ? request.getParameter("cardName") : ""%>">
                                </div>

                                <div class="security-info">
                                    <h4>🔒 Secure Payment</h4>
                                    <p>Your payment information is encrypted and secure. We use industry-standard SSL encryption to protect your data.</p>
                                </div>
                            </div>

                            <div id="cashInfo" class="payment-fields <%= "cash".equals(request.getParameter("paymentMethod")) ? "show" : ""%>">
                                <div class="cash-info">
                                    <h4>💰 Cash Payment</h4>
                                    <p>You have selected cash payment. Please proceed with your order and payment will be collected upon delivery.</p>
                                </div>
                                
                                <% if (userRole != null && "ADMIN".equalsIgnoreCase(userRole)) { %>
                                <div class="admin-cash-amount">
                                    <div class="form-group">
                                        <label for="cashAmount">💵 Enter Cash Amount Tendered *</label>
                                        <input type="number" id="cashAmount" name="cashAmount" 
                                               placeholder="Enter amount received from customer" 
                                               step="0.01" 
                                               min="0.01"
                                               oninput="calculateChange()"
                                               value="<%= request.getParameter("cashAmount") != null ? request.getParameter("cashAmount") : ""%>">
                                        <small style="color: #856404; display: block; margin-top: 0.5rem;">
                                            ⚠️ Admin: Enter the exact cash amount received from the customer (must be ≥ Rs<%= df.format(total)%>)
                                        </small>
                                    </div>
                                </div>
                                
                                <div id="changeDisplay" class="change-display" style="display: none;">
                                    <h4>💰 Change to Return</h4>
                                    <div class="change-amount-value" id="changeAmountDisplay">Rs0.00</div>
                                </div>
                                <% } %>
                            </div>
                        </div>

                        <button type="submit" class="place-order-btn">
                            Place Order - Rs<%= df.format(total)%>
                        </button>
                    </form>
                </div>

                <div class="order-summary">
                    <h2 class="summary-title">Order Summary</h2>

                    <div class="order-items">
                        <% for (Map<String, Object> item : cart) {
                                String itemName = (String) item.get("name");
                                double itemPrice = (Double) item.get("price");
                                int itemQuantity = (Integer) item.get("quantity");
                                double itemTotal = itemPrice * itemQuantity;

                                String productEmoji = "📦";
                                if (itemName.toLowerCase().contains("smartphone")) {
                                    productEmoji = "📱";
                                } else if (itemName.toLowerCase().contains("laptop")) {
                                    productEmoji = "💻";
                                } else if (itemName.toLowerCase().contains("headphones")) {
                                    productEmoji = "🎧";
                                }
                        %>
                        <div class="order-item">
                            <div class="item-info">
                                <span class="item-emoji"><%= productEmoji%></span>
                                <div class="item-details">
                                    <div class="item-name"><%= itemName%></div>
                                    <div class="item-qty">Qty: <%= itemQuantity%></div>
                                </div>
                            </div>
                            <div class="item-price">Rs<%= df.format(itemTotal)%></div>
                        </div>
                        <% }%>
                    </div>

                    <div class="summary-row">
                        <span>Subtotal:</span>
                        <span>Rs<%= df.format(subtotal)%></span>
                    </div>
                    <div class="summary-row">
                        <span>Shipping:</span>
                        <span><%= shipping == 0 ? "FREE" : "Rs" + df.format(shipping)%></span>
                    </div>
                    <div class="summary-row summary-total">
                        <span>Total:</span>
                        <span>Rs<%= df.format(total)%></span>
                    </div>
                </div>
            </div>
            <% }%>
        </div>

        <script>
            const orderTotal = <%= total %>;
            
            function togglePaymentFields() {
                const paymentMethod = document.getElementById('paymentMethod').value;
                const cardFields = document.getElementById('cardFields');
                const cashInfo = document.getElementById('cashInfo');
                const cashAmount = document.getElementById('cashAmount');
                const changeDisplay = document.getElementById('changeDisplay');

                cardFields.classList.remove('show');
                cashInfo.classList.remove('show');
                if (changeDisplay) {
                    changeDisplay.style.display = 'none';
                }

                if (paymentMethod === 'card') {
                    cardFields.classList.add('show');
                    document.getElementById('cardNumber').required = true;
                    document.getElementById('expiryDate').required = true;
                    document.getElementById('cvv').required = true;
                    document.getElementById('cardName').required = true;
                    if (cashAmount) {
                        cashAmount.required = false;
                    }
                } else if (paymentMethod === 'cash') {
                    cashInfo.classList.add('show');
                    document.getElementById('cardNumber').required = false;
                    document.getElementById('expiryDate').required = false;
                    document.getElementById('cvv').required = false;
                    document.getElementById('cardName').required = false;
                    if (cashAmount) {
                        cashAmount.required = true;
                        calculateChange();
                    }
                }
            }

            function calculateChange() {
                const cashAmount = document.getElementById('cashAmount');
                const changeDisplay = document.getElementById('changeDisplay');
                const changeAmountDisplay = document.getElementById('changeAmountDisplay');
                
                if (cashAmount && changeDisplay && changeAmountDisplay) {
                    const cashValue = parseFloat(cashAmount.value);
                    
                    if (!isNaN(cashValue) && cashValue > 0) {
                        const change = cashValue - orderTotal;
                        
                        if (change >= 0) {
                            changeDisplay.style.display = 'block';
                            changeAmountDisplay.textContent = 'Rs' + change.toFixed(2);
                            changeAmountDisplay.style.color = '#28a745';
                        } else {
                            changeDisplay.style.display = 'block';
                            changeAmountDisplay.textContent = 'Insufficient (Rs' + Math.abs(change).toFixed(2) + ' short)';
                            changeAmountDisplay.style.color = '#e74c3c';
                        }
                    } else {
                        changeDisplay.style.display = 'none';
                    }
                }
            }

            document.getElementById('cardNumber').addEventListener('input', function (e) {
                let value = e.target.value.replace(/\s+/g, '').replace(/[^0-9]/gi, '');
                let matches = value.match(/\d{4,16}/g);
                let match = matches && matches[0] || '';
                let parts = [];

                for (let i = 0, len = match.length; i < len; i += 4) {
                    parts.push(match.substring(i, i + 4));
                }

                if (parts.length) {
                    e.target.value = parts.join(' ');
                } else {
                    e.target.value = value;
                }
            });

            document.getElementById('expiryDate').addEventListener('input', function (e) {
                let value = e.target.value.replace(/\s+/g, '').replace(/[^0-9]/gi, '');
                if (value.length >= 2) {
                    e.target.value = value.substring(0, 2) + '/' + value.substring(2, 4);
                } else {
                    e.target.value = value;
                }
            });

            document.getElementById('cvv').addEventListener('input', function (e) {
                e.target.value = e.target.value.replace(/[^0-9]/gi, '');
            });

            const cashAmountField = document.getElementById('cashAmount');
            if (cashAmountField) {
                cashAmountField.addEventListener('input', function (e) {
                    let value = e.target.value.replace(/[^0-9.]/g, '');
                    
                    const parts = value.split('.');
                    if (parts.length > 2) {
                        value = parts[0] + '.' + parts.slice(1).join('');
                    }
                    
                    e.target.value = value;
                });
            }

            window.onload = function () {
                togglePaymentFields();
            };
        </script>
    </body>
</html>