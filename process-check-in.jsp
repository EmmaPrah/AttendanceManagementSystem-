<%@ page import="java.sql.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.*" %>
<%
    // Check if user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in to check-in");
        return;
    }

    String userId = (String) session.getAttribute("userId");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String message = "";
    String messageType = "";

    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);

        String courseCode = request.getParameter("courseCode");
        double latitude = 0;
        double longitude = 0;
        
        try {
            latitude = Double.parseDouble(request.getParameter("latitude"));
            longitude = Double.parseDouble(request.getParameter("longitude"));
        } catch (Exception e) {
            System.out.println("Error parsing coordinates: " + e.getMessage());
            // Continue with default values
        }
        
        LocalDateTime now = LocalDateTime.now();
        String checkInDate = now.format(DateTimeFormatter.ISO_LOCAL_DATE);
        String checkInTime = now.format(DateTimeFormatter.ISO_LOCAL_TIME);

        // Check if student is enrolled in the course
        pstmt = connection.prepareStatement(
            "SELECT * FROM course_selections WHERE student_id = ? AND course_code = ?"
        );
        pstmt.setString(1, userId);
        pstmt.setString(2, courseCode);
        rs = pstmt.executeQuery();

        if (!rs.next()) {
            message = "You are not enrolled in this course.";
            messageType = "danger";
        } else {
            // Verify location
            pstmt = connection.prepareStatement(
                "SELECT * FROM classroom_locations WHERE course_code = ?"
            );
            pstmt.setString(1, courseCode);
            rs = pstmt.executeQuery();

            boolean locationVerified = false;
            double classLat = 0;
            double classLng = 0;
            double radius = 100; // Default radius in meters

            if (rs.next()) {
                classLat = rs.getDouble("latitude");
                classLng = rs.getDouble("longitude");
                radius = rs.getDouble("radius");

                // Calculate distance between user and classroom
                double distance = calculateDistance(latitude, longitude, classLat, classLng);
                
                if (distance <= radius) {
                    locationVerified = true;
                }
            } else {
                // No location data for this course, skip location verification
                locationVerified = true;
            }

            // Check if voice verification was successful
            String voiceVerified = request.getParameter("voiceVerified");
            boolean isVoiceVerified = "true".equals(voiceVerified);

            if (!locationVerified) {
                message = "You are not at the correct location for this class.";
                messageType = "danger";
            } else if (!isVoiceVerified) {
                message = "Voice verification failed. Please try again.";
                messageType = "danger";
            } else {
                // Record attendance
                pstmt = connection.prepareStatement(
                    "INSERT INTO attendance (student_id, course_code, date, time, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)"
                );
                pstmt.setString(1, userId);
                pstmt.setString(2, courseCode);
                pstmt.setString(3, checkInDate);
                pstmt.setString(4, checkInTime);
                pstmt.setDouble(5, latitude);
                pstmt.setDouble(6, longitude);
                pstmt.executeUpdate();

                message = "Check-in successful for " + courseCode + "!";
                messageType = "success";
            }
        }
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageType = "danger";
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { /* ignore */ }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { /* ignore */ }
        if (connection != null) try { connection.close(); } catch (SQLException e) { /* ignore */ }
    }

    // Redirect back to student dashboard with message
    response.sendRedirect("student-dashboard.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&type=" + messageType);
%>

<%!
    // Calculate distance between two points using Haversine formula
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000; // Earth radius in meters
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distance = R * c;
        return distance;
    }
%>
