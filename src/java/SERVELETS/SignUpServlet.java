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
 * Servlet for handling user registration/sign up
 */
@WebServlet("/SignUpServlet")
public class SignUpServlet extends HttpServlet {
    
    private static final Logger LOGGER = Logger.getLogger(SignUpServlet.class.getName());
    
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
            
            LOGGER.info("SignUpServlet initialized successfully");
        } catch (Exception e) {
            LOGGER.severe("Failed to initialize SignUpServlet: " + e.getMessage());
            throw new ServletException("Servlet initialization failed", e);
        }
    }
    
    /**
     * Handle POST requests for user registration
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String contentType = request.getContentType();
        
        // Check if it's JSON request (from your register.jsp)
        if (contentType != null && contentType.contains("application/json")) {
            handleJsonSignUp(request, response);
        } else {
            // Handle form submission (traditional form)
            handleFormSignUp(request, response);
        }
    }
    
    /**
     * Handle JSON-based sign up (from your register.jsp)
     */
    private void handleJsonSignUp(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        
        // Set response headers for JSON
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        
        PrintWriter out = response.getWriter();
        
        LOGGER.info("Processing JSON sign up request");
        
        try {
            // Read and parse request body
            String jsonBody = readRequestBody(request);
            if (jsonBody == null || jsonBody.trim().isEmpty()) {
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    "Request body is required");
                return;
            }
            
            // Parse JSON to User object
            User user;
            try {
                user = gson.fromJson(jsonBody, User.class);
            } catch (JsonSyntaxException e) {
                LOGGER.warning("Invalid JSON in sign up request: " + e.getMessage());
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    "Invalid JSON format");
                return;
            }
            
            if (user == null) {
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    "User data is required");
                return;
            }
            
            // Process sign up
            AuthService.AuthResult result = authService.signUp(user);
            
            if (result.isSuccess()) {
                LOGGER.info("JSON Sign up successful for user: " + user.getUsername());
                response.setStatus(HttpServletResponse.SC_CREATED);
                
                SignUpResponse signUpResponse = new SignUpResponse(
                    true, result.getMessage(), result.getUser()
                );
                out.print(gson.toJson(signUpResponse));
            } else {
                LOGGER.warning("JSON Sign up failed: " + result.getMessage());
                sendJsonErrorResponse(response, out, HttpServletResponse.SC_BAD_REQUEST, 
                    result.getMessage());
            }
            
        } catch (Exception e) {
            LOGGER.severe("Error processing JSON sign up: " + e.getMessage());
            sendJsonErrorResponse(response, out, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                "Failed to process sign up request");
        } finally {
            if (out != null) {
                out.close();
            }
        }
    }
    
    /**
     * Handle traditional form-based sign up
     */
    private void handleFormSignUp(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        LOGGER.info("Processing form sign up request");
        
        try {
            // Extract form parameters
            String fullName = request.getParameter("fullName");
            String email = request.getParameter("email");
            String username = request.getParameter("username");
            String password = request.getParameter("password");
            String role = request.getParameter("role");
            
            // Additional parameters from the cab booking form
            String customerName = request.getParameter("customername");
            String phoneNumber = request.getParameter("phoneNumber");
            String address = request.getParameter("address");
            String nic = request.getParameter("nic");
            
            // Validate required fields
            if (isEmpty(username) || isEmpty(password)) {
                redirectWithError(request, response, "Username and password are required");
                return;
            }
            
            // Create User object
            User user = new User();
            user.setUsername(username);
            user.setPassword(password);
            user.setEmail(email != null ? email : "");
            user.setFullName(fullName != null ? fullName : customerName != null ? customerName : "");
            user.setRole(role != null ? role : "CUSTOMER");
            
            // Process sign up
            AuthService.AuthResult result = authService.signUp(user);
            
            if (result.isSuccess()) {
                LOGGER.info("Form Sign up successful for user: " + username);
                
                // Create session and redirect to appropriate page
                HttpSession session = request.getSession();
                session.setAttribute("user", result.getUser());
                session.setAttribute("role", result.getUser().getRole());
                session.setAttribute("successMessage", "Account created successfully!");
                
                // Redirect based on user role
                if ("ADMIN".equalsIgnoreCase(result.getUser().getRole())) {
                    response.sendRedirect(request.getContextPath() + "/views/dashboard-layout/admin.jsp");
                } else {
                    response.sendRedirect(request.getContextPath() + "/UI/login.jsp");
                }
                
            } else {
                LOGGER.warning("Form Sign up failed: " + result.getMessage());
                redirectWithError(request, response, result.getMessage());
            }
            
        } catch (Exception e) {
            LOGGER.severe("Error processing form sign up: " + e.getMessage());
            redirectWithError(request, response, "An error occurred during registration. Please try again.");
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
                                  String errorMessage) throws IOException {
        HttpSession session = request.getSession();
        session.setAttribute("errorMessage", errorMessage);
        String encodedMessage = URLEncoder.encode(errorMessage, "UTF-8");
        response.sendRedirect(request.getContextPath() + "/views/auth-layout/sign-up/signUp.jsp?errorMessage=" + encodedMessage);
    }
    
    private boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    @Override
    public void destroy() {
        LOGGER.info("SignUpServlet destroyed");
        super.destroy();
    }
    
    // ===== Inner Classes for JSON Response DTOs =====
    
    private static class SignUpResponse {
        private boolean success;
        private String message;
        private User user;
        
        public SignUpResponse(boolean success, String message, User user) {
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