package SERVELETS;

import MODELS.StoreInventory;
import SERVICES.StoreInventoryService;
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
import java.util.List;

@WebServlet("/StoreInventoryServlet/*")
public class StoreInventoryServlet extends HttpServlet {
    private StoreInventoryService inventoryService;
    private Gson gson;

    @Override
    public void init() throws ServletException {
        inventoryService = new StoreInventoryService();
        gson = new GsonBuilder().setPrettyPrinting().create();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        String pathInfo = req.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                // GET /api/inventory - Get all inventory
                List<StoreInventory> inventoryList = inventoryService.getAllInventory();
                out.print(gson.toJson(inventoryList));
            } else {
                String productCode = pathInfo.substring(1);
                
                if (productCode.contains("/")) {
                    String[] parts = productCode.split("/");
                    productCode = parts[0];
                    String action = parts[1];
                    
                    if ("stock".equals(action)) {
                        // GET /api/inventory/{code}/stock
                        int stockLevel = inventoryService.getStockLevel(productCode);
                        JsonObject response = new JsonObject();
                        response.addProperty("productCode", productCode);
                        response.addProperty("stockLevel", stockLevel);
                        out.print(gson.toJson(response));
                        return;
                    }
                }
                
                // GET /api/inventory/{code}
                StoreInventory inventory = inventoryService.getInventoryByCode(productCode);
                if (inventory != null) {
                    out.print(gson.toJson(inventory));
                } else {
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    out.print("{\"error\":\"Inventory not found for product: " + productCode + "\"}");
                }
            }
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
        String pathInfo = req.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                // POST /api/inventory - Add new inventory
                StoreInventory inventory = gson.fromJson(req.getReader(), StoreInventory.class);
                boolean success = inventoryService.addInventory(inventory);

                if (success) {
                    resp.setStatus(HttpServletResponse.SC_CREATED);
                    out.print("{\"success\":true,\"message\":\"Inventory added successfully\"}");
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"success\":false,\"message\":\"Failed to add inventory\"}");
                }
            } else {
                String productCode = pathInfo.substring(1);
                
                if (productCode.contains("/")) {
                    String[] parts = productCode.split("/");
                    productCode = parts[0];
                    String action = parts[1];
                    
                    // Read request body
                    StringBuilder sb = new StringBuilder();
                    BufferedReader reader = req.getReader();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        sb.append(line);
                    }
                    String requestBody = sb.toString();
                    JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();
                    
                    boolean success = false;
                    String message = "";
                    
                    switch (action) {
                        case "add-stock":
                            int quantityToAdd = jsonBody.get("quantity").getAsInt();
                            success = inventoryService.addStock(productCode, quantityToAdd);
                            message = success ? "Stock added successfully" : "Failed to add stock";
                            break;
                            
                        case "reduce-stock":
                            int quantityToReduce = jsonBody.get("quantity").getAsInt();
                            success = inventoryService.reduceStock(productCode, quantityToReduce);
                            message = success ? "Stock reduced successfully" : "Failed to reduce stock";
                            break;
                            
                        default:
                            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                            out.print("{\"error\":\"Invalid action: " + action + "\"}");
                            return;
                    }
                    
                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_OK);
                        out.print("{\"success\":true,\"message\":\"" + message + "\"}");
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"" + message + "\"}");
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Invalid endpoint\"}");
                }
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        String pathInfo = req.getPathInfo();

        try {
            if (pathInfo != null && pathInfo.length() > 1) {
                String productCode = pathInfo.substring(1);

                StoreInventory inventory = gson.fromJson(req.getReader(), StoreInventory.class);
                inventory.setProductCode(productCode);

                boolean success = inventoryService.updateInventory(inventory);
                if (success) {
                    resp.setStatus(HttpServletResponse.SC_OK);
                    out.print("{\"success\":true,\"message\":\"Inventory updated successfully\"}");
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"success\":false,\"message\":\"Failed to update inventory\"}");
                }
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Product code required in URL\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        String pathInfo = req.getPathInfo();

        try {
            if (pathInfo != null && pathInfo.length() > 1) {
                String productCode = pathInfo.substring(1);

                boolean success = inventoryService.deleteInventory(productCode);
                if (success) {
                    resp.setStatus(HttpServletResponse.SC_OK);
                    out.print("{\"success\":true,\"message\":\"Inventory deleted successfully\"}");
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"success\":false,\"message\":\"Failed to delete inventory\"}");
                }
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Product code required in URL\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }
}