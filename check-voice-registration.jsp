<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>

<%
    response.setContentType("application/json");
    
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.getWriter().write("{\"success\": false, \"error\": \"Please log in as a student\"}");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    
    try {
        // Database connection
        String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
        Connection connection = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            Class.forName("org.sqlite.JDBC");
            connection = DriverManager.getConnection(jdbcURL);

            // Check if the student has a registered voice print
            pstmt = connection.prepareStatement("SELECT COUNT(*) as count FROM voice_prints WHERE student_id = ?");
            pstmt.setString(1, studentId);
            rs = pstmt.executeQuery();
            
            boolean hasVoicePrint = false;
            if (rs.next()) {
                hasVoicePrint = rs.getInt("count") > 0;
            }
            
            response.getWriter().write("{\"success\": true, \"hasVoicePrint\": " + hasVoicePrint + "}");
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (connection != null) connection.close();
        }
    } catch (Exception e) {
        e.printStackTrace(); // Log the error to the console
        response.getWriter().write("{\"success\": false, \"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    }
%>
