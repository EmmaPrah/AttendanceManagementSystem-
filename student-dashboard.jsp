<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a student");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    String fullName = (String) session.getAttribute("fullName");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Dashboard - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body { 
            background-color: #f0f8ff;
            min-height: 100vh;
        }
        .navbar { 
            background-color: #007bff;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            margin-bottom: 20px;
            transition: transform 0.2s;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .stat-card {
            background: linear-gradient(45deg, #007bff, #00a5ff);
            color: white;
        }
        .stat-icon {
            font-size: 2.5rem;
            opacity: 0.8;
        }
        .quick-action {
            text-decoration: none;
            color: inherit;
        }
        .quick-action:hover .card {
            transform: translateY(-5px);
        }
        .attendance-status {
            font-weight: bold;
        }
        .status-present {
            color: #28a745;
        }
        .status-absent {
            color: #dc3545;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-graduation-cap me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link active" href="student-dashboard.jsp">
                            <i class="fas fa-home me-1"></i>Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="select-courses.jsp">
                            <i class="fas fa-book me-1"></i>Select Courses
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="student-check-in.jsp">
                            <i class="fas fa-check-circle me-1"></i>Check-In
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance-record.jsp">
                            <i class="fas fa-history me-1"></i>Attendance Record
                        </a>
                    </li>
                </ul>
                <ul class="navbar-nav">
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="fas fa-user-circle me-1"></i><%= fullName %>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><a class="dropdown-item" href="profile.jsp">Profile</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp">Logout</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="row mb-4">
            <div class="col-md-4">
                <div class="card stat-card">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-subtitle mb-2">Total Courses</h6>
                                <%
                                    int totalCourses = 0;
                                    try {
                                        connection = DriverManager.getConnection(jdbcURL);
                                        pstmt = connection.prepareStatement(
                                            "SELECT COUNT(*) FROM course_selections WHERE student_id = ?"
                                        );
                                        pstmt.setString(1, studentId);
                                        rs = pstmt.executeQuery();
                                        if (rs.next()) {
                                            totalCourses = rs.getInt(1);
                                        }
                                    } catch (Exception e) {
                                        out.println("Error: " + e.getMessage());
                                    }
                                %>
                                <h3 class="card-title mb-0"><%= totalCourses %></h3>
                            </div>
                            <i class="fas fa-book stat-icon"></i>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <div class="card stat-card">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-subtitle mb-2">Total Check-ins</h6>
                                <%
                                    int totalCheckins = 0;
                                    try {
                                        pstmt = connection.prepareStatement(
                                            "SELECT COUNT(*) FROM attendance WHERE student_id = ?"
                                        );
                                        pstmt.setString(1, studentId);
                                        rs = pstmt.executeQuery();
                                        if (rs.next()) {
                                            totalCheckins = rs.getInt(1);
                                        }
                                    } catch (Exception e) {
                                        out.println("Error: " + e.getMessage());
                                    }
                                %>
                                <h3 class="card-title mb-0"><%= totalCheckins %></h3>
                            </div>
                            <i class="fas fa-check-circle stat-icon"></i>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <div class="card stat-card">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-subtitle mb-2">Today's Check-ins</h6>
                                <%
                                    int todayCheckins = 0;
                                    try {
                                        pstmt = connection.prepareStatement(
                                            "SELECT COUNT(*) FROM attendance WHERE student_id = ? AND check_in_date = date('now')"
                                        );
                                        pstmt.setString(1, studentId);
                                        rs = pstmt.executeQuery();
                                        if (rs.next()) {
                                            todayCheckins = rs.getInt(1);
                                        }
                                    } catch (Exception e) {
                                        out.println("Error: " + e.getMessage());
                                    }
                                %>
                                <h3 class="card-title mb-0"><%= todayCheckins %></h3>
                            </div>
                            <i class="fas fa-calendar-check stat-icon"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Today's Classes</h5>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Course Code</th>
                                        <th>Course Name</th>
                                        <th>Lecturer</th>
                                        <th>Status</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try {
                                            pstmt = connection.prepareStatement(
                                                "SELECT c.course_code, c.course_name, u.full_name as lecturer_name, " +
                                                "CASE WHEN a.student_id IS NOT NULL THEN 'Present' ELSE 'Not Checked In' END as status " +
                                                "FROM course_selections cs " +
                                                "JOIN courses c ON cs.course_code = c.course_code " +
                                                "JOIN users u ON c.lecturer_id = u.user_id " +
                                                "LEFT JOIN attendance a ON c.course_code = a.course_code " +
                                                "AND a.student_id = ? AND a.check_in_date = date('now') " +
                                                "WHERE cs.student_id = ?"
                                            );
                                            pstmt.setString(1, studentId);
                                            pstmt.setString(2, studentId);
                                            rs = pstmt.executeQuery();
                                            
                                            while (rs.next()) {
                                                String status = rs.getString("status");
                                                String statusClass = "Present".equals(status) ? "status-present" : "status-absent";
                                    %>
                                    <tr>
                                        <td><%= rs.getString("course_code") %></td>
                                        <td><%= rs.getString("course_name") %></td>
                                        <td><%= rs.getString("lecturer_name") %></td>
                                        <td><span class="attendance-status <%= statusClass %>"><%= status %></span></td>
                                        <td>
                                            <% if (!"Present".equals(status)) { %>
                                                <a href="student-check-in.jsp?course=<%= rs.getString("course_code") %>" 
                                                   class="btn btn-primary btn-sm">
                                                    <i class="fas fa-check me-1"></i>Check In
                                                </a>
                                            <% } else { %>
                                                <span class="badge bg-success">
                                                    <i class="fas fa-check-circle me-1"></i>Checked In
                                                </span>
                                            <% } %>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            out.println("<tr><td colspan='5'>Error loading courses: " + e.getMessage() + "</td></tr>");
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Quick Actions</h5>
                        <a href="student-check-in.jsp" class="quick-action">
                            <div class="card mb-3">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="flex-shrink-0">
                                            <i class="fas fa-check-circle fa-2x text-primary"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <h6 class="mb-1">Check In</h6>
                                            <p class="mb-0 text-muted">Mark your attendance for class</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </a>
                        <a href="view-attendance-record.jsp" class="quick-action">
                            <div class="card mb-3">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="flex-shrink-0">
                                            <i class="fas fa-history fa-2x text-primary"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <h6 class="mb-1">View Record</h6>
                                            <p class="mb-0 text-muted">Check your attendance history</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </a>
                        <a href="select-courses.jsp" class="quick-action">
                            <div class="card mb-3">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="flex-shrink-0">
                                            <i class="fas fa-book fa-2x text-primary"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <h6 class="mb-1">Select Courses</h6>
                                            <p class="mb-0 text-muted">Enroll in available courses</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </a>
                        <a href="profile.jsp" class="quick-action">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="flex-shrink-0">
                                            <i class="fas fa-user-circle fa-2x text-primary"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <h6 class="mb-1">Profile</h6>
                                            <p class="mb-0 text-muted">View and edit your profile</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Voice Registration Card -->
        <div class="col-md-6 mb-4">
            <div class="card h-100">
                <div class="card-body">
                    <h5 class="card-title">
                        <i class="fas fa-microphone me-2"></i>Voice Authentication
                    </h5>
                    <p class="card-text">Register your voice for secure attendance check-in.</p>
                    <%
                        // Check if student has registered their voice
                        boolean hasVoicePrint = false;
                        try {
                            Class.forName("org.sqlite.JDBC");
                            Connection voiceConn = DriverManager.getConnection("jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db");
                            PreparedStatement voiceStmt = voiceConn.prepareStatement("SELECT 1 FROM voice_prints WHERE student_id = ?");
                            voiceStmt.setString(1, studentId);
                            ResultSet voiceRs = voiceStmt.executeQuery();
                            hasVoicePrint = voiceRs.next();
                            voiceRs.close();
                            voiceStmt.close();
                            voiceConn.close();
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    %>
                    <% if (hasVoicePrint) { %>
                        <div class="alert alert-success mb-3">
                            <i class="fas fa-check-circle me-2"></i>Voice print registered with Azure
                        </div>
                        <p class="small text-muted mb-3">Your voice is securely registered with Azure Cognitive Services for biometric verification.</p>
                        <a href="register-voice.jsp" class="btn btn-outline-primary">
                            <i class="fas fa-redo me-2"></i>Update Voice Print
                        </a>
                    <% } else { %>
                        <div class="alert alert-warning mb-3">
                            <i class="fas fa-exclamation-circle me-2"></i>Voice print not registered
                        </div>
                        <p class="small text-muted mb-3">You must register your voice to use the secure attendance check-in system.</p>
                        <a href="register-voice.jsp" class="btn btn-primary">
                            <i class="fas fa-microphone me-2"></i>Register Voice
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>