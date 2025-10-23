<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%@page import="MODELS.Bill"%>
<%@page import="SERVICES.BillService"%>
<%@page import="java.math.BigDecimal"%>
<%@page import="java.sql.*"%>

<%
    // Get username from session
    String username = (String) session.getAttribute("loggedInUsername");

    // Initialize BillService to get real data
    BillService billService = new BillService();
    List<Bill> allBills = new ArrayList<>();
    List<Bill> inStoreBills = new ArrayList<>();
    List<Bill> onlineBills = new ArrayList<>();
    String errorMessage = null;

    try {
        // Fetch all bills
        allBills = billService.getAllBills();
        if (allBills == null) {
            allBills = new ArrayList<>();
        }

        // Fetch in-store bills
        inStoreBills = billService.getBillsByType("INSTORE");
        if (inStoreBills == null) {
            inStoreBills = new ArrayList<>();
        }

        // Fetch online bills
        onlineBills = billService.getBillsByType("ONLINE");
        if (onlineBills == null) {
            onlineBills = new ArrayList<>();
        }

    } catch (Exception e) {
        errorMessage = "Error fetching bill data: " + e.getMessage();
    }

    // Calculate statistics for Overall Bills
    BigDecimal overallRevenue = BigDecimal.ZERO;
    int overallCount = allBills.size();
    BigDecimal overallAverage = BigDecimal.ZERO;

    for (Bill bill : allBills) {
        overallRevenue = overallRevenue.add(bill.getAmount());
    }
    if (overallCount > 0) {
        overallAverage = overallRevenue.divide(new BigDecimal(overallCount), 2, BigDecimal.ROUND_HALF_UP);
    }

    // Calculate statistics for In-Store Bills
    BigDecimal inStoreRevenue = BigDecimal.ZERO;
    int inStoreCount = inStoreBills.size();
    BigDecimal inStoreAverage = BigDecimal.ZERO;

    for (Bill bill : inStoreBills) {
        inStoreRevenue = inStoreRevenue.add(bill.getAmount());
    }
    if (inStoreCount > 0) {
        inStoreAverage = inStoreRevenue.divide(new BigDecimal(inStoreCount), 2, BigDecimal.ROUND_HALF_UP);
    }

    // Calculate statistics for Online Bills
    BigDecimal onlineRevenue = BigDecimal.ZERO;
    int onlineCount = onlineBills.size();
    BigDecimal onlineAverage = BigDecimal.ZERO;

    for (Bill bill : onlineBills) {
        onlineRevenue = onlineRevenue.add(bill.getAmount());
    }
    if (onlineCount > 0) {
        onlineAverage = onlineRevenue.divide(new BigDecimal(onlineCount), 2, BigDecimal.ROUND_HALF_UP);
    }

    // Product Sales Report Data
    class ProductSalesData {

        String productCode;
        String productName;
        int totalQuantitySold;
        BigDecimal totalRevenue;
        BigDecimal unitPrice;
        BigDecimal discount;
        BigDecimal revenueWithoutDiscount;
        BigDecimal discountAmount;
        int numberOfTransactions;
    }

    List<ProductSalesData> productSalesList = new ArrayList<>();
    int totalProductsSold = 0;
    int totalUniqueProducts = 0;
    BigDecimal totalDiscountGiven = BigDecimal.ZERO;
    int productsWithDiscount = 0;
    int productsWithoutSales = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/finalsyosdb?useSSL=false&serverTimezone=UTC",
                "root",
                "0774728548Ashen");

        String query = "SELECT "
                + "p.product_code, "
                + "p.name AS product_name, "
                + "p.unit_price, "
                + "p.discount, "
                + "oi.quantity AS sold_quantity, "
                + "(p.unit_price - p.discount) * oi.quantity AS total_sales, "
                + "(p.unit_price * oi.quantity) AS revenue_without_discount "
                + "FROM online_inventory oi "
                + "JOIN products p ON oi.product_code = p.product_code "
                + "ORDER BY total_sales DESC";

        PreparedStatement stmt = conn.prepareStatement(query);
        ResultSet rs = stmt.executeQuery();

        while (rs.next()) {
            ProductSalesData psd = new ProductSalesData();
            psd.productCode = rs.getString("product_code");
            psd.productName = rs.getString("product_name");
            psd.unitPrice = rs.getBigDecimal("unit_price");
            psd.discount = rs.getBigDecimal("discount");
            psd.totalQuantitySold = rs.getInt("sold_quantity");

            // total revenue (after discount)
            psd.totalRevenue = rs.getBigDecimal("total_sales");

            // revenue without discount
            psd.revenueWithoutDiscount = rs.getBigDecimal("revenue_without_discount");

            // transaction count not available in this schema, set to 0 for now
            psd.numberOfTransactions = 0;

            // calculate discount amount
            psd.discountAmount = psd.revenueWithoutDiscount.subtract(psd.totalRevenue);

            productSalesList.add(psd);

            totalProductsSold += psd.totalQuantitySold;
            if (psd.totalQuantitySold > 0) {
                totalUniqueProducts++;
            } else {
                productsWithoutSales++;
            }

            if (psd.discount.compareTo(BigDecimal.ZERO) > 0 && psd.totalQuantitySold > 0) {
                productsWithDiscount++;
                totalDiscountGiven = totalDiscountGiven.add(psd.discountAmount);
            }
        }

        rs.close();
        stmt.close();
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    ;
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Reports - Syops Retail Shop</title>
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

            .page-title {
                text-align: center;
                margin-bottom: 2rem;
                color: #2c3e50;
                font-size: 2.5rem;
                font-weight: 700;
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

            .report-section {
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
                margin-bottom: 2rem;
                color: #2c3e50;
                font-size: 2rem;
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

            .section-title.overall::after {
                background: linear-gradient(135deg, #8e44ad, #9b59b6);
            }

            .section-title.instore::after {
                background: linear-gradient(135deg, #27ae60, #2ecc71);
            }

            .section-title.online::after {
                background: linear-gradient(135deg, #e67e22, #f39c12);
            }

            .section-title.product::after {
                background: linear-gradient(135deg, #e91e63, #f44336);
            }

            .stats-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
                margin-bottom: 2rem;
            }

            .stat-card {
                background: white;
                padding: 2rem;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                text-align: center;
                border: 1px solid rgba(255,255,255,0.2);
                transition: all 0.3s ease;
            }

            .stat-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 10px 25px rgba(0,0,0,0.15);
            }

            .stat-icon {
                font-size: 2.5rem;
                margin-bottom: 1rem;
            }

            .stat-number {
                font-size: 2.2rem;
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 0.5rem;
            }

            .stat-label {
                color: #7f8c8d;
                font-size: 0.95rem;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                font-weight: 600;
            }

            .stat-card.total-bills {
                border-top: 4px solid #3498db;
            }

            .stat-card.total-revenue {
                border-top: 4px solid #e74c3c;
            }

            .stat-card.average-bill {
                border-top: 4px solid #27ae60;
            }

            .stat-card.products-sold {
                border-top: 4px solid #9b59b6;
            }

            .stat-card.unique-products {
                border-top: 4px solid #e91e63;
            }

            .stat-card.discount-given {
                border-top: 4px solid #ff9800;
            }

            .stat-card.no-sales {
                border-top: 4px solid #607d8b;
            }

            .bills-table-container {
                overflow-x: auto;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            }

            .bills-table {
                width: 100%;
                border-collapse: collapse;
                background: white;
            }

            .bills-table thead {
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white;
            }

            .bills-table th {
                padding: 1.2rem;
                text-align: left;
                font-weight: 600;
                text-transform: uppercase;
                font-size: 0.85rem;
                letter-spacing: 0.5px;
            }

            .bills-table td {
                padding: 1rem 1.2rem;
                border-bottom: 1px solid #e2e8f0;
            }

            .bills-table tbody tr {
                transition: all 0.2s ease;
            }

            .bills-table tbody tr:hover {
                background-color: #f8f9fa;
                transform: scale(1.01);
            }

            .bill-id {
                font-family: monospace;
                color: #3498db;
                font-weight: 600;
            }

            .product-code {
                font-family: monospace;
                color: #9b59b6;
                font-weight: 600;
            }

            .bill-type-badge {
                display: inline-block;
                padding: 0.4rem 0.8rem;
                border-radius: 20px;
                font-size: 0.85rem;
                font-weight: 600;
            }

            .bill-type-badge.instore {
                background: rgba(39, 174, 96, 0.2);
                color: #27ae60;
                border: 2px solid #27ae60;
            }

            .bill-type-badge.online {
                background: rgba(230, 126, 34, 0.2);
                color: #e67e22;
                border: 2px solid #e67e22;
            }

            .best-seller-badge {
                display: inline-block;
                padding: 0.3rem 0.6rem;
                border-radius: 15px;
                font-size: 0.75rem;
                font-weight: 700;
                background: linear-gradient(135deg, #ffd700, #ffed4e);
                color: #b8860b;
                border: 2px solid #daa520;
            }

            .amount-cell {
                color: #e74c3c;
                font-weight: 700;
                font-size: 1.1rem;
            }

            .username-cell {
                color: #2c3e50;
                font-weight: 600;
            }

            .no-data {
                text-align: center;
                color: #7f8c8d;
                padding: 3rem;
                font-style: italic;
                font-size: 1.1rem;
                background-color: #f8f9fa;
                border-radius: 10px;
                border: 2px dashed #dee2e6;
            }

            .view-details-btn {
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white;
                border: none;
                padding: 0.5rem 1rem;
                border-radius: 8px;
                cursor: pointer;
                font-size: 0.9rem;
                font-weight: 600;
                transition: all 0.3s ease;
                text-decoration: none;
                display: inline-block;
            }

            .view-details-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4);
            }

            .discount-badge {
                display: inline-block;
                padding: 0.3rem 0.6rem;
                border-radius: 12px;
                font-size: 0.8rem;
                font-weight: 600;
                background: rgba(255, 152, 0, 0.2);
                color: #ff9800;
                border: 1px solid #ff9800;
            }

            @media (max-width: 768px) {
                .container {
                    padding: 0 0.5rem;
                }

                .report-section {
                    padding: 1.5rem;
                }

                .stats-grid {
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

                .bills-table {
                    font-size: 0.85rem;
                }

                .bills-table th,
                .bills-table td {
                    padding: 0.8rem;
                }
            }
        </style>
    </head>

    <body>
        <!-- Header Section -->
        <div class="header">
            <a href="admin.jsp" class="logo">Syops Admin</a>
            <div class="nav-options">
                <% if (username != null && !username.trim().isEmpty()) {%>
                <span class="username-display"><%= username%></span>
                <% }%>
                <a href="admin.jsp" class="nav-btn">Dashboard</a>
                <a href="allProducts.jsp" class="nav-btn">All products</a>

                <a href="adminBillDetails.jsp" class="nav-btn">Bill Details</a>
                <a href="reports.jsp" class="nav-btn">Reports</a>
                <a href="login.jsp" class="nav-btn">Logout</a>
            </div>
        </div>

        <!-- Main Content -->
        <div class="container">
            <h1 class="page-title">📊 Admin Reports</h1>

            <!-- Error Message -->
            <% if (errorMessage != null) {%>
            <div class="error-message">
                <%= errorMessage%>
            </div>
            <% }%>

            <!-- Product Sales Report -->
            <div class="report-section">
                <h2 class="section-title product">Product Sales Report</h2>

                <div class="stats-grid">
                    <div class="stat-card products-sold">
                        <div class="stat-icon">📦</div>
                        <div class="stat-number"><%= totalProductsSold%></div>
                        <div class="stat-label">Total Products Sold</div>
                    </div>
                    <div class="stat-card unique-products">
                        <div class="stat-icon">🏷️</div>
                        <div class="stat-number"><%= totalUniqueProducts%></div>
                        <div class="stat-label">Products with Sales</div>
                    </div>
                    <div class="stat-card discount-given">
                        <div class="stat-icon">🎁</div>
                        <div class="stat-number">Rs <%= totalDiscountGiven.setScale(2, BigDecimal.ROUND_HALF_UP).toString()%></div>
                        <div class="stat-label">Total Discount Given</div>
                    </div>

                </div>

                <div class="bills-table-container">
                    <% if (productSalesList.isEmpty()) { %>
                    <div class="no-data">
                        No product data available.
                    </div>
                    <% } else { %>
                    <table class="bills-table">
                        <thead>
                            <tr>
                                <th>Product Code</th>
                                <th>Product Name</th>
                                <th>Qty Sold</th>
                                <th>Unit Price</th>
                                <th>Discount</th>
                                <th>Revenue</th>
                                <th>Discount Amt</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                int rank = 1;
                                for (ProductSalesData psd : productSalesList) {
                            %>
                            <tr>

                                <td class="product-code"><%= psd.productCode%></td>
                                <td class="username-cell"><%= psd.productName%></td>
                                <td style="text-align: center; font-weight: 600; color: #9b59b6;"><%= psd.totalQuantitySold%></td>
                                <td class="amount-cell">Rs <%= psd.unitPrice.toString()%></td>
                                <td style="text-align: center;">
                                    <% if (psd.discount.compareTo(BigDecimal.ZERO) > 0) {%>
                                    <span class="discount-badge"><%= psd.discount%>%</span>
                                    <% } else { %>
                                    <span style="color: #95a5a6;">-</span>
                                    <% }%>
                                </td>
                                <td class="amount-cell">Rs <%= psd.totalRevenue.setScale(2, BigDecimal.ROUND_HALF_UP).toString()%></td>
                                <td style="color: #ff9800; font-weight: 600;">Rs <%= psd.discountAmount.setScale(2, BigDecimal.ROUND_HALF_UP).toString()%></td>
                            </tr>
                            <%
                                    rank++;
                                }
                            %>
                        </tbody>
                    </table>
                    <% }%>
                </div>
            </div>

            <!-- Overall Bill Report -->
            <div class="report-section">
                <h2 class="section-title overall">Overall Bill Report</h2>

                <div class="stats-grid">
                    <div class="stat-card total-bills">
                        <div class="stat-icon">📋</div>
                        <div class="stat-number"><%= overallCount%></div>
                        <div class="stat-label">Total Bills</div>
                    </div>
                    <div class="stat-card total-revenue">
                        <div class="stat-icon">💰</div>
                        <div class="stat-number">Rs <%= overallRevenue.toString()%></div>
                        <div class="stat-label">Total Revenue</div>
                    </div>
                    <div class="stat-card average-bill">
                        <div class="stat-icon">📊</div>
                        <div class="stat-number">Rs <%= overallAverage.toString()%></div>
                        <div class="stat-label">Average Bill Amount</div>
                    </div>
                </div>

                <div class="bills-table-container">
                    <% if (allBills.isEmpty()) { %>
                    <div class="no-data">
                        No bills available. Bills will appear here once customers make purchases.
                    </div>
                    <% } else { %>
                    <table class="bills-table">
                        <thead>
                            <tr>
                                <th>Bill ID</th>
                                <th>Username</th>
                                <th>Bill Type</th>
                                <th>Amount</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Bill bill : allBills) {%>
                            <tr>
                                <td class="bill-id">BILL<%= bill.getBillId()%></td>
                                <td class="username-cell"><%= bill.getUsername()%></td>
                                <td>
                                    <span class="bill-type-badge <%= bill.getBillType().equalsIgnoreCase("IN-STORE") ? "instore" : "online"%>">
                                        <%= bill.getBillType()%>
                                    </span>
                                </td>
                                <td class="amount-cell">Rs <%= bill.getAmount().toString()%></td>
                                <td>
                                    <a href="adminBillDetails.jsp" class="view-details-btn">View Details</a>
                                </td>
                            </tr>
                            <% }%>
                        </tbody>
                    </table>
                    <% }%>
                </div>
            </div>

            <!-- In-Store Bill Report -->
            <div class="report-section">
                <h2 class="section-title instore">In-Store Bill Report</h2>

                <div class="stats-grid">
                    <div class="stat-card total-bills">
                        <div class="stat-icon">🏪</div>
                        <div class="stat-number"><%= inStoreCount%></div>
                        <div class="stat-label">In-Store Bills</div>
                    </div>
                    <div class="stat-card total-revenue">
                        <div class="stat-icon">💵</div>
                        <div class="stat-number">Rs <%= inStoreRevenue.toString()%></div>
                        <div class="stat-label">In-Store Revenue</div>
                    </div>
                    <div class="stat-card average-bill">
                        <div class="stat-icon">📈</div>
                        <div class="stat-number">Rs <%= inStoreAverage.toString()%></div>
                        <div class="stat-label">Average In-Store Bill</div>
                    </div>
                </div>

                <div class="bills-table-container">
                    <% if (inStoreBills.isEmpty()) { %>
                    <div class="no-data">
                        No in-store bills available yet.
                    </div>
                    <% } else { %>
                    <table class="bills-table">
                        <thead>
                            <tr>
                                <th>Bill ID</th>
                                <th>Username</th>
                                <th>Bill Type</th>
                                <th>Cash Tendered</th>
                                <th>Change Amount</th>
                                <th>Sub Total</th>

                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Bill bill : inStoreBills) {%>
                            <tr>
                                <td class="bill-id">BILL<%= bill.getBillId()%></td>
                                <td class="username-cell"><%= bill.getUsername()%></td>
                                <td>
                                    <span class="bill-type-badge instore">
                                        <%= bill.getBillType()%>
                                    </span>
                                </td>
                                <td class="amount-cell">Rs <%= bill.getCashTendered().toString()%></td>
                                <td class="amount-cell">Rs <%= bill.getChangeAmount().toString()%></td>
                                <td class="amount-cell">Rs <%= bill.getAmount().toString()%></td>

                                <td>
                                    <a href="adminBillDetails.jsp" class="view-details-btn">View Details</a>
                                </td>
                            </tr>
                            <% }%>
                        </tbody>
                    </table>
                    <% }%>
                </div>
            </div>

            <!-- Online Bill Report -->
            <div class="report-section">
                <h2 class="section-title online">Online Bill Report</h2>

                <div class="stats-grid">
                    <div class="stat-card total-bills">
                        <div class="stat-icon">🌐</div>
                        <div class="stat-number"><%= onlineCount%></div>
                        <div class="stat-label">Online Bills</div>
                    </div>
                    <div class="stat-card total-revenue">
                        <div class="stat-icon">💳</div>
                        <div class="stat-number">Rs <%= onlineRevenue.toString()%></div>
                        <div class="stat-label">Online Revenue</div>
                    </div>
                    <div class="stat-card average-bill">
                        <div class="stat-icon">📊</div>
                        <div class="stat-number">Rs <%= onlineAverage.toString()%></div>
                        <div class="stat-label">Average Online Bill</div>
                    </div>
                </div>

                <div class="bills-table-container">
                    <% if (onlineBills.isEmpty()) { %>
                    <div class="no-data">
                        No online bills available yet.
                    </div>
                    <% } else { %>
                    <table class="bills-table">
                        <thead>
                            <tr>
                                <th>Bill ID</th>
                                <th>Username</th>
                                <th>Bill Type</th>
                                <th>Amount</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Bill bill : onlineBills) {%>
                            <tr>
                                <td class="bill-id">BILL<%= bill.getBillId()%></td>
                                <td class="username-cell"><%= bill.getUsername()%></td>
                                <td>
                                    <span class="bill-type-badge online">
                                        <%= bill.getBillType()%>
                                    </span>
                                </td>
                                <td class="amount-cell">Rs <%= bill.getAmount().toString()%></td>
                                <td>
                                    <a href="adminBillDetails.jsp" class="view-details-btn">View Details</a>
                                </td>
                            </tr>
                            <% }%>
                        </tbody>
                    </table>
                    <% }%>
                </div>
            </div>
        </div>

        <script>
            document.addEventListener('DOMContentLoaded', function () {
                // Auto-hide error messages after 5 seconds
                const messages = document.querySelectorAll('.error-message');
                messages.forEach(message => {
                    setTimeout(() => {
                        message.style.opacity = '0';
                        setTimeout(() => {
                            message.remove();
                        }, 300);
                    }, 5000);
                });

                // Add smooth scroll animation to sections
                const observer = new IntersectionObserver((entries) => {
                    entries.forEach(entry => {
                        if (entry.isIntersecting) {
                            entry.target.style.opacity = '1';
                            entry.target.style.transform = 'translateY(0)';
                        }
                    });
                }, {
                    threshold: 0.1
                });

                document.querySelectorAll('.report-section').forEach(section => {
                    section.style.opacity = '0';
                    section.style.transform = 'translateY(20px)';
                    section.style.transition = 'all 0.5s ease';
                    observer.observe(section);
                });
            });
        </script>
    </body>
</html>