<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.math.BigInteger" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%
    // Ensure user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in to update your profile");
        return;
    }

    String userId = (String) session.getAttribute("userId");
    String userType = (String) session.getAttribute("userType");
    String currentPassword = request.getParameter("currentPassword");
    String newPassword = request.getParameter("newPassword");
    String fullName = request.getParameter("fullName");
    String email = request.getParameter("email");
    String faculty = request.getParameter("faculty");
    String department = request.getParameter("department");
    String levelParam = request.getParameter("level");
    int level = 0;
    
    if (levelParam != null && !levelParam.isEmpty()) {
        try {
            level = Integer.parseInt(levelParam);
        } catch (NumberFormatException e) {
            // Use default value if parsing fails
            level = 0;
        }
    }

    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        // Hash the current password
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        md.update(currentPassword.getBytes());
        String hashedCurrentPassword = String.format("%064x", new BigInteger(1, md.digest()));

        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);
        connection.setAutoCommit(false);

        // Verify current password
        pstmt = connection.prepareStatement("SELECT 1 FROM users WHERE user_id = ? AND password = ?");
        pstmt.setString(1, userId);
        pstmt.setString(2, hashedCurrentPassword);
        rs = pstmt.executeQuery();

        if (!rs.next()) {
            response.sendRedirect("edit-profile.jsp?error=" + URLEncoder.encode("Current password is incorrect", StandardCharsets.UTF_8));
            if (connection != null) connection.rollback();
            return;
        }

        // Check if email is already used by another user
        pstmt = connection.prepareStatement("SELECT 1 FROM users WHERE email = ? AND user_id != ?");
        pstmt.setString(1, email);
        pstmt.setString(2, userId);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            response.sendRedirect("edit-profile.jsp?error=" + URLEncoder.encode("Email is already in use by another user", StandardCharsets.UTF_8));
            if (connection != null) connection.rollback();
            return;
        }

        // Update user information
        String sql;
        if (newPassword != null && !newPassword.trim().isEmpty()) {
            // Hash the new password
            md.update(newPassword.getBytes());
            String hashedNewPassword = String.format("%064x", new BigInteger(1, md.digest()));
            
            if ("student".equals(userType)) {
                // For students, include the level field
                sql = "UPDATE users SET full_name = ?, email = ?, faculty = ?, department = ?, level = ?, password = ? WHERE user_id = ?";
                pstmt = connection.prepareStatement(sql);
                pstmt.setString(1, fullName);
                pstmt.setString(2, email);
                pstmt.setString(3, faculty);
                pstmt.setString(4, department);
                pstmt.setInt(5, level);
                pstmt.setString(6, hashedNewPassword);
                pstmt.setString(7, userId);
            } else {
                // For lecturers, exclude the level field
                sql = "UPDATE users SET full_name = ?, email = ?, faculty = ?, department = ?, password = ? WHERE user_id = ?";
                pstmt = connection.prepareStatement(sql);
                pstmt.setString(1, fullName);
                pstmt.setString(2, email);
                pstmt.setString(3, faculty);
                pstmt.setString(4, department);
                pstmt.setString(5, hashedNewPassword);
                pstmt.setString(6, userId);
            }
        } else {
            if ("student".equals(userType)) {
                // For students, include the level field
                sql = "UPDATE users SET full_name = ?, email = ?, faculty = ?, department = ?, level = ? WHERE user_id = ?";
                pstmt = connection.prepareStatement(sql);
                pstmt.setString(1, fullName);
                pstmt.setString(2, email);
                pstmt.setString(3, faculty);
                pstmt.setString(4, department);
                pstmt.setInt(5, level);
                pstmt.setString(6, userId);
            } else {
                // For lecturers, exclude the level field
                sql = "UPDATE users SET full_name = ?, email = ?, faculty = ?, department = ? WHERE user_id = ?";
                pstmt = connection.prepareStatement(sql);
                pstmt.setString(1, fullName);
                pstmt.setString(2, email);
                pstmt.setString(3, faculty);
                pstmt.setString(4, department);
                pstmt.setString(5, userId);
            }
        }

        int rowsAffected = pstmt.executeUpdate();
        
        if (rowsAffected > 0) {
            // Update session attributes
            session.setAttribute("fullName", fullName);
            session.setAttribute("userEmail", email);
            session.setAttribute("faculty", faculty);
            session.setAttribute("department", department);
            if ("student".equals(userType)) {
                session.setAttribute("level", level);
            }
            
            connection.commit();
            response.sendRedirect("profile.jsp?success=" + URLEncoder.encode("Profile updated successfully", StandardCharsets.UTF_8));
        } else {
            connection.rollback();
            response.sendRedirect("edit-profile.jsp?error=" + URLEncoder.encode("Failed to update profile", StandardCharsets.UTF_8));
        }
    } catch (Exception e) {
        if (connection != null) connection.rollback();
        e.printStackTrace();
        response.sendRedirect("edit-profile.jsp?error=" + URLEncoder.encode("Error updating profile: " + e.getMessage(), StandardCharsets.UTF_8));
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
