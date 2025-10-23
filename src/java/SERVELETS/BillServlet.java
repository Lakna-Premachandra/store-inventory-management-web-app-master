package SERVELETS;

import MODELS.Bill;
import SERVICES.BillService;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.List;

@WebServlet("/BillServlet/*")
public class BillServlet extends HttpServlet {
    private BillService billService;
    private Gson gson;
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    @Override
    public void init() throws ServletException {
        billService = new BillService();
        gson = new GsonBuilder()
                .setPrettyPrinting()
                .setDateFormat("yyyy-MM-dd HH:mm:ss")
                .create();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        String pathInfo = req.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                handleGetAllBills(req, resp, out);
                
            } else {
                String[] pathParts = pathInfo.substring(1).split("/");
                
                if (pathParts.length == 1) {
                    String firstPart = pathParts[0];
                    
                    if ("statistics".equals(firstPart)) {
                        BillService.BillStatistics stats = billService.getBillStatistics();
                        out.print(gson.toJson(stats));
                        
                    } else if (firstPart.matches("\\d+")) {
                        int billId = Integer.parseInt(firstPart);
                        Bill bill = billService.getBillById(billId);
                        
                        if (bill != null) {
                            out.print(gson.toJson(bill));
                        } else {
                            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                            out.print("{\"error\":\"Bill not found\"}");
                        }
                        
                    } else {
                        String username = firstPart;
                        List<Bill> bills = billService.getBillsByUsername(username);
                        
                        if (bills != null) {
                            out.print(gson.toJson(bills));
                        } else {
                            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                            out.print("{\"error\":\"Invalid username\"}");
                        }
                    }
                    
                } else if (pathParts.length == 2) {
                    String firstPart = pathParts[0];
                    String secondPart = pathParts[1];
                    
                    if ("user".equals(firstPart)) {
                        if ("total".equals(secondPart)) {
                            String username = req.getParameter("username");
                            if (username != null && !username.trim().isEmpty()) {
                                BigDecimal total = billService.getTotalAmountByUsername(username);
                                JsonObject response = new JsonObject();
                                response.addProperty("username", username);
                                response.addProperty("totalAmount", total);
                                out.print(gson.toJson(response));
                            } else {
                                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                                out.print("{\"error\":\"Username parameter is required\"}");
                            }
                        }
                    } else if ("type".equals(firstPart)) {
                        String billType = secondPart;
                        List<Bill> bills = billService.getBillsByType(billType);
                        
                        if (bills != null) {
                            out.print(gson.toJson(bills));
                        } else {
                            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                            out.print("{\"error\":\"Invalid bill type\"}");
                        }
                    }
                    
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Invalid URL format\"}");
                }
            }
        } catch (NumberFormatException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Invalid number format\"}");
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();

        try {
            StringBuilder sb = new StringBuilder();
            BufferedReader reader = req.getReader();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            String requestBody = sb.toString();

            if (requestBody.trim().isEmpty()) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Request body is required\"}");
                return;
            }

            JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();
            
            if (!jsonBody.has("amount") || !jsonBody.has("username") || !jsonBody.has("billType")) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Required fields: amount, username, billType\"}");
                return;
            }
            
            BigDecimal amount = jsonBody.get("amount").getAsBigDecimal();
            String username = jsonBody.get("username").getAsString();
            String billType = jsonBody.get("billType").getAsString();
            
            // Get cash tendered if present (for INSTORE bills)
            BigDecimal cashTendered = null;
            if (jsonBody.has("cashTendered")) {
                cashTendered = jsonBody.get("cashTendered").getAsBigDecimal();
            }

            boolean success = billService.createBill(amount, username, billType, cashTendered);
            
            if (success) {
                resp.setStatus(HttpServletResponse.SC_CREATED);
                JsonObject response = new JsonObject();
                response.addProperty("success", true);
                response.addProperty("message", "Bill created successfully");
                
                // Add cash details if present
                if (cashTendered != null) {
                    response.addProperty("cashTendered", cashTendered);
                    BigDecimal change = cashTendered.subtract(amount);
                    response.addProperty("changeAmount", change);
                }
                
                out.print(gson.toJson(response));
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"success\":false,\"message\":\"Failed to create bill. Check if user exists and bill type matches user role (CUSTOMER=ONLINE, ADMIN=INSTORE)\"}");
            }

        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }

    private void handleGetAllBills(HttpServletRequest req, HttpServletResponse resp, PrintWriter out) throws IOException {
        String username = req.getParameter("username");
        String billType = req.getParameter("billType");
        String startDate = req.getParameter("startDate");
        String endDate = req.getParameter("endDate");

        try {
            List<Bill> bills;

            if (startDate != null && endDate != null) {
                Timestamp start = new Timestamp(DATE_FORMAT.parse(startDate).getTime());
                Timestamp end = new Timestamp(DATE_FORMAT.parse(endDate).getTime());
                bills = billService.getBillsByDateRange(start, end);
                
            } else if (username != null && !username.trim().isEmpty()) {
                bills = billService.getBillsByUsername(username);
                
            } else if (billType != null && !billType.trim().isEmpty()) {
                bills = billService.getBillsByType(billType);
                
            } else {
                bills = billService.getAllBills();
            }

            if (bills != null) {
                out.print(gson.toJson(bills));
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Invalid parameters\"}");
            }
            
        } catch (ParseException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Invalid date format. Use yyyy-MM-dd HH:mm:ss\"}");
        }
    }
}