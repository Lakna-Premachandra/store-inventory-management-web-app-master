<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Register - Create Account</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }

            .register-container {
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
                padding: 40px;
                width: 100%;
                max-width: 480px;
                position: relative;
                overflow: hidden;
            }

            .register-container::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                height: 4px;
                background: linear-gradient(90deg, #667eea, #764ba2, #667eea);
                background-size: 200% 100%;
                animation: shimmer 3s ease-in-out infinite;
            }



            .register-header {
                text-align: center;
                margin-bottom: 30px;
            }

            .register-title {
                font-size: 28px;
                font-weight: 700;
                color: #2d3748;
                margin-bottom: 8px;
            }

            .register-subtitle {
                color: #718096;
                font-size: 16px;
            }

            .form-group {
                margin-bottom: 24px;
                position: relative;
            }

            .form-label {
                display: block;
                margin-bottom: 8px;
                font-weight: 600;
                color: #4a5568;
                font-size: 14px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .form-input, .form-select {
                width: 100%;
                padding: 16px 20px;
                border: 2px solid #e2e8f0;
                border-radius: 12px;
                font-size: 16px;
                transition: all 0.3s ease;
                background: #f7fafc;
            }

            .form-input:focus, .form-select:focus {
                outline: none;
                border-color: #667eea;
                background: white;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
                transform: translateY(-2px);
            }

            .form-input:hover, .form-select:hover {
                border-color: #cbd5e0;
                background: white;
            }

            .form-select {
                appearance: none;
                background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
                background-position: right 16px center;
                background-repeat: no-repeat;
                background-size: 16px;
                padding-right: 48px;
            }

            .password-container {
                position: relative;
            }

            .password-toggle {
                position: absolute;
                right: 16px;
                top: 50%;
                transform: translateY(-50%);
                background: none;
                border: none;
                cursor: pointer;
                color: #718096;
                font-size: 18px;
                transition: color 0.3s ease;
            }

            .password-toggle:hover {
                color: #4a5568;
            }

            .register-button {
                width: 100%;
                padding: 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 12px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s ease;
                text-transform: uppercase;
                letter-spacing: 1px;
            }

            .register-button:hover {
                transform: translateY(-2px);
                box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
            }

            .register-button:disabled {
                opacity: 0.6;
                cursor: not-allowed;
                transform: none;
            }

            .error-message {
                background: #fed7d7;
                color: #c53030;
                padding: 12px 16px;
                border-radius: 8px;
                margin-bottom: 20px;
                font-size: 14px;
                border-left: 4px solid #e53e3e;
            }

            .success-message {
                background: #c6f6d5;
                color: #2f855a;
                padding: 12px 16px;
                border-radius: 8px;
                margin-bottom: 20px;
                font-size: 14px;
                border-left: 4px solid #38a169;
            }

            .login-link {
                text-align: center;
                margin-top: 24px;
                color: #718096;
                font-size: 14px;
            }

            .login-link a {
                color: #667eea;
                text-decoration: none;
                font-weight: 600;
            }

            .login-link a:hover {
                text-decoration: underline;
            }

            @media (max-width: 480px) {
                .register-container {
                    padding: 30px 20px;
                    margin: 10px;
                }

                .register-title {
                    font-size: 24px;
                }
            }
        </style>
    </head>
    <body>
        <div class="register-container">
            <div class="register-header">
                <h1 class="register-title">Create Account</h1>
                <p class="register-subtitle">Join us today and get started</p>
            </div>

            <!-- Display messages from session or URL parameters -->
            <%
                String errorMessage = (String) session.getAttribute("errorMessage");
                String successMessage = (String) session.getAttribute("successMessage");
                String urlErrorMessage = request.getParameter("errorMessage");

                // Clear session messages after displaying
                if (errorMessage != null) {
                    session.removeAttribute("errorMessage");
                }
                if (successMessage != null) {
                    session.removeAttribute("successMessage");
                }
            %>

            <% if (errorMessage != null) {%>
            <div class="error-message"><%= errorMessage%></div>
            <% } %>

            <% if (urlErrorMessage != null) {%>
            <div class="error-message"><%= java.net.URLDecoder.decode(urlErrorMessage, "UTF-8")%></div>
            <% } %>

            <% if (successMessage != null) {%>
            <div class="success-message"><%= successMessage%></div>
            <% }%>

            <!-- Form that submits to SignUpServlet -->
            <form id="registerForm" action="<%= request.getContextPath()%>/SignUpServlet" method="post">

                <div class="form-group">
                    <label for="fullName" class="form-label">Full Name</label>
                    <input type="text" 
                           id="fullName" 
                           name="fullName" 
                           class="form-input" 
                           placeholder="Enter your full name" 
                           required
                           value="<%= request.getParameter("fullName") != null ? request.getParameter("fullName") : ""%>">
                </div>

                <div class="form-group">
                    <label for="email" class="form-label">Email Address</label>
                    <input type="email" 
                           id="email" 
                           name="email" 
                           class="form-input" 
                           placeholder="Enter your email address" 
                           required
                           value="<%= request.getParameter("email") != null ? request.getParameter("email") : ""%>">
                </div>

                <div class="form-group">
                    <label for="username" class="form-label">Username</label>
                    <input type="text" 
                           id="username" 
                           name="username" 
                           class="form-input" 
                           placeholder="Choose a username" 
                           required
                           value="<%= request.getParameter("username") != null ? request.getParameter("username") : ""%>">
                </div>

                <div class="form-group">
                    <label for="role" class="form-label">Account Type</label>
                    <select id="role" name="role" class="form-select" required>
                        <option value="CUSTOMER" <%= "CUSTOMER".equals(request.getParameter("role")) || request.getParameter("role") == null ? "selected" : ""%>>Customer</option>
                        <option value="ADMIN" <%= "ADMIN".equals(request.getParameter("role")) ? "selected" : ""%>>Admin</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="password" class="form-label">Password</label>
                    <div class="password-container">
                        <input type="password" 
                               id="password" 
                               name="password" 
                               class="form-input" 
                               placeholder="Create a strong password" 
                               required>
                        <button type="button" class="password-toggle" onclick="togglePassword('password')">
                            👁
                        </button>
                    </div>
                </div>

                <div class="form-group">
                    <label for="confirmPassword" class="form-label">Confirm Password</label>
                    <div class="password-container">
                        <input type="password" 
                               id="confirmPassword" 
                               name="confirmPassword" 
                               class="form-input" 
                               placeholder="Confirm your password" 
                               required>
                        <button type="button" class="password-toggle" onclick="togglePassword('confirmPassword')">
                            👁
                        </button>
                    </div>
                </div>

                <button type="submit" class="register-button" id="registerBtn">
                    Create Account
                </button>
            </form>

            <div class="login-link">
                Already have an account? <a href='login.jsp'>Sign in here</a>
            </div>
        </div>

        <script>
            // Toggle password visibility
            function togglePassword(fieldId) {
                const passwordInput = document.getElementById(fieldId);
                const toggleButton = passwordInput.nextElementSibling;

                if (passwordInput.type === 'password') {
                    passwordInput.type = 'text';
                    toggleButton.textContent = '🙈';
                } else {
                    passwordInput.type = 'password';
                    toggleButton.textContent = '👁';
                }
            }

            // Basic client-side validation
            document.getElementById('registerForm').addEventListener('submit', function (e) {
                const password = document.getElementById('password').value;
                const confirmPassword = document.getElementById('confirmPassword').value;
                const username = document.getElementById('username').value;
                const email = document.getElementById('email').value;
                const fullName = document.getElementById('fullName').value;

                // Check if passwords match
                if (password !== confirmPassword) {
                    alert('Passwords do not match!');
                    e.preventDefault();
                    return false;
                }

                // Basic validation
                if (password.length < 6) {
                    alert('Password must be at least 6 characters long!');
                    e.preventDefault();
                    return false;
                }

                if (username.length < 3) {
                    alert('Username must be at least 3 characters long!');
                    e.preventDefault();
                    return false;
                }

                if (!email.includes('@')) {
                    alert('Please enter a valid email address!');
                    e.preventDefault();
                    return false;
                }

                if (fullName.trim().length < 2) {
                    alert('Please enter your full name!');
                    e.preventDefault();
                    return false;
                }

                // Show loading state
                const registerBtn = document.getElementById('registerBtn');
                registerBtn.disabled = true;
                registerBtn.textContent = 'Creating Account...';

                return true;
            });

            // Add hover effects
            document.querySelectorAll('.form-input, .form-select').forEach(input => {
                input.addEventListener('focus', function () {
                    this.style.transform = 'translateY(-2px)';
                });

                input.addEventListener('blur', function () {
                    this.style.transform = 'translateY(0)';
                });
            });
        </script>
    </body>
</html>