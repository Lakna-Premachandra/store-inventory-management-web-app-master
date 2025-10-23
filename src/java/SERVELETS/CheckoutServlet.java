package SERVELETS;

import SERVICES.CheckoutService;
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

@WebServlet("/CheckoutServlet")
public class CheckoutServlet extends HttpServlet {
    private CheckoutService checkoutService;
    private Gson gson;

    @Override
    public void init() throws ServletException {
        checkoutService = new CheckoutService();
        gson = new GsonBuilder().setPrettyPrinting().create();
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
            
            if (!jsonBody.has("username")) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Username is required\"}");
                return;
            }
            
            String username = jsonBody.get("username").getAsString();
            
            // Get cash tendered if present (for INSTORE bills)
            BigDecimal cashTendered = null;
            if (jsonBody.has("cashTendered")) {
                cashTendered = jsonBody.get("cashTendered").getAsBigDecimal();
            }
            
            CheckoutService.CheckoutResult result = checkoutService.processCheckout(username, cashTendered);
            
            if (result.isSuccess()) {
                resp.setStatus(HttpServletResponse.SC_CREATED);
                
                // Create response JSON with all details
                JsonObject response = new JsonObject();
                response.addProperty("success", true);
                response.addProperty("message", result.getMessage());
                response.addProperty("billId", result.getBillId());
                response.addProperty("amount", result.getTotalAmount());
                response.addProperty("billType", result.getBillType());
                
                // Add cash tendered and change if present
                if (result.getCashTendered() != null) {
                    response.addProperty("cashTendered", result.getCashTendered());
                }
                if (result.getChangeAmount() != null) {
                    response.addProperty("changeAmount", result.getChangeAmount());
                }
                
                out.print(gson.toJson(response));
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print(gson.toJson(result));
            }

        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }
}