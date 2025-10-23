package SERVELETS;

import MODELS.Cart;
import SERVICES.CartService;
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

@WebServlet("/CartServlet/*")
public class CartServlet extends HttpServlet {
    private CartService cartService;
    private Gson gson;

    @Override
    public void init() throws ServletException {
        cartService = new CartService();
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
                // GET /CartServlet - Get username from parameter
                String username = req.getParameter("username");
                if (username == null || username.trim().isEmpty()) {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Username parameter is required\"}");
                    return;
                }

                List<Cart> cartItems = cartService.getCartItems(username);
                out.print(gson.toJson(cartItems));
                
            } else {
                String[] pathParts = pathInfo.substring(1).split("/");
                String username = pathParts[0];

                if (pathParts.length == 1) {
                    // GET /CartServlet/{username} - Get user's cart items
                    List<Cart> cartItems = cartService.getCartItems(username);
                    out.print(gson.toJson(cartItems));
                    
                } else if (pathParts.length == 2) {
                    String action = pathParts[1];
                    
                    if ("summary".equals(action)) {
                        // GET /CartServlet/{username}/summary - Get cart summary
                        CartService.CartSummary summary = cartService.getCartSummary(username);
                        if (summary != null) {
                            out.print(gson.toJson(summary));
                        } else {
                            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                            out.print("{\"error\":\"Cart not found\"}");
                        }
                    } else {
                        // GET /CartServlet/{username}/{productCode} - Get specific cart item
                        String productCode = action;
                        Cart cartItem = cartService.getCartItem(username, productCode);
                        if (cartItem != null) {
                            out.print(gson.toJson(cartItem));
                        } else {
                            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                            out.print("{\"error\":\"Cart item not found\"}");
                        }
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Invalid URL format\"}");
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
            // Read request body
            StringBuilder sb = new StringBuilder();
            BufferedReader reader = req.getReader();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            String requestBody = sb.toString();

            if (pathInfo == null || pathInfo.equals("/")) {
                // POST /CartServlet - Add item to cart
                JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();
                
                String username = jsonBody.get("username").getAsString();
                String productCode = jsonBody.get("productCode").getAsString();
                int quantity = jsonBody.get("quantity").getAsInt();

                boolean success = cartService.addToCart(username, productCode, quantity);
                
                if (success) {
                    resp.setStatus(HttpServletResponse.SC_CREATED);
                    out.print("{\"success\":true,\"message\":\"Item added to cart successfully\"}");
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"success\":false,\"message\":\"Failed to add item to cart\"}");
                }
                
            } else {
                String[] pathParts = pathInfo.substring(1).split("/");
                
                if (pathParts.length >= 2) {
                    String username = pathParts[0];
                    String action = pathParts[1];
                    
                    if ("clear".equals(action)) {
                        // POST /CartServlet/{username}/clear - Clear cart
                        boolean success = cartService.clearCart(username);
                        
                        if (success) {
                            resp.setStatus(HttpServletResponse.SC_OK);
                            out.print("{\"success\":true,\"message\":\"Cart cleared successfully\"}");
                        } else {
                            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                            out.print("{\"success\":false,\"message\":\"Failed to clear cart\"}");
                        }
                    } else {
                        // POST /CartServlet/{username}/{productCode} - Add specific product to cart
                        String productCode = action;
                        JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();
                        int quantity = jsonBody.get("quantity").getAsInt();

                        boolean success = cartService.addToCart(username, productCode, quantity);
                        
                        if (success) {
                            resp.setStatus(HttpServletResponse.SC_CREATED);
                            out.print("{\"success\":true,\"message\":\"Item added to cart successfully\"}");
                        } else {
                            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                            out.print("{\"success\":false,\"message\":\"Failed to add item to cart\"}");
                        }
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Invalid URL format\"}");
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
                String[] pathParts = pathInfo.substring(1).split("/");
                
                if (pathParts.length >= 2) {
                    String username = pathParts[0];
                    String productCode = pathParts[1];
                    
                    // Read request body
                    StringBuilder sb = new StringBuilder();
                    BufferedReader reader = req.getReader();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        sb.append(line);
                    }
                    String requestBody = sb.toString();
                    
                    JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();
                    int quantity = jsonBody.get("quantity").getAsInt();

                    boolean success = cartService.updateCartItem(username, productCode, quantity);
                    
                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_OK);
                        if (quantity == 0) {
                            out.print("{\"success\":true,\"message\":\"Item removed from cart successfully\"}");
                        } else {
                            out.print("{\"success\":true,\"message\":\"Cart item updated successfully\"}");
                        }
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"Failed to update cart item\"}");
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Username and product code required in URL\"}");
                }
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Invalid URL format\"}");
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
                String[] pathParts = pathInfo.substring(1).split("/");
                
                if (pathParts.length == 1) {
                    // DELETE /CartServlet/{username} - Clear entire cart
                    String username = pathParts[0];
                    boolean success = cartService.clearCart(username);
                    
                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_OK);
                        out.print("{\"success\":true,\"message\":\"Cart cleared successfully\"}");
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"Failed to clear cart\"}");
                    }
                    
                } else if (pathParts.length >= 2) {
                    // DELETE /CartServlet/{username}/{productCode} - Remove specific item
                    String username = pathParts[0];
                    String productCode = pathParts[1];
                    
                    boolean success = cartService.removeFromCart(username, productCode);
                    
                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_OK);
                        out.print("{\"success\":true,\"message\":\"Item removed from cart successfully\"}");
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"Failed to remove item from cart\"}");
                    }
                } else {
                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Invalid URL format\"}");
                }
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Username required in URL\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Internal server error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }
}