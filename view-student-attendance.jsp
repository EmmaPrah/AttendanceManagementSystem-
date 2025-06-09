<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
    String studentId = request.getParameter("studentId");
    
    if (studentId == null || studentId.isEmpty()) {
        response.sendRedirect("view-attendance.jsp?error=Student ID is required");
        return;
    }
    
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Get student information
    String studentName = "";
    String studentDepartment = "";
    int studentLevel = 0;
    
    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);
        pstmt = connection.prepareStatement(
            "SELECT full_name, department, level FROM users WHERE user_id = ?"
        );
        pstmt.setString(1, studentId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            studentName = rs.getString("full_name");
            studentDepartment = rs.getString("department");
            studentLevel = rs.getInt("level");
        } else {
            response.sendRedirect("view-attendance.jsp?error=Student not found");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect("view-attendance.jsp?error=" + e.getMessage());
        return;
    } finally {
        if (rs != null) rs.close();
        if (pstmt != null) pstmt.close();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Attendance - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .attendance-card {
            border-radius: 15px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: transform 0.2s;
        }
        .attendance-card:hover {
            transform: translateY(-5px);
        }
        .stats-card {
            background: linear-gradient(45deg, #0072ff, #00c6ff);
            color: white;
            border: none;
        }
        .table-container {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .student-info {
            background: #f8f9fa;
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body class="bg-light">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="lecturer-dashboard.jsp">
                <i class="fas fa-chalkboard-teacher me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="lecturer-dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp">View Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp">Manage Courses</a>
                    </li>
                </ul>
                <div class="d-flex">
                    <a href="logout.jsp" class="btn btn-light">
                        <i class="fas fa-sign-out-alt me-2"></i>Logout
                    </a>
                </div>
            </div>
        </div>
    </nav>

    <div class="container my-4">
        <div class="row mb-4">
            <div class="col">
                <h2><i class="fas fa-user-graduate me-2"></i>Student Attendance Records</h2>
                <a href="view-attendance.jsp" class="btn btn-outline-primary mt-2">
                    <i class="fas fa-arrow-left me-2"></i>Back to All Attendance
                </a>
            </div>
        </div>

        <div class="student-info">
            <div class="row">
                <div class="col-md-3">
                    <p class="mb-1 text-muted">Student ID</p>
                    <h5><%= studentId %></h5>
                </div>
                <div class="col-md-3">
                    <p class="mb-1 text-muted">Name</p>
                    <h5><%= studentName %></h5>
                </div>
                <div class="col-md-3">
                    <p class="mb-1 text-muted">Department</p>
                    <h5><%= studentDepartment %></h5>
                </div>
                <div class="col-md-3">
                    <p class="mb-1 text-muted">Level</p>
                    <h5><%= studentLevel %></h5>
                </div>
            </div>
        </div>

        <div class="row mb-4">
            <div class="col-md-4">
                <div class="card stats-card mb-3">
                    <div class="card-body">
                        <h5 class="card-title">Total Attendance Records</h5>
                        <%
                            int totalAttendance = 0;
                            try {
                                pstmt = connection.prepareStatement(
                                    "SELECT COUNT(*) as count FROM attendance a " +
                                    "JOIN courses c ON a.course_code = c.course_code " +
                                    "WHERE a.student_id = ? AND c.lecturer_id = ?"
                                );
                                pstmt.setString(1, studentId);
                                pstmt.setString(2, lecturerId);
                                rs = pstmt.executeQuery();
                                if (rs.next()) {
                                    totalAttendance = rs.getInt("count");
                                }
                            } catch (Exception e) {
                                // Ignore and use default value
                            }
                        %>
                        <h2 class="mb-0"><%= totalAttendance %></h2>
                    </div>
                </div>
            </div>
        </div>

        <div class="table-container">
            <%
                try {
                    // First, get all courses taught by this lecturer that the student is enrolled in
                    pstmt = connection.prepareStatement(
                        "SELECT c.course_code, c.course_name " +
                        "FROM courses c " +
                        "JOIN course_selections cs ON c.course_code = cs.course_code " +
                        "WHERE c.lecturer_id = ? AND cs.student_id = ? " +
                        "ORDER BY c.course_code"
                    );
                    pstmt.setString(1, lecturerId);
                    pstmt.setString(2, studentId);
                    rs = pstmt.executeQuery();
                    
                    boolean hasAnyCourses = false;
                    
                    while (rs.next()) {
                        hasAnyCourses = true;
                        String courseCode = rs.getString("course_code");
                        String courseName = rs.getString("course_name");
                        %>
                        <div class="card mb-4">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0"><%= courseCode %> - <%= courseName %></h5>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>Date</th>
                                                <th>Check-in Time</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                // Get attendance records for this specific course and student
                                                PreparedStatement courseStmt = connection.prepareStatement(
                                                    "SELECT check_in_date, check_in_time " +
                                                    "FROM attendance " +
                                                    "WHERE course_code = ? AND student_id = ? " +
                                                    "ORDER BY check_in_date DESC, check_in_time DESC"
                                                );
                                                courseStmt.setString(1, courseCode);
                                                courseStmt.setString(2, studentId);
                                                ResultSet courseRs = courseStmt.executeQuery();
                                                
                                                boolean hasRecords = false;
                                                
                                                while (courseRs.next()) {
                                                    hasRecords = true;
                                                    %>
                                                    <tr>
                                                        <td><%= courseRs.getString("check_in_date") %></td>
                                                        <td><%= courseRs.getString("check_in_time") %></td>
                                                        <td><span class="badge bg-success">Present</span></td>
                                                    </tr>
                                                    <%
                                                }
                                                
                                                if (!hasRecords) {
                                                    %>
                                                    <tr>
                                                        <td colspan="3" class="text-center text-muted">
                                                            <i class="fas fa-info-circle me-2"></i>No attendance records found for this course
                                                        </td>
                                                    </tr>
                                                    <%
                                                }
                                                
                                                courseRs.close();
                                                courseStmt.close();
                                            %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                        <%
                    }
                    
                    if (!hasAnyCourses) {
                        %>
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle me-2"></i>This student is not enrolled in any of your courses.
                        </div>
                        <%
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    %>
                    <div class="alert alert-danger">
                        <i class="fas fa-exclamation-circle me-2"></i>Error retrieving attendance records: <%= e.getMessage() %>
                    </div>
                    <%
                } finally {
                    try {
                        if (rs != null) rs.close();
                        if (pstmt != null) pstmt.close();
                        if (connection != null) connection.close();
                    } catch (SQLException e) {
                        e.printStackTrace();
                    }
                }
            %>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
