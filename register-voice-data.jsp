<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="org.json.JSONObject" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>

<%
    // Set error handling to catch all exceptions
    try {
        // Set appropriate headers to prevent caching
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        response.setContentType("application/json");
        
        PrintWriter outWriter = response.getWriter();
        JSONObject jsonResponse = new JSONObject();
        
        // Ensure user is logged in and is a student
        if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Please log in as a student");
            outWriter.print(jsonResponse.toString());
            return;
        }
    
        String studentId = (String) session.getAttribute("userId");
        System.out.println("Processing voice registration for student ID: " + studentId);
        
        try {
            // Get the audio data from request parameter
            String audioData = request.getParameter("audioData");
            String pin = request.getParameter("pin");
            
            System.out.println("PIN received: " + (pin != null ? pin : "null"));
            
            if (audioData == null || audioData.isEmpty()) {
                System.out.println("ERROR: No audio data received in request");
                System.out.println("Request parameters: " + request.getParameterMap().keySet());
                jsonResponse.put("success", false);
                jsonResponse.put("error", "No audio data received");
                outWriter.print(jsonResponse.toString());
                return;
            }
            
            // Debug info
            System.out.println("Audio data received, length: " + audioData.length());
            
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
                
                // Check for minimum audio data size (1KB)
                if (voiceData.length < 1024) {
                    jsonResponse.put("success", false);
                    jsonResponse.put("error", "Recording too short or empty. Please try again with a longer recording.");
                    outWriter.print(jsonResponse.toString());
                    return;
                }
            } catch (IllegalArgumentException e) {
                e.printStackTrace();
                System.out.println("ERROR: Failed to decode base64 audio: " + e.getMessage());
                System.out.println("First 100 chars of audio data: " + audioData.substring(0, Math.min(100, audioData.length())));
                jsonResponse.put("success", false);
                jsonResponse.put("error", "Invalid audio data format: " + e.getMessage());
                outWriter.print(jsonResponse.toString());
                return;
            }
    
            // Check if we have any voice data
            if (voiceData.length == 0) {
                jsonResponse.put("success", false);
                jsonResponse.put("error", "Decoded audio data is empty");
                outWriter.print(jsonResponse.toString());
                return;
            }
            
            // For now, skip the audio conversion to simplify the process
            // We'll use the raw audio data for enrollment
            System.out.println("Using raw audio data for enrollment, length: " + voiceData.length);
    
            // Database operations
            String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
            Connection connection = null;
            PreparedStatement pstmt = null;
            Statement stmt = null;
            ResultSet rs = null;
            
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
                    "azure_profile_id TEXT, " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "UNIQUE(student_id)" +
                    ")";
                stmt.execute(createTableSQL);
                System.out.println("Table created or already exists");
                
                // First check if the user already has a registered voice print
                pstmt = connection.prepareStatement("SELECT azure_profile_id FROM voice_prints WHERE student_id = ?");
                pstmt.setString(1, studentId);
                rs = pstmt.executeQuery();
                
                String azureProfileId = "mock-profile-" + System.currentTimeMillis();
                boolean isUpdate = false;
                
                if (rs.next()) {
                    // User already has a voice print
                    isUpdate = true;
                    System.out.println("Found existing voice print for student: " + studentId);
                }
                
                // For testing purposes, skip the actual Azure enrollment
                // Just simulate a successful enrollment
                boolean enrollmentSuccess = true;
                System.out.println("Simulating successful voice enrollment");
                
                if (!enrollmentSuccess) {
                    jsonResponse.put("success", false);
                    jsonResponse.put("error", "Voice enrollment failed. Please try again with a clearer recording.");
                    outWriter.print(jsonResponse.toString());
                    return;
                }
                
                System.out.println("Voice enrollment successful, saving to database...");
                
                // Close previous statement and result set before creating new ones
                if (pstmt != null) pstmt.close();
                if (rs != null) rs.close();
                
                // Save or update the voice print in the database
                if (isUpdate) {
                    pstmt = connection.prepareStatement(
                        "UPDATE voice_prints SET voice_data = ?, azure_profile_id = ?, updated_at = CURRENT_TIMESTAMP WHERE student_id = ?"
                    );
                    pstmt.setBytes(1, voiceData);
                    pstmt.setString(2, azureProfileId);
                    pstmt.setString(3, studentId);
                    System.out.println("Updating existing voice print for student: " + studentId);
                } else {
                    pstmt = connection.prepareStatement(
                        "INSERT INTO voice_prints (student_id, voice_data, azure_profile_id) VALUES (?, ?, ?)"
                    );
                    pstmt.setString(1, studentId);
                    pstmt.setBytes(2, voiceData);
                    pstmt.setString(3, azureProfileId);
                    System.out.println("Inserting new voice print for student: " + studentId);
                }
                
                try {
                    int rowsAffected = pstmt.executeUpdate();
                    System.out.println("Database update complete. Rows affected: " + rowsAffected);
                    
                    if (rowsAffected > 0) {
                        jsonResponse.put("success", true);
                        jsonResponse.put("message", "Voice registered successfully");
                        System.out.println("Voice registration successful for student: " + studentId);
                    } else {
                        jsonResponse.put("success", false);
                        jsonResponse.put("error", "Failed to save voice data to database");
                        System.out.println("Failed to save voice data to database for student: " + studentId);
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                    jsonResponse.put("success", false);
                    jsonResponse.put("error", "Database error: " + e.getMessage());
                    System.out.println("SQL error while saving voice print: " + e.getMessage());
                }
                
            } catch (Exception e) {
                e.printStackTrace();
                jsonResponse.put("success", false);
                jsonResponse.put("error", "Database error: " + e.getMessage());
                System.out.println("Database error: " + e.getMessage());
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException e) { /* ignore */ }
                if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { /* ignore */ }
                if (stmt != null) try { stmt.close(); } catch (SQLException e) { /* ignore */ }
                if (connection != null) try { connection.close(); } catch (SQLException e) { /* ignore */ }
            }
            
            // Send the response
            outWriter.print(jsonResponse.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("ERROR: Exception in main processing: " + e.getMessage());
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Error processing request: " + e.getMessage());
            outWriter.print(jsonResponse.toString());
        }
    } catch (Throwable t) {
        // Catch any errors that might occur before the response is set up
        t.printStackTrace();
        System.out.println("CRITICAL ERROR: Throwable caught: " + t.getMessage());
        
        // Try to send a response if possible
        try {
            response.setContentType("application/json");
            PrintWriter errorWriter = response.getWriter();
            JSONObject jsonResponse = new JSONObject();
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Server error: " + t.getMessage());
            errorWriter.print(jsonResponse.toString());
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
%>
