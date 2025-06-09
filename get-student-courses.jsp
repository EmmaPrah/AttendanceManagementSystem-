<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.google.gson.*" %>
<%
    response.setContentType("application/json");
    
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.getWriter().write("{\"success\": false, \"error\": \"Please log in as a student\"}");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    JsonObject jsonResponse = new JsonObject();
    JsonArray coursesArray = new JsonArray();
    
    try {
        String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
        Connection connection = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            Class.forName("org.sqlite.JDBC");
            connection = DriverManager.getConnection(jdbcURL);

            // Get courses the student is enrolled in
            pstmt = connection.prepareStatement(
                "SELECT cs.course_code, c.course_name " +
                "FROM course_selections cs " +
                "JOIN courses c ON cs.course_code = c.course_code " +
                "WHERE cs.student_id = ?"
            );
            pstmt.setString(1, studentId);
            rs = pstmt.executeQuery();

            while (rs.next()) {
                JsonObject courseObj = new JsonObject();
                courseObj.addProperty("courseCode", rs.getString("course_code"));
                courseObj.addProperty("courseName", rs.getString("course_name"));
                coursesArray.add(courseObj);
            }

            jsonResponse.addProperty("success", true);
            jsonResponse.add("courses", coursesArray);
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (connection != null) connection.close();
        }
    } catch (Exception e) {
        jsonResponse.addProperty("success", false);
        jsonResponse.addProperty("error", e.getMessage());
    }
    
    response.getWriter().write(jsonResponse.toString());
%>
