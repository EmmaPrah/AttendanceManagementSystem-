<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="AzureSpeakerVerification" %>
<%@ page import="AzureSpeakerVerification.VerificationResult" %>
<%@ page import="DatabaseInitializer" %>

<%
    // Initialize database to ensure tables exist
    DatabaseInitializer.initialize();
    
    // Set appropriate headers to prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    response.setContentType("application/json");
    
    PrintWriter out = response.getWriter();
    JSONObject jsonResponse = new JSONObject();
    
    try {
        // Ensure user is logged in and is a student
        if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Please log in as a student");
            out.print(jsonResponse.toString());
            return;
        }

        String studentId = (String) session.getAttribute("userId");
        
        // Get the audio data and PIN from request parameters
        String audioData = request.getParameter("audioData");
        String pin = request.getParameter("pin");
        
        if (audioData == null || audioData.isEmpty()) {
            jsonResponse.put("success", false);
            jsonResponse.put("error", "No audio data received");
            out.print(jsonResponse.toString());
            return;
        }
        
        // Debug info
        System.out.println("Audio data received for verification, length: " + audioData.length());
        System.out.println("PIN received: " + (pin != null ? pin : "null"));
        
        // Remove the "data:audio/webm;base64," prefix if present
        if (audioData.contains(",")) {
            audioData = audioData.split(",")[1];
        }
        
        // Decode base64 audio data
        byte[] checkInVoiceData;
        try {
            checkInVoiceData = Base64.getDecoder().decode(audioData);
            System.out.println("Decoded audio data length: " + checkInVoiceData.length);
            
            // Check for minimum audio data size (1KB)
            if (checkInVoiceData.length < 1024) {
                jsonResponse.put("success", false);
                jsonResponse.put("error", "Recording too short or empty. Please try again with a longer recording.");
                out.print(jsonResponse.toString());
                return;
            }
        } catch (IllegalArgumentException e) {
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Invalid audio data format: " + e.getMessage());
            out.print(jsonResponse.toString());
            return;
        }
        
        // Check if we have any voice data
        if (checkInVoiceData.length == 0) {
            jsonResponse.put("success", false);
            jsonResponse.put("error", "Decoded audio data is empty");
            out.print(jsonResponse.toString());
            return;
        }
        
        // Convert WebM to WAV format for Azure
        try {
            if (audioData.contains("webm")) {
                try {
                    byte[] convertedData = AzureSpeakerVerification.convertWebmToWav(checkInVoiceData);
                    if (convertedData != null && convertedData.length > 0) {
                        checkInVoiceData = convertedData;
                        System.out.println("Converted WebM to WAV, new length: " + checkInVoiceData.length);
                    } else {
                        System.out.println("Warning: WebM to WAV conversion returned null or empty data. Using original format.");
                    }
                } catch (Exception e) {
                    System.out.println("Warning: Could not convert WebM to WAV: " + e.getMessage());
                    // Continue with original format
                }
            }
        } catch (Exception e) {
            System.out.println("Warning: Error during format detection or conversion: " + e.getMessage());
            // Continue with original data
        }

        // Retrieve stored voice print from database
        String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
        Connection connection = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            Class.forName("org.sqlite.JDBC");
            connection = DriverManager.getConnection(jdbcURL);

            // Check if the user has a registered voice print
            pstmt = connection.prepareStatement("SELECT azure_profile_id FROM voice_prints WHERE student_id = ?");
            pstmt.setString(1, studentId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String azureProfileId = rs.getString("azure_profile_id");
                System.out.println("Azure profile ID: " + azureProfileId);
                
                if (azureProfileId == null || azureProfileId.isEmpty()) {
                    jsonResponse.put("success", false);
                    jsonResponse.put("error", "No Azure profile found. Please register your voice again.");
                    out.print(jsonResponse.toString());
                    return;
                }
                
                // Perform voice verification with Azure
                System.out.println("Performing Azure verification for student: " + studentId);
                
                try {
                    VerificationResult result = AzureSpeakerVerification.verifyVoice(azureProfileId, checkInVoiceData);
                    
                    // Add confidence score to response
                    jsonResponse.put("confidenceScore", result.getConfidenceScore());
                    
                    if (result.isVerified()) {
                        jsonResponse.put("success", true);
                        jsonResponse.put("verified", true);
                        jsonResponse.put("message", result.getMessage());
                        System.out.println("Voice verification successful for student: " + studentId);
                    } else {
                        jsonResponse.put("success", true);
                        jsonResponse.put("verified", false);
                        jsonResponse.put("message", result.getMessage());
                        System.out.println("Voice verification failed for student: " + studentId + " - " + result.getMessage());
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    jsonResponse.put("success", false);
                    jsonResponse.put("error", "Voice verification error: " + e.getMessage());
                    System.out.println("Voice verification error for student: " + studentId + " - " + e.getMessage());
                }
            } else {
                jsonResponse.put("success", false);
                jsonResponse.put("error", "No voice print found. Please register your voice first.");
                System.out.println("No voice print found for student: " + studentId);
            }
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { /* ignore */ }
            if (pstmt != null) try { pstmt.close(); } catch (Exception e) { /* ignore */ }
            if (connection != null) try { connection.close(); } catch (Exception e) { /* ignore */ }
        }
        
        out.print(jsonResponse.toString());
        out.flush();
        
    } catch (Exception e) {
        e.printStackTrace(); // Log the error to the console
        jsonResponse.put("success", false);
        jsonResponse.put("error", "Error processing request: " + e.getMessage());
        out.print(jsonResponse.toString());
    }
%>
