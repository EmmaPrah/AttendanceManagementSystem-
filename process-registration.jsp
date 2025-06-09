<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>

<%
    // Declare variables at the top
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        // Get form data
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String userId = request.getParameter("userId");
        String password = request.getParameter("password");
        String userType = request.getParameter("userType");

        if (fullName == null || email == null || userId == null || password == null || userType == null) {
            String error = "All fields are required";
            response.sendRedirect("register.jsp?error=" + URLEncoder.encode(error, StandardCharsets.UTF_8));
            return;
        }

        // Validate user ID format
        if (!userId.matches("[A-Za-z0-9]+")) {
            String error = "ID should only contain letters and numbers";
            response.sendRedirect("register.jsp?error=" + URLEncoder.encode(error, StandardCharsets.UTF_8));
            return;
        }

        // Hash the password
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder hexString = new StringBuilder();
        for (byte b : hash) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }
        String hashedPassword = hexString.toString();

        // Database connection
        String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL + "?busy_timeout=5000");
        
        // Set pragmas before starting transaction
        Statement stmt = connection.createStatement();
        stmt.execute("PRAGMA busy_timeout=5000");
        stmt.close();
        
        // Now start transaction
        connection.setAutoCommit(false);

        // Check if user already exists
        pstmt = connection.prepareStatement("SELECT 1 FROM users WHERE user_id = ? OR email = ?");
        pstmt.setString(1, userId);
        pstmt.setString(2, email);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            connection.rollback();
            response.sendRedirect("register.jsp?error=" + URLEncoder.encode("A user with this ID or email already exists", StandardCharsets.UTF_8));
            return;
        }

        // Insert new user
        pstmt = connection.prepareStatement("INSERT INTO users (user_id, full_name, email, password, user_type) VALUES (?, ?, ?, ?, ?)");
        pstmt.setString(1, userId);
        pstmt.setString(2, fullName);
        pstmt.setString(3, email);
        pstmt.setString(4, hashedPassword);
        pstmt.setString(5, userType);
        pstmt.executeUpdate();

        // Commit and set session
        connection.commit();
        session.setAttribute("userId", userId);
        session.setAttribute("userType", userType);
        session.setAttribute("fullName", fullName);

        // Redirect based on user type
        response.sendRedirect("student".equals(userType) ? "student-dashboard.jsp" : "lecturer-dashboard.jsp");

    } catch (Exception e) {
        if (connection != null) {
            try { connection.rollback(); } catch (SQLException se) { se.printStackTrace(); }
        }
        e.printStackTrace();
        response.sendRedirect("register.jsp?error=" + URLEncoder.encode("Registration failed: " + e.getMessage(), StandardCharsets.UTF_8));
    } finally {
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (connection != null) connection.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>
