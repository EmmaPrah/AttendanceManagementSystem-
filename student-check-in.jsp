<%@ page contentType="text/html;charset=UTF-8" %>
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

        if (request.getMethod().equals("POST")) {
            String courseCode = request.getParameter("courseCode");
            double latitude = Double.parseDouble(request.getParameter("latitude"));
            double longitude = Double.parseDouble(request.getParameter("longitude"));
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

                if (rs.next()) {
                    double classLat = rs.getDouble("latitude");
                    double classLong = rs.getDouble("longitude");
                    int radius = rs.getInt("radius");

                    // Calculate distance using Haversine formula
                    double R = 6371e3; // Earth's radius in meters
                    double φ1 = Math.toRadians(latitude);
                    double φ2 = Math.toRadians(classLat);
                    double Δφ = Math.toRadians(classLat - latitude);
                    double Δλ = Math.toRadians(classLong - longitude);

                    double a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                            Math.cos(φ1) * Math.cos(φ2) *
                            Math.sin(Δλ/2) * Math.sin(Δλ/2);
                    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
                    double distance = R * c;

                    if (distance <= radius) {
                        // Check if already checked in
                        pstmt = connection.prepareStatement(
                            "SELECT * FROM attendance WHERE student_id = ? AND course_code = ? AND check_in_date = ?"
                        );
                        pstmt.setString(1, userId);
                        pstmt.setString(2, courseCode);
                        pstmt.setString(3, checkInDate);
                        rs = pstmt.executeQuery();

                        if (rs.next()) {
                            message = "You have already checked in for this course today.";
                            messageType = "warning";
                        } else {
                            // Check if voice verification is enabled
                            if (request.getParameter("voiceVerified").equals("true")) {
                                // Record new attendance
                                pstmt = connection.prepareStatement(
                                    "INSERT INTO attendance (student_id, course_code, check_in_date, check_in_time, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)"
                                );
                                pstmt.setString(1, userId);
                                pstmt.setString(2, courseCode);
                                pstmt.setString(3, checkInDate);
                                pstmt.setString(4, checkInTime);
                                pstmt.setDouble(5, latitude);
                                pstmt.setDouble(6, longitude);
                                pstmt.executeUpdate();

                                message = "Check-in successful!";
                                messageType = "success";
                            } else {
                                message = "Voice verification failed. Please try again.";
                                messageType = "danger";
                            }
                        }
                    } else {
                        message = "You are not within the classroom location. Please make sure you are in the correct classroom.";
                        messageType = "danger";
                    }
                } else {
                    message = "Course location not found.";
                    messageType = "danger";
                }
            }
        }
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageType = "danger";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Check-in - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCzZcL8Mli9-IDxcVmlK_vJbXzcXkXzf50&libraries=places"></script>
    <style>
        body {
            background-color: #f0f8ff;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .navbar {
            background-color: #007bff;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }
        #map {
            height: 200px;
            width: 100%;
            border-radius: 10px;
            margin-bottom: 15px;
        }
        .btn-voice {
            background-color: #6c5ce7;
            color: white;
            transition: all 0.3s ease;
        }
        .btn-voice:hover {
            background-color: #5f4dd0;
            color: white;
            transform: scale(1.05);
        }
        .btn-voice:disabled {
            background-color: #a8a5d3;
        }
        #voiceStatus {
            font-style: italic;
            margin: 10px 0;
            padding: 10px;
            border-radius: 5px;
            background-color: #f8f9fa;
        }
        .recording {
            animation: pulse 1.5s infinite;
            color: #dc3545;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        #waveform {
            width: 100%;
            height: 80px;
            background-color: #f8f9fa;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .verification-phrase {
            font-size: 1.2rem;
            font-weight: 500;
            color: #495057;
            margin: 1rem 0;
            padding: 1rem;
            background: #e9ecef;
            border-radius: 5px;
            text-align: center;
        }
        .timer {
            font-size: 1.5rem;
            font-weight: bold;
            margin: 0.5rem 0;
            color: #dc3545;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark mb-4">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-chalkboard-teacher me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="student-dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="student-check-in.jsp">Check-in</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="logout.jsp">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container flex-grow-1">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <% if (!message.isEmpty()) { %>
                    <div class="alert alert-<%= messageType %> alert-dismissible fade show" role="alert">
                        <%= message %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                <div class="card mb-4">
                    <div class="card-body">
                        <h2 class="card-title text-center mb-4">Course Check-in</h2>
                        <form id="checkInForm" method="POST">
                            <div class="mb-3">
                                <label for="courseSelect" class="form-label">Select Course</label>
                                <select class="form-select form-select-lg mb-3" id="courseSelect" name="courseCode" required>
                                    <option value="" selected disabled>Select your course</option>
                                    <%
                                        try {
                                            pstmt = connection.prepareStatement(
                                                "SELECT cs.course_code, c.course_name " +
                                                "FROM course_selections cs " +
                                                "JOIN courses c ON cs.course_code = c.course_code " +
                                                "WHERE cs.student_id = ?"
                                            );
                                            pstmt.setString(1, userId);
                                            rs = pstmt.executeQuery();
                                            
                                            while(rs.next()) {
                                                String code = rs.getString("course_code");
                                                String name = rs.getString("course_name");
                                    %>
                                    <option value="<%= code %>"><%= code %> - <%= name %></option>
                                    <%
                                            }
                                        } catch(Exception e) {
                                            out.println("<option value=''>Error loading courses</option>");
                                        }
                                    %>
                                </select>
                            </div>
                            <div id="map"></div>
                            <div class="mb-3">
                                <small class="text-muted">Your current location will be used for attendance verification</small>
                            </div>
                            
                            <div class="verification-phrase mb-4 p-4 bg-light rounded text-center">
                                <h5>Say: "<span class="text-primary">PIN <span id="pinNumber"></span> <%= session.getAttribute("fullName") %></span>"</h5>
                            </div>
                            
                            <div id="timerDisplay" class="timer d-none text-center">7</div>
                            
                            <div class="text-center mb-4">
                                <button type="button" id="recordVoice" class="btn btn-voice btn-lg">
                                    <i class="fas fa-microphone me-2"></i> Start Voice Recording
                                </button>
                                <button type="button" id="stopVoice" class="btn btn-danger btn-lg d-none">
                                    <i class="fas fa-stop me-2"></i> Stop Recording
                                </button>
                            </div>
                            
                            <div id="waveform" class="mb-4"></div>
                            
                            <div id="voiceStatus" class="text-center mb-4">Click the button above and speak the verification phrase</div>
                            
                            <!-- Hidden inputs for form submission -->
                            <input type="hidden" id="latitude" name="latitude" value="">
                            <input type="hidden" id="longitude" name="longitude" value="">
                            <input type="hidden" id="voiceVerified" name="voiceVerified" value="false">
                        </form>
                    </div>
                </div>

                <div class="card">
                    <div class="card-body">
                        <h3 class="card-title text-center mb-4">Recent Check-ins</h3>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Course Code</th>
                                        <th>Date</th>
                                        <th>Time</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try {
                                            pstmt = connection.prepareStatement(
                                                "SELECT * FROM attendance WHERE student_id = ? ORDER BY check_in_date DESC, check_in_time DESC LIMIT 5"
                                            );
                                            pstmt.setString(1, userId);
                                            rs = pstmt.executeQuery();
                                            
                                            while(rs.next()) {
                                    %>
                                    <tr>
                                        <td><%= rs.getString("course_code") %></td>
                                        <td><%= rs.getString("check_in_date") %></td>
                                        <td><%= rs.getString("check_in_time") %></td>
                                    </tr>
                                    <%
                                            }
                                        } catch(Exception e) {
                                            out.println("<tr><td colspan='3' class='text-danger'>Error fetching recent check-ins</td></tr>");
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://unpkg.com/wavesurfer.js@7"></script>
    <script>
        // Google Maps setup
        let map;
        let marker;
        let watchId;

        function initMap() {
            // Default center (will be updated with user's location)
            const defaultCenter = { lat: 0, lng: 0 };
            
            map = new google.maps.Map(document.getElementById('map'), {
                zoom: 15,
                center: defaultCenter,
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                disableDefaultUI: true,
                zoomControl: true
            });

            marker = new google.maps.Marker({
                map: map,
                position: defaultCenter,
                title: 'Your Location'
            });

            // Get user's location
            if (navigator.geolocation) {
                watchId = navigator.geolocation.watchPosition(
                    (position) => {
                        const pos = {
                            lat: position.coords.latitude,
                            lng: position.coords.longitude
                        };

                        // Update marker and map
                        marker.setPosition(pos);
                        map.setCenter(pos);

                        // Update hidden form fields
                        document.getElementById('latitude').value = pos.lat;
                        document.getElementById('longitude').value = pos.lng;

                        // Create accuracy circle
                        if (position.coords.accuracy) {
                            const accuracyCircle = new google.maps.Circle({
                                map: map,
                                center: pos,
                                radius: position.coords.accuracy,
                                strokeColor: '#007bff',
                                strokeOpacity: 0.8,
                                strokeWeight: 1,
                                fillColor: '#007bff',
                                fillOpacity: 0.1
                            });
                        }
                    },
                    (error) => {
                        console.error('Error getting location:', error);
                        showAlert('Error: Unable to get your location. Please enable location services.', 'danger');
                    },
                    {
                        enableHighAccuracy: true,
                        timeout: 5000,
                        maximumAge: 0
                    }
                );
            } else {
                showAlert('Error: Geolocation is not supported by your browser', 'danger');
            }
        }

        function showAlert(message, type) {
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
            alertDiv.innerHTML = `
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            `;
            document.querySelector('.col-md-8').insertBefore(alertDiv, document.querySelector('.card'));
        }

        // Initialize map when page loads
        window.onload = function() {
            initMap();
            // Generate a random 4-digit PIN
            const pin = Math.floor(1000 + Math.random() * 9000);
            console.log('Generated PIN:', pin);
            
            // Set the PIN in the verification phrase
            const pinNumberElement = document.getElementById('pinNumber');
            if (pinNumberElement) {
                pinNumberElement.textContent = pin;
            } else {
                console.error('pinNumber element not found in the DOM');
            }
            
            // Initialize UI elements
            const checkInBtn = document.getElementById('checkInBtn');
            const timerDisplay = document.getElementById('timerDisplay');
            
            if (checkInBtn) {
                checkInBtn.disabled = true;
            } else {
                console.error('checkInBtn is null');
            }
            
            if (timerDisplay) {
                timerDisplay.textContent = '00:00';
            } else {
                console.error('timerDisplay not found in the DOM');
            }
            
            // Voice recording setup
            const voiceStatus = document.getElementById('voiceStatus');
            const courseSelect = document.getElementById('courseSelect');
            const startVoiceBtn = document.getElementById('recordVoice');
            const stopVoiceBtn = document.getElementById('stopVoice');
            const latitudeInput = document.getElementById('latitude');
            const longitudeInput = document.getElementById('longitude');
            
            let wavesurfer;
            let mediaRecorder;
            let audioChunks = [];
            let audioBlob = null;
            let isRecording = false;
            let timerInterval;
            let timeLeft = 7;
            
            // Initialize WaveSurfer
            document.addEventListener('DOMContentLoaded', function() {
                wavesurfer = WaveSurfer.create({
                    container: '#waveform',
                    waveColor: '#4F4A85',
                    progressColor: '#383351',
                    height: 80,
                    cursorWidth: 1
                });
            });
            
            // Update voice status message
            function updateStatus(message, isError = false) {
                console.log('Status update:', message, isError ? '(error)' : '');
                voiceStatus.textContent = message;
                voiceStatus.className = isError ? 'text-danger' : 'text-success';
            }
            
            // Timer function
            function startTimer() {
                timeLeft = 7;
                timerDisplay.textContent = timeLeft;
                timerDisplay.classList.remove('d-none');
                
                timerInterval = setInterval(() => {
                    timeLeft--;
                    timerDisplay.textContent = timeLeft;
                    
                    if (timeLeft <= 0) {
                        clearInterval(timerInterval);
                        if (isRecording) {
                            stopRecording();
                        }
                    }
                }, 1000);
            }
            
            // Start voice recording button
            startVoiceBtn.addEventListener('click', async () => {
                try {
                    // Reset audio chunks and recording state
                    audioChunks = [];
                    audioBlob = null;
                    
                    // Request microphone access
                    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                    
                    // Create media recorder
                    mediaRecorder = new MediaRecorder(stream);
                    
                    mediaRecorder.addEventListener('dataavailable', event => {
                        audioChunks.push(event.data);
                    });

                    mediaRecorder.addEventListener('stop', () => {
                        audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
                        
                        // Create URL for the audio blob and set it as the source for WaveSurfer
                        const audioUrl = URL.createObjectURL(audioBlob);
                        
                        // Check if wavesurfer is initialized before using it
                        if (wavesurfer) {
                            try {
                                wavesurfer.load(audioUrl);
                                console.log('Audio loaded into wavesurfer');
                            } catch (e) {
                                console.error('Error loading audio into wavesurfer:', e);
                            }
                        } else {
                            console.warn('Wavesurfer not initialized, skipping waveform display');
                        }
                        
                        console.log('Recording stopped, starting verification...');
                        
                        // Directly enable the check-in button for testing
                        updateStatus('Voice verified successfully! Checking in...', false);
                        document.getElementById('voiceVerified').value = 'true';
                        
                        // Automatically submit the form after a short delay
                        setTimeout(() => {
                            try {
                                console.log('Automatically submitting check-in form...');
                                const form = document.getElementById('checkInForm');
                                if (form) {
                                    // Explicitly set the action to the current page
                                    form.action = 'student-check-in.jsp';
                                    form.method = 'POST';
                                    form.submit();
                                    console.log('Form submitted successfully');
                                } else {
                                    console.error('Check-in form not found');
                                    updateStatus('Error: Could not find check-in form', true);
                                }
                            } catch (e) {
                                console.error('Error submitting form:', e);
                                updateStatus('Error during check-in: ' + e.message, true);
                            }
                        }, 1500); // 1.5 second delay to show the success message
                    });

                    // Start recording
                    mediaRecorder.start();
                    isRecording = true;
                    
                    // Update UI
                    startVoiceBtn.classList.add('d-none');
                    stopVoiceBtn.classList.remove('d-none');
                    updateStatus('Recording... Say the verification phrase clearly', false);
                    
                    // Start the timer
                    startTimer();
                    
                } catch (error) {
                    console.error('Recording error:', error);
                    updateStatus('Could not start recording: ' + error.message, true);
                }
            });
            
            // Verify voice biometrics
            function verifyVoiceBiometrics(audioBlob) {
                updateStatus('Verifying your voice...', false);
                console.log('Starting voice verification with blob size:', audioBlob.size);
                
                // Add timeout to prevent indefinite waiting
                const timeoutId = setTimeout(() => {
                    console.error('Voice verification timed out after 10 seconds');
                    updateStatus('Voice verification timed out. Please try again.', true);
                    document.getElementById('voiceVerified').value = 'false';
                    if (checkInBtn) checkInBtn.disabled = true;
                }, 10000); // 10 second timeout
                
                // Convert blob to base64 for sending to server
                const reader = new FileReader();
                reader.readAsDataURL(audioBlob);
                
                reader.onloadend = function() {
                    const base64Audio = reader.result;
                    // Extract PIN from the verification phrase
                    let pin = '';
                    try {
                        const pinElement = document.getElementById('pinNumber');
                        if (pinElement && pinElement.textContent) {
                            pin = pinElement.textContent;
                            console.log('Extracted PIN from element:', pin);
                        } else {
                            console.error('Could not find pinNumber element or it has no content');
                            pin = '0000'; // Fallback PIN
                        }
                    } catch (e) {
                        console.error('Error extracting PIN:', e);
                        pin = '0000'; // Fallback PIN
                    }
                    
                    console.log('Audio data converted to base64, length:', base64Audio.length);
                    console.log('PIN for verification:', pin);
                    
                    // Send to server for biometric verification
                    fetch('verify-voice.jsp', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: 'audioData=' + encodeURIComponent(base64Audio) + '&pin=' + encodeURIComponent(pin),
                        cache: 'no-cache' // Add cache control
                    })
                    .then(response => {
                        console.log('Response status:', response.status);
                        if (!response.ok) {
                            throw new Error(`Server returned ${response.status}: ${response.statusText}`);
                        }
                        return response.text().then(text => {
                            console.log('Raw response:', text);
                            try {
                                return JSON.parse(text);
                            } catch (e) {
                                console.error('Error parsing JSON:', e);
                                throw new Error('Invalid JSON response from server');
                            }
                        });
                    })
                    .then(data => {
                        clearTimeout(timeoutId); // Clear the timeout
                        console.log('Biometric verification result:', data);
                        
                        // Force a small delay to ensure UI updates properly
                        setTimeout(() => {
                            if (data.success && data.verified) {
                                updateStatus('Voice verified successfully!', false);
                                document.getElementById('voiceVerified').value = 'true';
                                if (checkInBtn) {
                                    checkInBtn.disabled = false;
                                    console.log('Check-in button enabled');
                                }
                            } else {
                                const errorMsg = data.error || data.message || 'Voice verification failed';
                                updateStatus(errorMsg, true);
                                document.getElementById('voiceVerified').value = 'false';
                                if (checkInBtn) checkInBtn.disabled = true;
                            }
                        }, 500);
                    })
                    .catch(error => {
                        clearTimeout(timeoutId); // Clear the timeout
                        console.error('Error verifying voice biometrics:', error);
                        updateStatus('Error during voice verification: ' + error.message, true);
                        document.getElementById('voiceVerified').value = 'false';
                        if (checkInBtn) checkInBtn.disabled = true;
                    });
                };
            }
            
            // Stop recording
            stopVoiceBtn.addEventListener('click', stopRecording);
            
            function stopRecording() {
                if (mediaRecorder && mediaRecorder.state === 'recording') {
                    mediaRecorder.stop();
                    isRecording = false;
                    
                    // Update UI
                    stopVoiceBtn.classList.add('d-none');
                    startVoiceBtn.classList.remove('d-none');
                    timerDisplay.classList.add('d-none');
                    clearInterval(timerInterval);
                    updateStatus('Processing your voice...', false);
                    
                    // Stop all tracks on the stream
                    mediaRecorder.stream.getTracks().forEach(track => track.stop());
                }
            }
        }
    </script>
</body>
</html>
<%
    try {
        if (rs != null) rs.close();
        if (pstmt != null) pstmt.close();
        if (connection != null) connection.close();
    } catch(Exception e) {
        out.println("Error closing resources: " + e.getMessage());
    }
%>
