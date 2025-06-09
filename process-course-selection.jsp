<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a student");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    String[] selectedCourses = request.getParameterValues("selectedCourses");
    
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);
        connection.setAutoCommit(false);

        // First, delete all existing course selections for this student
        pstmt = connection.prepareStatement("DELETE FROM course_selections WHERE student_id = ?");
        pstmt.setString(1, studentId);
        pstmt.executeUpdate();

        // Then insert new selections
        if (selectedCourses != null && selectedCourses.length > 0) {
            pstmt = connection.prepareStatement("INSERT INTO course_selections (student_id, course_code) VALUES (?, ?)");
            for (String courseCode : selectedCourses) {
                pstmt.setString(1, studentId);
                pstmt.setString(2, courseCode);
                pstmt.executeUpdate();
            }
        }

        connection.commit();
        response.sendRedirect("select-courses.jsp?success=" + URLEncoder.encode("Course selection updated successfully", StandardCharsets.UTF_8));
    } catch (Exception e) {
        if (connection != null) {
            try {
                connection.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
        e.printStackTrace();
        response.sendRedirect("select-courses.jsp?error=" + URLEncoder.encode("Error updating course selection: " + e.getMessage(), StandardCharsets.UTF_8));
    } finally {
        try {
            if (pstmt != null) pstmt.close();
            if (connection != null) connection.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>
