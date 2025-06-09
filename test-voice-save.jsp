<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test Voice Registration</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .recording-box {
            border: 1px solid #ccc;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        .button {
            background-color: #4CAF50;
            border: none;
            color: white;
            padding: 10px 20px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 16px;
            margin: 4px 2px;
            cursor: pointer;
            border-radius: 5px;
        }
        .button.stop {
            background-color: #f44336;
        }
        .button.save {
            background-color: #2196F3;
        }
        .status {
            margin-top: 10px;
            padding: 10px;
            border-radius: 5px;
        }
        .error {
            background-color: #ffebee;
            color: #c62828;
        }
        .success {
            background-color: #e8f5e9;
            color: #2e7d32;
        }
    </style>
</head>
<body>
    <h1>Test Voice Registration</h1>
    <p>This is a simplified test page to diagnose voice registration issues.</p>
    
    <div class="recording-box">
        <h3>Voice Registration</h3>
        <p>PIN: <span id="pinNumber">1234</span></p>
        <p>Please say: "PIN <span id="pinDisplay">1234</span> <span id="nameDisplay"><%=session.getAttribute("userName")%></span>"</p>
        
        <div id="timer">00:00</div>
        <div id="waveform"></div>
        
        <div id="statusMessage" class="status"></div>
        
        <button id="startButton" class="button">Start Recording</button>
        <button id="stopButton" class="button stop" disabled>Stop Recording</button>
        <button id="saveButton" class="button save" disabled>Save Voice Print</button>
    </div>
    
    <div id="debugInfo"></div>
    
    <script>
        // DOM elements
        const startButton = document.getElementById('startButton');
        const stopButton = document.getElementById('stopButton');
        const saveButton = document.getElementById('saveButton');
        const statusMessage = document.getElementById('statusMessage');
        const timer = document.getElementById('timer');
        const waveform = document.getElementById('waveform');
        const debugInfo = document.getElementById('debugInfo');
        const pinNumber = document.getElementById('pinNumber');
        const pinDisplay = document.getElementById('pinDisplay');
        
        // Set a random PIN
        const randomPin = Math.floor(1000 + Math.random() * 9000);
        pinNumber.textContent = randomPin;
        pinDisplay.textContent = randomPin;
        
        // Recording variables
        let mediaRecorder;
        let audioChunks = [];
        let startTime;
        let timerInterval;
        let audioBlob;
        
        // Start recording
        startButton.addEventListener('click', async () => {
            try {
                statusMessage.textContent = 'Requesting microphone access...';
                statusMessage.className = 'status';
                
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                
                mediaRecorder = new MediaRecorder(stream);
                audioChunks = [];
                
                mediaRecorder.addEventListener('dataavailable', event => {
                    audioChunks.push(event.data);
                });
                
                mediaRecorder.addEventListener('stop', () => {
                    audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
                    const audioSize = audioBlob.size;
                    
                    debugInfo.innerHTML += `<p>Recording stopped. Audio size: ${audioSize} bytes</p>`;
                    
                    if (audioSize < 10000) {
                        statusMessage.textContent = 'Recording too short or no sound detected. Please try again.';
                        statusMessage.className = 'status error';
                        return;
                    }
                    
                    statusMessage.textContent = 'Recording complete. You can now save your voice print.';
                    statusMessage.className = 'status success';
                    saveButton.disabled = false;
                });
                
                // Start recording
                mediaRecorder.start();
                startTime = Date.now();
                updateTimer();
                timerInterval = setInterval(updateTimer, 1000);
                
                // Update UI
                startButton.disabled = true;
                stopButton.disabled = false;
                statusMessage.textContent = 'Recording... Please speak clearly.';
                
                // Auto-stop after 7 seconds
                setTimeout(() => {
                    if (mediaRecorder && mediaRecorder.state === 'recording') {
                        stopRecording();
                    }
                }, 7000);
                
            } catch (error) {
                console.error('Error accessing microphone:', error);
                statusMessage.textContent = 'Error accessing microphone: ' + error.message;
                statusMessage.className = 'status error';
            }
        });
        
        // Stop recording
        stopButton.addEventListener('click', stopRecording);
        
        function stopRecording() {
            if (mediaRecorder && mediaRecorder.state === 'recording') {
                mediaRecorder.stop();
                clearInterval(timerInterval);
                
                // Update UI
                startButton.disabled = false;
                stopButton.disabled = true;
            }
        }
        
        // Update timer display
        function updateTimer() {
            const elapsedTime = Math.floor((Date.now() - startTime) / 1000);
            const minutes = Math.floor(elapsedTime / 60).toString().padStart(2, '0');
            const seconds = (elapsedTime % 60).toString().padStart(2, '0');
            timer.textContent = `${minutes}:${seconds}`;
        }
        
        // Save voice print
        saveButton.addEventListener('click', async () => {
            if (!audioBlob) {
                statusMessage.textContent = 'No recording available. Please record your voice first.';
                statusMessage.className = 'status error';
                return;
            }
            
            statusMessage.textContent = 'Saving voice print...';
            statusMessage.className = 'status';
            
            try {
                // Convert audio blob to base64
                const reader = new FileReader();
                reader.readAsDataURL(audioBlob);
                
                reader.onloadend = async () => {
                    const base64Audio = reader.result;
                    debugInfo.innerHTML += `<p>Sending audio data, length: ${base64Audio.length}</p>`;
                    debugInfo.innerHTML += `<p>PIN: ${pinNumber.textContent}</p>`;
                    
                    // Send to our simplified endpoint
                    const formData = new FormData();
                    formData.append('audioData', base64Audio);
                    formData.append('pin', pinNumber.textContent);
                    
                    try {
                        const response = await fetch('simple-voice-save.jsp', {
                            method: 'POST',
                            body: formData
                        });
                        
                        debugInfo.innerHTML += `<p>Response status: ${response.status}</p>`;
                        
                        if (response.ok) {
                            const result = await response.json();
                            
                            if (result.success) {
                                statusMessage.textContent = 'Voice print saved successfully!';
                                statusMessage.className = 'status success';
                                saveButton.disabled = true;
                            } else {
                                statusMessage.textContent = 'Error saving voice print: ' + result.error;
                                statusMessage.className = 'status error';
                            }
                        } else {
                            throw new Error('Server returned ' + response.status);
                        }
                    } catch (error) {
                        console.error('Error saving voice print:', error);
                        debugInfo.innerHTML += `<p>Error: ${error.message}</p>`;
                        statusMessage.textContent = 'Error saving voice print: ' + error.message;
                        statusMessage.className = 'status error';
                    }
                };
            } catch (error) {
                console.error('Error processing audio:', error);
                statusMessage.textContent = 'Error processing audio: ' + error.message;
                statusMessage.className = 'status error';
            }
        });
    </script>
</body>
</html>
