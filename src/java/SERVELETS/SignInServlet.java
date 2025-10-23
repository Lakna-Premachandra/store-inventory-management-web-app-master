package SERVELETS;

import MODELS.User;
import SERVICES.AuthService;
import UTILS.LocalDateTimeAdapter;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.time.LocalDateTime;
import java.util.logging.Logger;

/**
 * Servlet for handling user authentication/sign in
 */
@WebServlet("/SignInServlet")
public class SignInServlet extends HttpServlet {
    
    private static final Logger LOGGER = Logger.getLogger(SignInServlet.class.getName());
    
    private AuthService authService;
    private Gson gson;
    
    /**
     * Initialize servlet with required services
     */
    @Override
    public void init() throws ServletException {
        try {
            authService = new AuthService();
            gson = new GsonBuilder()
                    .registerTypeAdapter(LocalDateTime.class, new LocalDateTimeAdapter())
                    .setPrettyPrinting()
                    .create();
            
            LOGGER.info("SignInServlet initialized successfully");
        } catch (Exception e) {
            LOGGER.severe("Failed to initialize SignInServlet: " + e.getMessage());
            throw new ServletException("Servlet initialization failed", e);
        }
    }
    
    /**
     * Handle POST requests for user authentication
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String contentType = request.getContentType();
        
        // Check if it's JSON request
        if (contentType != null && contentType.contains("application/json")) {
            handleJsonSignIn(request, response);
        } else {
            // Handle form submission (traditional form)
            handleFormSignIn(request, response);
        }
    }
    
    /**
     * Handle JSON-based sign in
     */
    private void handleJsonSignIn(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        
        // Set response headers for JSON
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        
        PrintWriter out = response.getWriter();
        
        LOGGER.info("Processing JSON sign in request");
        
        try {
            // Read and parse request body
            String jsonBody = readRequestBody(request);
            if (jsonBody == null || jsonBody.trim().isEmpty()) {
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    "Request body is required");
                return;
            }
            
            // Parse JSON to get credentials
            SignInRequest signInRequest;
            try {
                signInRequest = gson.fromJson(jsonBody, SignInRequest.class);
            } catch (JsonSyntaxException e) {
                LOGGER.warning("Invalid JSON in sign in request: " + e.getMessage());
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    "Invalid JSON format");
                return;
            }
            
