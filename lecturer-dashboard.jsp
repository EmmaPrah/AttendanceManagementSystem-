<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
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
    <title>Lecturer Dashboard - Attendify</title>
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
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-chalkboard-teacher me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link active" href="lecturer-dashboard.jsp">
                            <i class="fas fa-home me-1"></i>Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-classroom-locations.jsp">
                            <i class="fas fa-map-marker-alt me-1"></i>Classroom Locations
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp">
                            <i class="fas fa-book me-1"></i>Manage Courses
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp">
                            <i class="fas fa-clipboard-list me-1"></i>View Attendance
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="enrolled-students.jsp">
                            <i class="fas fa-users me-1"></i>Enrolled Students
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
                                            "SELECT COUNT(*) FROM courses WHERE lecturer_id = ?"
                                        );
                                        pstmt.setString(1, lecturerId);
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
                                <h6 class="card-subtitle mb-2">Total Students</h6>
                                <%
                                    int totalStudents = 0;
                                    try {
                                        pstmt = connection.prepareStatement(
                                            "SELECT COUNT(DISTINCT cs.student_id) " +
                                            "FROM course_selections cs " +
                                            "JOIN courses c ON cs.course_code = c.course_code " +
                                            "WHERE c.lecturer_id = ?"
                                        );
                                        pstmt.setString(1, lecturerId);
                                        rs = pstmt.executeQuery();
                                        if (rs.next()) {
                                            totalStudents = rs.getInt(1);
                                        }
                                    } catch (Exception e) {
                                        out.println("Error: " + e.getMessage());
                                    }
                                %>
                                <h3 class="card-title mb-0"><%= totalStudents %></h3>
                            </div>
                            <i class="fas fa-users stat-icon"></i>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card stat-card">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-subtitle mb-2">Today's Attendance</h6>
                                <%
                                    int todayAttendance = 0;
                                    try {
                                        pstmt = connection.prepareStatement(
                                            "SELECT COUNT(*) FROM attendance a " +
                                            "JOIN courses c ON a.course_code = c.course_code " +
                                            "WHERE c.lecturer_id = ? AND a.check_in_date = date('now')"
                                        );
                                        pstmt.setString(1, lecturerId);
                                        rs = pstmt.executeQuery();
                                        if (rs.next()) {
                                            todayAttendance = rs.getInt(1);
                                        }
                                    } catch (Exception e) {
                                        out.println("Error: " + e.getMessage());
                                    }
                                %>
                                <h3 class="card-title mb-0"><%= todayAttendance %></h3>
                            </div>
                            <i class="fas fa-clipboard-check stat-icon"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Your Courses</h5>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Course Code</th>
                                        <th>Course Name</th>
                                        <th>Location Set</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try {
                                            pstmt = connection.prepareStatement(
                                                "SELECT c.course_code, c.course_name, " +
                                                "CASE WHEN cl.course_code IS NOT NULL THEN 'Yes' ELSE 'No' END as has_location " +
                                                "FROM courses c " +
                                                "LEFT JOIN classroom_locations cl ON c.course_code = cl.course_code " +
                                                "WHERE c.lecturer_id = ?"
                                            );
                                            pstmt.setString(1, lecturerId);
                                            rs = pstmt.executeQuery();
                                            
                                            while (rs.next()) {
                                                String locationStatus = rs.getString("has_location");
                                                String badgeClass = "Yes".equals(locationStatus) ? "bg-success" : "bg-warning";
                                    %>
                                    <tr>
                                        <td><%= rs.getString("course_code") %></td>
                                        <td><%= rs.getString("course_name") %></td>
                                        <td><span class="badge <%= badgeClass %>"><%= locationStatus %></span></td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            out.println("<tr><td colspan='3'>Error loading courses: " + e.getMessage() + "</td></tr>");
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-6">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Recent Attendance</h5>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Course</th>
                                        <th>Student</th>
                                        <th>Time</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try {
                                            Class.forName("org.sqlite.JDBC");
                                            connection = DriverManager.getConnection(jdbcURL);
                                            pstmt = connection.prepareStatement(
                                                "SELECT c.course_name, u.full_name, a.check_in_time, a.check_in_date " +
                                                "FROM attendance a " +
                                                "JOIN courses c ON a.course_code = c.course_code " +
                                                "JOIN users u ON a.student_id = u.user_id " +
                                                "WHERE c.lecturer_id = ? " +
                                                "AND date(a.check_in_date) = date('now', 'localtime') " +
                                                "ORDER BY a.check_in_date DESC, a.check_in_time DESC LIMIT 5"
                                            );
                                            pstmt.setString(1, lecturerId);
                                            rs = pstmt.executeQuery();
                                            
                                            while (rs.next()) {
                                    %>
                                    <tr>
                                        <td><%= rs.getString("course_name") %></td>
                                        <td><%= rs.getString("full_name") %></td>
                                        <td><%= rs.getString("check_in_date") %> <%= rs.getString("check_in_time") %></td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            out.println("<tr><td colspan='3'>Error loading attendance: " + e.getMessage() + "</td></tr>");
                                        } finally {
                                            try {
                                                if (rs != null) rs.close();
                                                if (pstmt != null) pstmt.close();
                                                if (connection != null) connection.close();
                                            } catch (Exception e) {
                                                out.println("Error closing resources: " + e.getMessage());
                                            }
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
</body>
</html>