<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a student");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    String studentName = (String) session.getAttribute("fullName");
    String message = request.getParameter("message");
    String messageType = request.getParameter("type");
    
    // Define verification phrase directly (no need for external config)
    String verificationPhrase = "PIN [number] " + studentName;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register Voice - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .navbar {
            background: linear-gradient(to right, #0062cc, #0096ff);
            padding: 1rem;
        }
        .navbar-brand, .nav-link {
            color: white !important;
        }
        .card {
            border: none;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .card-title {
            color: #0062cc;
            font-weight: bold;
            margin-bottom: 1.5rem;
        }
        .recording-box {
            border: 2px dashed #dee2e6;
            border-radius: 10px;
            padding: 2rem;
            text-align: center;
            margin-bottom: 1rem;
        }
        .recording-box.recording {
            border-color: #dc3545;
            background-color: #fff5f5;
        }
        .recording-box.success {
            border-color: #28a745;
            background-color: #f8fff9;
        }
        #waveform {
            width: 100%;
            height: 100px;
            margin: 1rem 0;
            background: #f8f9fa;
            border-radius: 5px;
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
    <!-- Navigation Bar -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="#"><i class="fas fa-calendar-check me-2"></i>Attendify</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="student-dashboard.jsp"><i class="fas fa-home me-1"></i>Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="select-courses.jsp"><i class="fas fa-book me-1"></i>Select Courses</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="check-in.jsp"><i class="fas fa-check-circle me-1"></i>Check In</a>
                    </li>
                </ul>
                <div class="d-flex align-items-center">
                    <span class="text-white me-3"><i class="fas fa-user-circle me-1"></i><%= studentName %></span>
                    <a href="logout.jsp" class="btn btn-light btn-sm"><i class="fas fa-sign-out-alt me-1"></i>Logout</a>
                </div>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="row">
            <div class="col-md-8 mx-auto">
                <div class="card">
                    <div class="card-body">
                        <h3 class="card-title text-center">Voice Registration</h3>
                        
                        <% if (message != null && !message.isEmpty()) { %>
                            <div class="alert alert-<%= "success".equals(messageType) ? "success" : "danger" %> alert-dismissible fade show" role="alert">
                                <%= message %>
                                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                            </div>
                        <% } %>
                        
                        <p class="text-center mb-4">Please register your voice for secure attendance verification.</p>
                        
                        <div class="recording-box mb-4" id="recordingBox">
                            <h5 class="mb-3">Say clearly:</h5>
                            <div class="verification-phrase p-3 bg-light rounded text-center mb-3">
                                <span id="pinDisplay"><%= verificationPhrase %></span>
                            </div>
                            
                            <div id="timerDisplay" class="timer d-none">7</div>
                            
                            <div id="waveform" class="mb-3"></div>
                            
                            <div id="statusMessage" class="mb-3 text-center">Click "Start Recording" when ready</div>
                            
                            <button id="startBtn" class="btn btn-primary me-2">
                                <i class="fas fa-microphone me-2"></i>Start Recording
                            </button>
                            <button id="stopBtn" class="btn btn-danger me-2 d-none">
                                <i class="fas fa-stop-circle me-2"></i>Stop Recording
                            </button>
                            <button id="saveBtn" class="btn btn-success d-none">
                                <i class="fas fa-save me-2"></i>Save Voice Print
                            </button>
                        </div>
                        
                        <div class="d-grid gap-2">
                            <a href="student-dashboard.jsp" class="btn btn-secondary">
                                <i class="fas fa-arrow-left me-2"></i>Back to Dashboard
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://unpkg.com/wavesurfer.js@7"></script>
    <script>
        let wavesurfer;
        let mediaRecorder;
        let audioChunks = [];
        let audioBlob = null;
        let isRecording = false;
        let timerInterval;
        let timeLeft = 7;
        
        // DOM elements
        const recordingBox = document.getElementById('recordingBox');
        const startBtn = document.getElementById('startBtn');
        const stopBtn = document.getElementById('stopBtn');
        const saveBtn = document.getElementById('saveBtn');
        const statusMessage = document.getElementById('statusMessage');
        const timerDisplay = document.getElementById('timerDisplay');
        const pinDisplay = document.getElementById('pinDisplay');
        
        // Generate a random 4-digit PIN
        const randomPin = Math.floor(1000 + Math.random() * 9000);
        pinDisplay.innerHTML = pinDisplay.innerHTML.replace('[number]', randomPin);
        
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

        // Update status message
        function updateStatus(message, isError) {
            statusMessage.textContent = message;
            statusMessage.className = isError ? 'text-danger' : 'text-info';
            statusMessage.style.display = 'block';
        }
        
        // Start recording button
        startBtn.addEventListener('click', startRecording);
        
        // Function to start recording
        function startRecording() {
            // Reset previous recording
            audioChunks = [];
            audioBlob = null;
            wavesurfer.empty();
            saveBtn.classList.add('d-none');
            
            // Request microphone access
            navigator.mediaDevices.getUserMedia({ audio: true })
                .then(stream => {
                    // Create media recorder
                    try {
                        const options = { mimeType: 'audio/webm' };
                        mediaRecorder = new MediaRecorder(stream, options);
                    } catch (e) {
                        console.error('MediaRecorder error:', e);
                        try {
                            // Fallback to default mime type
                            mediaRecorder = new MediaRecorder(stream);
                        } catch (e2) {
                            updateStatus('Error accessing microphone: ' + e2.message, true);
                            return;
                        }
                    }
                    
                    // Set up recording
                    mediaRecorder.ondataavailable = event => {
                        if (event.data.size > 0) {
                            audioChunks.push(event.data);
                        }
                    };
                    
                    mediaRecorder.onstop = processRecording;
                    
                    // Start recording
                    try {
                        mediaRecorder.start();
                        isRecording = true;
                        
                        // Update UI
                        startBtn.classList.add('d-none');
                        stopBtn.classList.remove('d-none');
                        recordingBox.classList.add('recording');
                        updateStatus('Recording... Speak clearly into your microphone', false);
                        
                        // Start timer
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
                    } catch (e) {
                        updateStatus('Error starting recording: ' + e.message, true);
                        console.error('Error starting recording:', e);
                    }
                })
                .catch(error => {
                    console.error('Error accessing microphone:', error);
                    updateStatus('Error accessing microphone. Please ensure your browser has permission to use the microphone.', true);
                });
        }
        
        // Stop recording button
        stopBtn.addEventListener('click', stopRecording);
        
        // Function to stop recording
        function stopRecording() {
            if (isRecording && mediaRecorder && mediaRecorder.state !== 'inactive') {
                clearInterval(timerInterval);
                mediaRecorder.stop();
                isRecording = false;
                
                // Update UI
                stopBtn.classList.add('d-none');
                startBtn.classList.remove('d-none');
                recordingBox.classList.remove('recording');
                timerDisplay.classList.add('d-none');
                clearInterval(timerInterval);
                updateStatus('Processing your recording...', false);
                
                // Stop all tracks on the stream
                mediaRecorder.stream.getTracks().forEach(track => track.stop());
            }
        }
        
        // Process the recording after stopping
        function processRecording() {
            try {
                // Create audio blob from chunks
                const mimeType = mediaRecorder.mimeType || 'audio/webm';
                audioBlob = new Blob(audioChunks, { type: mimeType });
                
                if (!audioBlob || audioBlob.size < 1024) {
                    updateStatus('Recording too short or empty. Please try again with a longer recording.', true);
                    return;
                }
                
                // Create audio URL and load into wavesurfer
                const audioURL = URL.createObjectURL(audioBlob);
                wavesurfer.load(audioURL);
                
                wavesurfer.on('ready', function() {
                    // Show save button when audio is ready
                    saveBtn.classList.remove('d-none');
                    updateStatus('Recording complete. Please review and save your voice print.', false);
                    
                    // Play the audio for review
                    wavesurfer.play();
                });
                
                wavesurfer.on('error', function(err) {
                    console.error('WaveSurfer error:', err);
                    updateStatus('Error processing audio. Please try recording again.', true);
                });
            } catch (error) {
                console.error('Error processing recording:', error);
                updateStatus('Error processing recording: ' + error.message, true);
            }
        }
        
        // Save voice print
        saveBtn.addEventListener('click', function() {
            if (!audioBlob) {
                updateStatus('No recording available. Please record your voice first.', true);
                return;
            }
            
            updateStatus('Saving voice print...', false);
            
            // Convert audio blob to base64
            const reader = new FileReader();
            reader.readAsDataURL(audioBlob);
            
            reader.onloadend = function() {
                const base64Audio = reader.result;
                console.log('Sending audio data, length:', base64Audio.length);
                console.log('PIN:', randomPin);
                
                // Use URLSearchParams instead of FormData for more reliable data transmission
                const params = new URLSearchParams();
                params.append('audioData', base64Audio);
                params.append('pin', randomPin);
                
                fetch('register-voice-data.jsp', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Cache-Control': 'no-cache'
                    },
                    body: params.toString()
                })
                .then(response => {
                    console.log('Response status:', response.status);
                    if (!response.ok) {
                        throw new Error('Server returned ' + response.status);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('Server response:', data);
                    if (data.success) {
                        updateStatus('Voice print saved successfully!', false);
                        saveBtn.disabled = true;
                        
                        // Redirect to dashboard after successful save
                        setTimeout(() => {
                            window.location.href = 'student-dashboard.jsp?message=Voice registered successfully&type=success';
                        }, 1500);
                    } else {
                        updateStatus('Error saving voice print: ' + data.error, true);
                    }
                })
                .catch(error => {
                    console.error('Error saving voice print:', error);
                    updateStatus('Error saving voice print: ' + error.message, true);
                });
            };
        });
    </script>
</body>
</html>