            if (signInRequest == null) {
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    "Credentials are required");
                return;
            }
            
            // Process sign in
            AuthService.AuthResult result = authService.signIn(
                signInRequest.getUsername(), 
                signInRequest.getPassword()
            );
            
            if (result.isSuccess()) {
                LOGGER.info("JSON Sign in successful for user: " + signInRequest.getUsername());
                response.setStatus(HttpServletResponse.SC_OK);
                
                SignInResponse signInResponse = new SignInResponse(
                    true, result.getMessage(), result.getUser()
                );
                out.print(gson.toJson(signInResponse));
            } else {
                LOGGER.warning("JSON Sign in failed for user: " + signInRequest.getUsername() + 
                    " - " + result.getMessage());
                
                int statusCode = result.getMessage().contains("Invalid username or password") ? 
                    HttpServletResponse.SC_UNAUTHORIZED : HttpServletResponse.SC_BAD_REQUEST;
                
                sendJsonErrorResponse(response, out, statusCode, result.getMessage());
            }
            
        } catch (Exception e) {
            LOGGER.severe("Error processing JSON sign in: " + e.getMessage());
            sendJsonErrorResponse(response, out, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                "Failed to process sign in request");
        } finally {
            if (out != null) {
                out.close();
            }
        }
    }
    
    /**
     * Handle traditional form-based sign in
     */
    private void handleFormSignIn(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        LOGGER.info("Processing form sign in request");
        
        try {
            String username = request.getParameter("username");
            String password = request.getParameter("password");
            boolean rememberMe = request.getParameter("remember") != null;
            
            // Validate input
            if (isEmpty(username) || isEmpty(password)) {
                redirectWithError(request, response, "Username and password are required", username);
                return;
            }
            
            // Process sign in
            AuthService.AuthResult result = authService.signIn(username, password);
            
            if (result.isSuccess()) {
                LOGGER.info("Form Sign in successful for user: " + username);
                
                // Create session
                HttpSession session = request.getSession();
                session.setAttribute("user", result.getUser());
                // MODIFICATION: Store username separately for easy access in JSP
                session.setAttribute("loggedInUsername", result.getUser().getUsername());
                session.setAttribute("role", result.getUser().getRole());
                
                // Set session timeout if remember me is checked
                if (rememberMe) {
                    session.setMaxInactiveInterval(7 * 24 * 60 * 60); // 7 days
                }
                
                // Redirect based on user role
                String userRole = result.getUser().getRole();
                if ("ADMIN".equalsIgnoreCase(userRole)) {
                    response.sendRedirect(request.getContextPath() + "/UI/admin.jsp");
                } else if ("".equalsIgnoreCase(userRole)) {
                    response.sendRedirect(request.getContextPath() + "/UI/main.jsp");
                } else {
                    // CUSTOMER or default
                    response.sendRedirect(request.getContextPath() + "/UI/main.jsp");
                }
                
            } else {
                LOGGER.warning("Form Sign in failed for user: " + username + " - " + result.getMessage());
                redirectWithError(request, response, result.getMessage(), username);
            }
            
        } catch (Exception e) {
            LOGGER.severe("Error processing form sign in: " + e.getMessage());
            redirectWithError(request, response, "An error occurred during login. Please try again.", null);
        }
    }
    
    /**
     * Handle OPTIONS requests for CORS preflight
     */
    @Override
    protected void doOptions(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        response.setStatus(HttpServletResponse.SC_OK);
    }
    
    // Helper methods
    
    private String readRequestBody(HttpServletRequest request) throws IOException {
        StringBuilder jsonBuffer = new StringBuilder();
        
        try (BufferedReader reader = request.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                jsonBuffer.append(line);
            }
        }
        
        return jsonBuffer.toString();
    }
    
    private void sendJsonErrorResponse(HttpServletResponse response, PrintWriter out, 
                                     int statusCode, String message) {
        response.setStatus(statusCode);
        ErrorResponse errorResponse = new ErrorResponse(false, message);
        out.print(gson.toJson(errorResponse));
    }
    
    private void redirectWithError(HttpServletRequest request, HttpServletResponse response, 
                                  String errorMessage, String lastUsername) throws IOException {
        HttpSession session = request.getSession();
        session.setAttribute("errorMessage", errorMessage);
        if (lastUsername != null) {
            session.setAttribute("lastUsername", lastUsername);
        }
        
        String encodedMessage = URLEncoder.encode(errorMessage, "UTF-8");
        response.sendRedirect(request.getContextPath() + "/UI/login.jsp?errorMessage=" + encodedMessage);
    }
    
    private boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    @Override
    public void destroy() {
        LOGGER.info("SignInServlet destroyed");
        super.destroy();
    }
    
    // ===== Inner Classes for Request/Response DTOs =====
    
    private static class SignInRequest {
        private String username;
        private String password;
        
        public SignInRequest() {}
        
        public String getUsername() { 
            return username; 
        }
        
        public void setUsername(String username) { 
            this.username = username; 
        }
        
        public String getPassword() { 
            return password; 
        }
        
        public void setPassword(String password) { 
            this.password = password; 
        }
        
        @Override
        public String toString() {
            return "SignInRequest{username='" + username + "'}"; // Don't log password
        }
    }
    
    private static class SignInResponse {
        private boolean success;
        private String message;
        private User user;
        
        public SignInResponse(boolean success, String message, User user) {
            this.success = success;
            this.message = message;
            this.user = user;
        }
        
        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }
        public User getUser() { return user; }
    }
    
    private static class ErrorResponse {
        private boolean success;
        private String message;
        
        public ErrorResponse(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
        
        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }
    }
}