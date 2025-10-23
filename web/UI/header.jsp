<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>

<%
    // Get cart from session and calculate total items
    List<Map<String, Object>> cart = (List<Map<String, Object>>) session.getAttribute("cart");
    int headerCartCount = 0;

    if (cart != null) {
        for (Map<String, Object> item : cart) {
            headerCartCount += (Integer) item.get("quantity");
        }
    }

    // Get logged in username from session
    String loggedInUsername = (String) session.getAttribute("loggedInUsername");
        String role = (String) session.getAttribute("role");

    
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
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

        /* Username display styles */
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
            display: <%= headerCartCount > 0 ? "inline-block" : "none"%>;
        }

        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 1rem;
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
        }

        .product-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
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
        }

        .product-name {
            font-size: 1.2rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
            color: #2c3e50;
        }

        .product-description {
            color: #7f8c8d;
            margin-bottom: 1rem;
            font-size: 0.9rem;
        }

        .product-price {
            font-size: 1.3rem;
            font-weight: bold;
            color: #e74c3c;
            margin-bottom: 1rem;
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

        /* Success message styles */
        .success-message {
            position: fixed;
            top: 90px;
            right: 20px;
            background-color: #27ae60;
            color: white;
            padding: 1rem 1.5rem;
            border-radius: 5px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
            z-index: 1000;
            display: none;
            animation: slideIn 0.3s ease-out;
        }

        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
    </style>
    <body>
        <header class="header">
            <a href="main.jsp" class="logo">Syops</a>
            <div class="nav-options">
                <!-- Display username if logged in -->
                <% if (loggedInUsername != null && !loggedInUsername.trim().isEmpty()) {%>
                <span class="username-display"><%= loggedInUsername%></span>asd
                <% }%>
                <% if (loggedInUsername != null && !loggedInUsername.trim().isEmpty()) {%>
                <span class="username-display"><%= role%></span>
                <% }%>

                <a href="cart.jsp" class="cart-btn">
                    🛒 Cart 
                    <span class="cart-count" id="cartCount"><%= headerCartCount%></span>
                </a>
                <a class="logout-btn" href="./login.jsp">Logout</a>
            </div>
        </header>

        <!-- Success message for cart additions -->
        <div id="successMessage" class="success-message">
            <span id="messageText"></span>
        </div>

        <script>
            function addToCart(productName, price) {
                // Show loading message
                showMessage('Adding ' + productName + ' to cart...', '#f39c12');

                // Small delay to show the message before redirect
                setTimeout(function () {
                    // Redirect to cart.jsp with add action
                    window.location.href = 'cart.jsp?action=add&productName=' + encodeURIComponent(productName) + '&price=' + price + '&redirect=main';
                }, 500);
            }

            function viewCart() {
                window.location.href = 'cart.jsp';
            }

            function logout() {
                if (confirm('Are you sure you want to logout?')) {
                    // Redirect to logout servlet
                    window.location.href = '<%= request.getContextPath()%>/LogoutServlet';
                }
            }

            function showMessage(message, color = '#27ae60') {
                const messageEl = document.getElementById('successMessage');
                const textEl = document.getElementById('messageText');

                if (messageEl && textEl) {
                    textEl.textContent = message;
                    messageEl.style.backgroundColor = color;
                    messageEl.style.display = 'block';

                    setTimeout(() => {
                        messageEl.style.display = 'none';
                    }, 3000);
            }
            }

            // Check for success message from URL parameters
            window.onload = function () {
                const urlParams = new URLSearchParams(window.location.search);
                const added = urlParams.get('added');

                if (added) {
                    showMessage(decodeURIComponent(added) + ' added to cart successfully!');

                    // Clean up URL by removing the 'added' parameter
                    const url = new URL(window.location);
                    url.searchParams.delete('added');
                    window.history.replaceState({}, '', url);
                }
            };
        </script>
    </body>
</html>