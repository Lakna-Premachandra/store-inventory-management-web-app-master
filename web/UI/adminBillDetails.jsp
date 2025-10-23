<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%@page import="MODELS.Bill"%>
<%@page import="SERVICES.BillService"%>
<%@page import="java.math.BigDecimal"%>

<%
    // Initialize BillService to get real data
    BillService billService = new BillService();
    List<Bill> billList = null;
    String errorMessage = null;
    String successMessage = null;

    // Get filter parameters
    String usernameFilter = request.getParameter("username");
    String billTypeFilter = request.getParameter("billType");
    String searchTerm = request.getParameter("search");

    try {
        // Fetch bills based on filters
        if (usernameFilter != null && !usernameFilter.trim().isEmpty()) {
            billList = billService.getBillsByUsername(usernameFilter);
            successMessage = "Showing bills for user: " + usernameFilter;
        } else if (billTypeFilter != null && !billTypeFilter.trim().isEmpty()) {
            billList = billService.getBillsByType(billTypeFilter);
            successMessage = "Showing " + billTypeFilter + " bills";
        } else {
            billList = billService.getAllBills();
        }

        // If no bills found
        if (billList == null) {
            billList = new ArrayList<>();
            errorMessage = "No bills found.";
        }

    } catch (Exception e) {
        billList = new ArrayList<>();
        errorMessage = "Error fetching bill data: " + e.getMessage();
    }

    // Convert Bill objects to Map for easier JSP handling (maintaining compatibility with existing frontend)
    List<Map<String, Object>> bills = new ArrayList<>();
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    for (Bill bill : billList) {
        Map<String, Object> billMap = new HashMap<>();
        billMap.put("orderNumber", "#ORD" + bill.getBillId()); // Using billId as order number
        billMap.put("totalAmount", "Rs" + bill.getAmount().toString());
        billMap.put("paymentMethod", "ONLINE"); // Default since not in Bill model
        billMap.put("customer", bill.getUsername());
        billMap.put("billId", "BILL" + bill.getBillId());
        billMap.put("billType", bill.getBillType());
        billMap.put("generatedOn", dateFormat.format(bill.getAmount()));
        billMap.put("username", bill.getUsername());
        billMap.put("status", "Generated");
        bills.add(billMap);
    }

    // Calculate statistics
    BigDecimal totalRevenue = BigDecimal.ZERO;
    int generatedBillsCount = 0;

    for (Bill bill : billList) {
        totalRevenue = totalRevenue.add(bill.getAmount());
        generatedBillsCount++; // All bills in our system are generated
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Bill Details - Syops Retail Shop</title>
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

            .filter-section {
                background: rgba(255, 255, 255, 0.9);
                padding: 1.5rem;
                border-radius: 15px;
                margin-bottom: 2rem;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            }

            .filter-form {
                display: flex;
                gap: 1rem;
                align-items: center;
                flex-wrap: wrap;
            }

            .filter-group {
                display: flex;
                flex-direction: column;
                gap: 0.3rem;
            }

            .filter-label {
                font-size: 0.85rem;
                color: #64748b;
                font-weight: 600;
            }

            .filter-input, .filter-select {
                padding: 0.6rem;
                border: 2px solid #e2e8f0;
                border-radius: 8px;
                font-size: 0.95rem;
                min-width: 150px;
            }

            .filter-btn {
                background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
                color: white;
                border: none;
                padding: 0.7rem 1.5rem;
                border-radius: 8px;
                cursor: pointer;
                font-size: 0.95rem;
                font-weight: 600;
                margin-top: 1.2rem;
            }

            .clear-btn {
                background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
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

            .bills-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
                gap: 2rem;
                margin-top: 1rem;
            }

            .bill-card {
                background: white;
                border-radius: 15px;
                box-shadow: 0 8px 25px rgba(0,0,0,0.1);
                overflow: hidden;
                transition: all 0.3s ease;
                border: 1px solid rgba(255,255,255,0.2);
            }

            .bill-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 15px 40px rgba(0,0,0,0.15);
            }

            .bill-header {
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white;
                padding: 1.5rem;
                text-align: center;
            }

            .bill-header h3 {
                font-size: 1.3rem;
                font-weight: 600;
                margin-bottom: 0.5rem;
            }

            .bill-status {
                display: inline-block;
                background: rgba(39, 174, 96, 0.2);
                color: #27ae60;
                padding: 0.3rem 0.8rem;
                border-radius: 15px;
                font-size: 0.85rem;
                font-weight: 600;
                border: 2px solid #27ae60;
            }

            .bill-body {
                padding: 2rem;
            }

            .bill-section {
                margin-bottom: 2rem;
            }

            .bill-section:last-child {
                margin-bottom: 0;
            }

            .section-header {
                font-size: 1.1rem;
                font-weight: 700;
                color: #2c3e50;
                margin-bottom: 1rem;
                padding-bottom: 0.5rem;
                border-bottom: 2px solid #e2e8f0;
            }

            .bill-details {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 1rem;
            }

            .detail-item {
                display: flex;
                flex-direction: column;
                gap: 0.3rem;
            }

            .detail-label {
                font-size: 0.85rem;
                color: #64748b;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .detail-value {
                font-size: 1rem;
                color: #2c3e50;
                font-weight: 600;
            }

            .detail-value.amount {
                color: #e74c3c;
                font-size: 1.2rem;
                font-weight: 700;
            }

            .detail-value.order-number {
                color: #3498db;
                font-family: monospace;
                font-weight: 700;
            }

            .detail-value.payment-method {
                color: #27ae60;
                font-weight: 700;
            }

            .bill-section.generated {
                background: linear-gradient(135deg, #d5f4e6 0%, #c6f6d5 100%);
                border: 2px solid #48bb78;
                border-radius: 10px;
                padding: 1.5rem;
                position: relative;
            }

            .bill-section.generated::before {
                content: '✓';
                position: absolute;
                top: 1rem;
                right: 1rem;
                background: #27ae60;
                color: white;
                width: 30px;
                height: 30px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: bold;
                font-size: 1.1rem;
            }

            .generated-header {
                color: #2f855a;
                font-weight: 700;
                margin-bottom: 1rem;
                font-size: 1.1rem;
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

            @media (max-width: 768px) {
                .container {
                    padding: 0 0.5rem;
                }

                .admin-section {
                    padding: 1.5rem;
                }

                .filter-form {
                    flex-direction: column;
                    align-items: stretch;
                }

                .action-buttons {
                    flex-direction: column;
                    gap: 1rem;
                }

                .search-container {
                    max-width: 100%;
                }

                .bills-grid {
                    grid-template-columns: 1fr;
                }

                .bill-details {
                    grid-template-columns: 1fr;
                }

                .stats-section {
                    flex-direction: column;
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
                <a href="admin.jsp" class="nav-btn">Back to Dashboard</a>
                <a href="reports.jsp" class="nav-btn">Reports</a>
                <a href="login.jsp" class="nav-btn">Logout</a>
            </div>
        </div>

        <!-- Main Content -->
        <div class="container">
            <!-- Statistics Section -->
            <div class="stats-section">
                <div class="stat-card">
                    <div class="stat-number"><%= bills.size()%></div>
                    <div class="stat-label">Total Bills</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number"><%= generatedBillsCount%></div>
                    <div class="stat-label">Bills Generated</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">Rs<%= totalRevenue.toString()%></div>
                    <div class="stat-label">Total Revenue</div>
                </div>
            </div>



            <div class="admin-section">
                <h2 class="section-title">Customer Bill Details</h2>

                <div class="action-buttons">
                    <div class="search-container">
                        <input type="text" class="search-input" id="searchInput" 
                               placeholder="Search by order number, customer..." onkeyup="searchBills()">
                    </div>
                    <div style="display: flex; gap: 1rem;">
                        <a href="adminBillDetails.jsp" class="refresh-btn">Refresh</a>
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

                <!-- Bills Grid -->
                <div class="bills-grid" id="billsGrid">
                    <% if (bills.isEmpty()) { %>
                    <div class="no-data">
                        No bills found. Bills will appear here once customers make purchases.
                    </div>
                    <% } else { %>
                    <% for (Map<String, Object> bill : bills) {%>
                    <div class="bill-card" 
                         data-order="<%= bill.get("orderNumber")%>"
                         data-customer="<%= bill.get("customer")%>"
                         data-bill-id="<%= bill.get("billId")%>">

                        <div class="bill-header">
                            <h3>Order Details</h3>
                            <div class="bill-status"><%= bill.get("status")%></div>
                        </div>

                        <div class="bill-body">
                            <div class="bill-section">
                                <div class="bill-details">
                                    <div class="detail-item">
                                        <span class="detail-label">Order Number:</span>
                                        <span class="detail-value order-number"><%= bill.get("orderNumber")%></span>
                                    </div>
                                    <div class="detail-item">
                                        <span class="detail-label">Payment Method:</span>
                                        <span class="detail-value payment-method"><%= bill.get("paymentMethod")%></span>
                                    </div>
                                    <div class="detail-item">
                                        <span class="detail-label">Total Amount:</span>
                                        <span class="detail-value amount"><%= bill.get("totalAmount")%></span>
                                    </div>
                                    <div class="detail-item">
                                        <span class="detail-label">Customer:</span>
                                        <span class="detail-value"><%= bill.get("customer")%></span>
                                    </div>
                                </div>
                            </div>

                            <div class="bill-section generated">
                                <div class="generated-header">✓ Bill Generated</div>
                                <div class="bill-details">
                                    <div class="detail-item">
                                        <span class="detail-label">Bill ID:</span>
                                        <span class="detail-value order-number"><%= bill.get("billId")%></span>
                                    </div>
                                    <div class="detail-item">
                                        <span class="detail-label">Generated On:</span>
                                        <span class="detail-value"><%= bill.get("generatedOn")%></span>
                                    </div>
                                    <div class="detail-item">
                                        <span class="detail-label">Bill Type:</span>
                                        <span class="detail-value"><%= bill.get("billType")%></span>
                                    </div>
                                    <div class="detail-item">
                                        <span class="detail-label">Username:</span>
                                        <span class="detail-value"><%= bill.get("username")%></span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <% } %>
                    <% }%>
                </div>
            </div>
        </div>

        <script>
            // Store bills data for search functionality
            const allBills = document.querySelectorAll('.bill-card');

            // Search functionality
            function searchBills() {
                const searchTerm = document.getElementById('searchInput').value.toLowerCase();
                const grid = document.getElementById('billsGrid');
                let visibleBills = 0;

                allBills.forEach(bill => {
                    const orderNumber = bill.dataset.order.toLowerCase();
                    const customer = bill.dataset.customer.toLowerCase();
                    const billId = bill.dataset.billId.toLowerCase();

                    if (orderNumber.includes(searchTerm) ||
                            customer.includes(searchTerm) ||
                            billId.includes(searchTerm)) {
                        bill.style.display = '';
                        visibleBills++;
                    } else {
                        bill.style.display = 'none';
                    }
                });

                // Show "no results" message if no bills visible
                if (visibleBills === 0 && allBills.length > 0 && searchTerm !== '') {
                    if (!document.getElementById('noSearchResults')) {
                        const noResultsDiv = document.createElement('div');
                        noResultsDiv.id = 'noSearchResults';
                        noResultsDiv.className = 'no-data';
                        noResultsDiv.textContent = 'No bills found matching your search';
                        grid.appendChild(noResultsDiv);
                    }
                } else {
                    const noResultsDiv = document.getElementById('noSearchResults');
                    if (noResultsDiv) {
                        noResultsDiv.remove();
                    }
                }
            }

            // Keyboard shortcuts
            document.addEventListener('keydown', function (e) {
                // Escape to clear search
                if (e.key === 'Escape') {
                    document.getElementById('searchInput').value = '';
                    searchBills();
                }
                // Ctrl+R to refresh page
                if (e.ctrlKey && e.key === 'r') {
                    e.preventDefault();
                    window.location.reload();
                }
            });

            document.addEventListener('DOMContentLoaded', function () {
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

                // Add hover effects to bill cards
                const billCards = document.querySelectorAll('.bill-card');
                billCards.forEach(card => {
                    card.addEventListener('mouseenter', function () {
                        this.style.transform = 'translateY(-8px) scale(1.02)';
                    });

                    card.addEventListener('mouseleave', function () {
                        this.style.transform = 'translateY(0) scale(1)';
                    });
                });
            });
        </script>
    </body>
</html>