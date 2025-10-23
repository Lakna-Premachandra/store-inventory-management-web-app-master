<%-- cartUtils.jsp - Reusable cart functions --%>
<%@page import="java.util.*"%>
<%!
    public static int getCartItemCount(HttpSession session) {
        List<Map<String, Object>> cart = (List<Map<String, Object>>) session.getAttribute("cart");
        if (cart == null) return 0;
        
        int count = 0;
        for (Map<String, Object> item : cart) {
            count += (Integer) item.get("quantity");
        }
        return count;
    }
    
    public static double getCartTotal(HttpSession session) {
        List<Map<String, Object>> cart = (List<Map<String, Object>>) session.getAttribute("cart");
        if (cart == null) return 0.0;
        
        double total = 0.0;
        for (Map<String, Object> item : cart) {
            double price = (Double) item.get("price");
            int quantity = (Integer) item.get("quantity");
            total += price * quantity;
        }
        return total;
    }
%>