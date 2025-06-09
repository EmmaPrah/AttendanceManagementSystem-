<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="org.json.JSONObject" %>

<%
    // Set error handling to catch all exceptions
    try {
        // Set appropriate headers
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        response.setContentType("application/json");
        
        PrintWriter out = response.getWriter();
        JSONObject jsonResponse = new JSONObject();
        
        // Ensure user is logged in and is a student
        if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Please log in as a student");
            out.print(jsonResponse.toString());
            return;
        }
    
        String studentId = (String) session.getAttribute("userId");
        System.out.println("Processing simple voice save for student ID: " + studentId);
        
        try {
            // Get the audio data from request parameter
            String audioData = request.getParameter("audioData");
            String pin = request.getParameter("pin");
            
            if (audioData == null || audioData.isEmpty()) {
                jsonResponse.put("success", false);
                jsonResponse.put("error", "No audio data received");
                out.print(jsonResponse.toString());
                return;
            }
            
            // Debug info
            System.out.println("Audio data received, length: " + audioData.length());
            System.out.println("PIN received: " + (pin != null ? pin : "null"));
            
            // Remove the "data:audio/webm;base64," prefix if present
            if (audioData.contains(",")) {
                audioData = audioData.split(",")[1];
                System.out.println("Audio data after splitting, length: " + audioData.length());
            }
            
            // Decode base64 audio data
            byte[] voiceData;
            try {
                voiceData = Base64.getDecoder().decode(audioData);
                System.out.println("Decoded audio data length: " + voiceData.length);
            } catch (IllegalArgumentException e) {
                e.printStackTrace();
                jsonResponse.put("success", false);
                jsonResponse.put("error", "Invalid audio data format: " + e.getMessage());
                out.print(jsonResponse.toString());
                return;
            }
    
            // Create database table if it doesn't exist
            String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
            Connection connection = null;
            Statement stmt = null;
            PreparedStatement pstmt = null;
            
            try {
                Class.forName("org.sqlite.JDBC");
                System.out.println("JDBC driver loaded successfully");
                
                connection = DriverManager.getConnection(jdbcURL);
                System.out.println("Database connection established");
                
                // Create voice_prints table if it doesn't exist
                stmt = connection.createStatement();
                String createTableSQL = 
                    "CREATE TABLE IF NOT EXISTS voice_prints (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "student_id TEXT NOT NULL, " +
                    "voice_data BLOB, " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "UNIQUE(student_id)" +
                    ")";
                stmt.execute(createTableSQL);
                System.out.println("Table created or already exists");
                
                // Save the voice print - simple version without Azure
                pstmt = connection.prepareStatement(
                    "INSERT OR REPLACE INTO voice_prints (student_id, voice_data) VALUES (?, ?)"
                );
                pstmt.setString(1, studentId);
                pstmt.setBytes(2, voiceData);
                
                int rowsAffected = pstmt.executeUpdate();
                System.out.println("Database update complete. Rows affected: " + rowsAffected);
                
                if (rowsAffected > 0) {
                    jsonResponse.put("success", true);
                    jsonResponse.put("message", "Voice saved successfully");
                    System.out.println("Voice saved successfully for student: " + studentId);
                } else {
                    jsonResponse.put("success", false);
                    jsonResponse.put("error", "Failed to save voice data");
                    System.out.println("Failed to save voice data for student: " + studentId);
                }
                
            } catch (Exception e) {
                e.printStackTrace();
                jsonResponse.put("success", false);
                jsonResponse.put("error", "Database error: " + e.getMessage());
                System.out.println("Database error: " + e.getMessage());
            } finally {
                if (stmt != null) try { stmt.close(); } catch (SQLException e) { /* ignore */ }
                if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { /* ignore */ }
                if (connection != null) try { connection.close(); } catch (SQLException e) { /* ignore */ }
            }
            
            // Send the response
            out.print(jsonResponse.toString());
            out.flush();
            
        } catch (Exception e) {
            e.printStackTrace();
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Error processing request: " + e.getMessage());
            out.print(jsonResponse.toString());
        }
    } catch (Throwable t) {
        // Catch any errors that might occur before the response is set up
        t.printStackTrace();
        
        // Try to send a response if possible
        try {
            response.setContentType("application/json");
            PrintWriter out = response.getWriter();
            JSONObject jsonResponse = new JSONObject();
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Server error: " + t.getMessage());
            out.print(jsonResponse.toString());
            out.flush();
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
%>
