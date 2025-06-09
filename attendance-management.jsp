<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in first");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendance Management - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .navbar {
            background-color: #2c3e50;
        }
        .btn-manage {
            background-color: #3498db;
            color: white;
        }
        .btn-manage:hover {
            background-color: #2980b9;
            color: white;
        }
        .btn-reset {
            background-color: #e74c3c;
            color: white;
        }
        .btn-reset:hover {
            background-color: #c0392b;
            color: white;
        }
    </style>
</head>
<body class="d-flex flex-column min-vh-100">
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
                        <a class="nav-link" href="lecturer-dashboard.jsp">
                            <i class="fas fa-home me-1"></i>Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="logout.jsp">
                            <i class="fas fa-sign-out-alt me-1"></i>Logout
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container flex-grow-1">
        <div class="row">
            <div class="col-md-12 mb-4">
                <div class="d-flex justify-content-between align-items-center">
                    <h2><i class="fas fa-clipboard-list me-2"></i>Attendance Management</h2>
                    <div class="btn-group">
                        <button class="btn btn-reset" onclick="manageAttendance('reset')">
                            <i class="fas fa-trash-alt me-1"></i>Reset Current Week
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mb-4">
            <div class="col-md-12">

            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <div class="card shadow-sm">
                    <div class="card-body">
                        <div id="currentAttendanceData">
                            <!-- Current week attendance data will be loaded here -->
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <footer class="footer mt-4 py-3 bg-light">
        <div class="container text-center">
            <span class="text-muted">© 2025 Attendify. All rights reserved.</span>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            loadAttendanceData();
        });

        function loadAttendanceData() {
            fetch('attendance-management')
                .then(response => {
                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = 'login.jsp?error=Please log in first';
                            return;
                        }
                        throw new Error('Network response was not ok');
                    }
                    return response.json();
                })
                .then(data => {
                    // Handle the attendance data
                    const container = document.getElementById('currentAttendanceData');
                    if (data.error) {
                        container.innerHTML = `<div class="alert alert-danger">${data.error}</div>`;
                        return;
                    }
                    
                    if (!data.attendance || data.attendance.length === 0) {
                        container.innerHTML = '<div class="alert alert-info">No attendance records found for the current week.</div>';
                        return;
                    }

                    let html = `
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Student</th>
                                    <th>Course</th>
                                    <th>Check-in Time</th>
                                </tr>
                            </thead>
                            <tbody>
                    `;

                    data.attendance.forEach(record => {
                        html += `
                            <tr>
                                <td>${record.date}</td>
                                <td>${record.student_name}</td>
                                <td>${record.course_name}</td>
                                <td>${record.check_in_time}</td>
                            </tr>
                        `;
                    });

                    html += '</tbody></table>';
                    container.innerHTML = html;
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('currentAttendanceData').innerHTML = 
                        '<div class="alert alert-danger">Error loading attendance data. Please try again later.</div>';
                });
        }

        function manageAttendance(action) {
            if (!confirm('Are you sure you want to ' + action + ' the attendance data?')) {
                return;
            }

            fetch('attendance-management', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=' + action
            })
            .then(response => {
                if (!response.ok) {
                    if (response.status === 401) {
                        window.location.href = 'login.jsp?error=Please log in first';
                        return;
                    }
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    loadAttendanceData(); // Reload the data
                } else {
                    alert('Error: ' + (data.message || 'Unknown error occurred'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error performing operation. Please try again.');
            });
        }

        function loadAttendanceData(view = 'current') {
            const targetDiv = view === 'current' ? 'currentAttendanceData' : 'archivedAttendanceData';
            fetch(`attendance-management?view=${view}`)
                .then(response => response.json())
                .then(data => {
                    const attendanceDiv = document.getElementById(targetDiv);
                    if (data.records && data.records.length > 0) {
                        let html = '<div class="table-responsive"><table class="table table-striped">';
                        html += '<thead><tr>';
                        html += '<th>Student Name</th>';
                        html += '<th>Course</th>';
                        html += '<th>Date</th>';
                        html += '<th>Time</th>';
                        html += '<th>Location</th>';
                        html += '<th>Voice Verified</th>';

                        html += '</tr></thead><tbody>';

                        data.records.forEach(record => {
                            html += '<tr>';
                            html += `<td>${record.studentName}</td>`;
                            html += `<td>${record.courseName} (${record.courseCode})</td>`;
                            html += `<td>${record.checkInDate}</td>`;
                            html += `<td>${record.checkInTime}</td>`;
                            html += `<td><a href="https://www.google.com/maps?q=${record.latitude},${record.longitude}" target="_blank">View Location</a></td>`;
                            html += `<td>${record.voiceVerified ? '<span class="text-success">Yes</span>' : '<span class="text-danger">No</span>'}</td>`;

                            html += '</tr>';
                        });

                        html += '</tbody></table></div>';
                        attendanceDiv.innerHTML = html;
                    } else {
                        attendanceDiv.innerHTML = `<div class="alert alert-info">No ${view} attendance records found.</div>`;
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    const attendanceDiv = document.getElementById(targetDiv);
                    attendanceDiv.innerHTML = '<div class="alert alert-danger">Error loading attendance data. Please try again later.</div>';
                });
        }

        function manageAttendance(action, courseCode = '') {
            if (!confirm(`Are you sure you want to ${action} the attendance records?`)) {
                return;
            }

            fetch('attendance-management', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `action=${action}${courseCode ? '&courseCode=' + courseCode : ''}`
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showAlert(data.message, 'success');
                    loadAttendanceData('current');

                } else {
                    showAlert(data.message, 'danger');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showAlert('Error performing action. Please try again later.', 'danger');
            });
        }

        function showAlert(message, type) {
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert alert-${type} alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3`;
            alertDiv.style.zIndex = '1050';
            alertDiv.role = 'alert';
            alertDiv.innerHTML = `
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            `;
            document.body.appendChild(alertDiv);
            setTimeout(() => {
                alertDiv.remove();
            }, 5000);
        }
    </script>
</body>
</html>
