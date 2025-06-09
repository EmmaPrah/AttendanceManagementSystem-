<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
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
    <title>View Attendance - Attendify</title>
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
                        <a class="nav-link active" href="view-attendance.jsp">View Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp">Manage Courses</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="enrolled-students.jsp">
                            <i class="fas fa-users me-1"></i>Enrolled Students
                        </a>
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
                <h2><i class="fas fa-clipboard-list me-2"></i>Attendance Records</h2>
            </div>
            <div class="col-auto">
                <div class="btn-group">
                    <form action="attendance-management" method="post" style="display: inline;">
                        <input type="hidden" name="action" value="reset">
                        <button type="submit" class="btn btn-danger" onclick="return confirm('Are you sure you want to reset this week\'s attendance? This action cannot be undone.')">
                            <i class="fas fa-trash-alt me-2"></i>Reset Current Week
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <%-- Display success/error messages --%>
        <% if (request.getParameter("success") != null) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i>Operation completed successfully
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        <% if (request.getParameter("error") != null) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><%= request.getParameter("error") %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>

        <div class="row mb-4">
            <div class="col-md-4">
                <div class="card stats-card mb-3">
                    <div class="card-body">
                        <h5 class="card-title">Total Attendance Records</h5>
                        <%
                            try {
                                Class.forName("org.sqlite.JDBC");
                                connection = DriverManager.getConnection(jdbcURL);
                                pstmt = connection.prepareStatement(
                                    "SELECT COUNT(*) as count FROM attendance a " +
                                    "JOIN courses c ON a.course_code = c.course_code " +
                                    "WHERE c.lecturer_id = ?"
                                );
                                pstmt.setString(1, lecturerId);
                                rs = pstmt.executeQuery();
                                if (rs.next()) {
                                    out.println("<h2 class=\"mb-0\">" + rs.getInt("count") + "</h2>");
                                }
                            } catch (Exception e) {
                                out.println("<h2 class=\"mb-0\">0</h2>");
                            }
                        %>
                    </div>
                </div>
            </div>
        </div>

        <div class="table-container">
            <%
                try {
                    Class.forName("org.sqlite.JDBC");
                    connection = DriverManager.getConnection(jdbcURL);
                    
                    // First, get all courses taught by this lecturer
                    pstmt = connection.prepareStatement(
                        "SELECT course_code, course_name FROM courses WHERE lecturer_id = ? ORDER BY course_code"
                    );
                    pstmt.setString(1, lecturerId);
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
                                                <th>Student ID</th>
                                                <th>Student Name</th>
                                                <th>Check-in Time</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                // Get attendance records for this specific course
                                                PreparedStatement courseStmt = connection.prepareStatement(
                                                    "SELECT a.student_id, a.check_in_date, a.check_in_time, u.full_name " +
                                                    "FROM attendance a " +
                                                    "JOIN users u ON a.student_id = u.user_id " +
                                                    "WHERE a.course_code = ? " +
                                                    "ORDER BY a.check_in_date DESC, a.check_in_time DESC"
                                                );
                                                courseStmt.setString(1, courseCode);
                                                ResultSet courseRs = courseStmt.executeQuery();
                                                
                                                boolean hasRecords = false;
                                                
                                                while (courseRs.next()) {
                                                    hasRecords = true;
                                                    %>
                                                    <tr>
                                                        <td><%= courseRs.getString("check_in_date") %></td>
                                                        <td><%= courseRs.getString("student_id") %></td>
                                                        <td><%= courseRs.getString("full_name") %></td>
                                                        <td><%= courseRs.getString("check_in_time") %></td>
                                                        <td><span class="badge bg-success">Present</span></td>
                                                    </tr>
                                                    <%
                                                }
                                                
                                                if (!hasRecords) {
                                                    %>
                                                    <tr>
                                                        <td colspan="5" class="text-center text-muted">
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
                            <i class="fas fa-info-circle me-2"></i>You don't have any courses assigned yet.
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
