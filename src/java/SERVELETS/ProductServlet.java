    package SERVELETS;

    import MODELS.Product;
    import SERVICES.ProductService;
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
    import java.util.List;

    @WebServlet("/ProductServlet/*")
    public class ProductServlet extends HttpServlet {
        private ProductService productService;
        private Gson gson;

        @Override
        public void init() throws ServletException {
            productService = new ProductService();
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
                    // GET /api/products - Get all products
                    List<Product> products = productService.getAllProducts();
                    out.print(gson.toJson(products));
                } else {
                    String productCode = pathInfo.substring(1);

                    if (productCode.contains("/")) {
                        String[] parts = productCode.split("/");
                        productCode = parts[0];
                        String action = parts[1];

                        if ("with-stock".equals(action)) {
                            // GET /api/products/{code}/with-stock
                            ProductService.ProductWithStock productWithStock = 
                                productService.getProductWithStock(productCode);
                            if (productWithStock != null) {
                                out.print(gson.toJson(productWithStock));
                            } else {
                                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                                out.print("{\"error\":\"Product not found\"}");
                            }
                            return;
                        }
                    }

                    // GET /api/products/{code} - Get specific product
                    Product product = productService.getProductByCode(productCode);
                    if (product != null) {
                        out.print(gson.toJson(product));
                    } else {
                        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                        out.print("{\"error\":\"Product not found\"}");
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
                    // POST /api/products - Add new product
                    StringBuilder sb = new StringBuilder();
                    BufferedReader reader = req.getReader();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        sb.append(line);
                    }
                    String requestBody = sb.toString();
                    JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();

                    Product product = gson.fromJson(jsonBody, Product.class);

                    // Check if initial stock is provided
                    boolean success;
                    if (jsonBody.has("initialStock")) {
                        int initialStock = jsonBody.get("initialStock").getAsInt();
                        success = productService.addProductWithStock(product, initialStock);
                    } else {
                        success = productService.addProduct(product);
                    }

                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_CREATED);
                        out.print("{\"success\":true,\"message\":\"Product added successfully\"}");
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"Failed to add product\"}");
                    }
                } else {
                    String productCode = pathInfo.substring(1);

                    if (productCode.contains("/")) {
                        String[] parts = productCode.split("/");
                        productCode = parts[0];
                        String action = parts[1];

                        if ("with-stock".equals(action)) {
                            // POST /api/products/{code}/with-stock - Add product with initial stock
                            StringBuilder sb = new StringBuilder();
                            BufferedReader reader = req.getReader();
                            String line;
                            while ((line = reader.readLine()) != null) {
                                sb.append(line);
                            }
                            String requestBody = sb.toString();
                            JsonObject jsonBody = JsonParser.parseString(requestBody).getAsJsonObject();

                            Product product = new Product();
                            product.setProductCode(productCode);
                            product.setName(jsonBody.get("name").getAsString());
                            product.setUnitPrice(jsonBody.get("unitPrice").getAsBigDecimal());

                            if (jsonBody.has("discount")) {
                                product.setDiscount(jsonBody.get("discount").getAsBigDecimal());
                            }

                            int initialStock = jsonBody.get("initialStock").getAsInt();

                            boolean success = productService.addProductWithStock(product, initialStock);
                            if (success) {
                                resp.setStatus(HttpServletResponse.SC_CREATED);
                                out.print("{\"success\":true,\"message\":\"Product with stock added successfully\"}");
                            } else {
                                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                                out.print("{\"success\":false,\"message\":\"Failed to add product with stock\"}");
                            }
                            return;
                        }
                    }

                    resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{\"error\":\"Invalid endpoint\"}");
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

                    Product product = gson.fromJson(req.getReader(), Product.class);
                    product.setProductCode(productCode);

                    boolean success = productService.updateProduct(product);
                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_OK);
                        out.print("{\"success\":true,\"message\":\"Product updated successfully\"}");
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"Failed to update product\"}");
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

                    boolean success = productService.deleteProduct(productCode);
                    if (success) {
                        resp.setStatus(HttpServletResponse.SC_OK);
                        out.print("{\"success\":true,\"message\":\"Product and related inventory deleted successfully\"}");
                    } else {
                        resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        out.print("{\"success\":false,\"message\":\"Failed to delete product\"}");
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