<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.math.BigInteger" %>
<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");
    
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);
        
        // First check if the database exists by trying to query the users table
        try {
            Statement checkStmt = connection.createStatement();
            checkStmt.executeQuery("SELECT 1 FROM users LIMIT 1");
            checkStmt.close();
        } catch (SQLException e) {
            // Database or table doesn't exist
            response.sendRedirect("setupDatabase.jsp");
            return;
        }
        
        // Query using email as username
        // Hash the password using SHA-256
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        md.update(password.getBytes());
        String hashedPassword = String.format("%064x", new BigInteger(1, md.digest()));

        String sql = "SELECT user_id, email, user_type, full_name, department, level FROM users WHERE email = ? AND password = ?";
        pstmt = connection.prepareStatement(sql);
        pstmt.setString(1, username);
        pstmt.setString(2, hashedPassword);
        
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            // Store user information in session
            session.setAttribute("userId", rs.getString("user_id"));
            session.setAttribute("userEmail", rs.getString("email"));
            session.setAttribute("userType", rs.getString("user_type"));
            session.setAttribute("fullName", rs.getString("full_name"));
            session.setAttribute("department", rs.getString("department"));
            
            // Only set level for students
            if ("student".equals(rs.getString("user_type"))) {
                Integer level = rs.getObject("level") != null ? rs.getInt("level") : null;
                session.setAttribute("level", level);
            }
            
            // Redirect based on user type
            if ("student".equals(rs.getString("user_type"))) {
                response.sendRedirect("student-dashboard.jsp");
            } else if ("lecturer".equals(rs.getString("user_type"))) {
                response.sendRedirect("lecturer-dashboard.jsp");
            }
        } else {
            response.sendRedirect("login.jsp?error=" + URLEncoder.encode("Invalid email or password", StandardCharsets.UTF_8));
        }
    } catch (Exception e) {
        e.printStackTrace(); // Log the error for debugging
        String errorMessage = "Database error: " + e.getMessage();
        response.sendRedirect("login.jsp?error=" + URLEncoder.encode(errorMessage, StandardCharsets.UTF_8));
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
