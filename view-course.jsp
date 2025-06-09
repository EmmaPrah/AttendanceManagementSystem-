<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
    String lecturerName = (String) session.getAttribute("fullName");
    String courseCode = request.getParameter("code");
    
    if (courseCode == null || courseCode.isEmpty()) {
        response.sendRedirect("manage-courses.jsp?error=Invalid course code");
        return;
    }

    // Database connection
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    String courseName = "";
    String department = "";
    int level = 0;
    int semester = 0;
    int studentCount = 0;

    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);

        // Get course details
        pstmt = connection.prepareStatement(
            "SELECT c.*, (SELECT COUNT(*) FROM course_selections cs WHERE cs.course_code = c.course_code) as student_count " +
            "FROM courses c WHERE c.course_code = ? AND c.lecturer_id = ?"
        );
        pstmt.setString(1, courseCode);
        pstmt.setString(2, lecturerId);
        rs = pstmt.executeQuery();

        if (!rs.next()) {
            response.sendRedirect("manage-courses.jsp?error=Course not found or access denied");
            return;
        }

        courseName = rs.getString("course_name");
        department = rs.getString("department");
        level = rs.getInt("level");
        semester = rs.getInt("semester");
        studentCount = rs.getInt("student_count");
    } catch (Exception e) {
        response.sendRedirect("manage-courses.jsp?error=" + e.getMessage());
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Course - <%= courseCode %> - Attendify</title>
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
        .info-label {
            font-weight: 500;
            color: #6c757d;
        }
        .info-value {
            font-size: 1.1rem;
        }
        .badge {
            font-size: 0.9rem;
            padding: 0.5rem 1rem;
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
                        <a class="nav-link" href="lecturer-dashboard.jsp"><i class="fas fa-home me-1"></i>Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-classroom-locations.jsp"><i class="fas fa-map-marker-alt me-1"></i>Classroom Locations</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp"><i class="fas fa-book me-1"></i>Manage Courses</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp"><i class="fas fa-clipboard-list me-1"></i>View Attendance</a>
                    </li>
                </ul>
                <div class="d-flex align-items-center">
                    <span class="text-white me-3"><i class="fas fa-user-circle me-1"></i><%= lecturerName %></span>
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
                        <h5 class="card-title">
                            <i class="fas fa-book me-2"></i>Course Details
                            <a href="manage-courses.jsp" class="btn btn-outline-primary btn-sm float-end">
                                <i class="fas fa-arrow-left me-1"></i>Back to Courses
                            </a>
                        </h5>
                        <div class="row mb-4">
                            <div class="col-md-6">
                                <p class="info-label mb-1">Course Code</p>
                                <p class="info-value"><%= courseCode %></p>
                            </div>
                            <div class="col-md-6">
                                <p class="info-label mb-1">Course Name</p>
                                <p class="info-value"><%= courseName %></p>
                            </div>
                        </div>
                        <div class="row mb-4">
                            <div class="col-md-6">
                                <p class="info-label mb-1">Department</p>
                                <p class="info-value"><%= department %></p>
                            </div>
                            <div class="col-md-6">
                                <p class="info-label mb-1">Level</p>
                                <p class="info-value"><%= level %></p>
                            </div>
                        </div>
                        <div class="row mb-4">
                            <div class="col-md-6">
                                <p class="info-label mb-1">Semester</p>
                                <p class="info-value"><%= semester == 1 ? "First" : "Second" %></p>
                            </div>
                            <div class="col-md-6">
                                <p class="info-label mb-1">Enrolled Students</p>
                                <p class="info-value">
                                    <span class="badge bg-info">
                                        <i class="fas fa-users me-1"></i><%= studentCount %> students
                                    </span>
                                </p>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-12">
                                <hr>
                                <div class="d-flex justify-content-between">
                                    <a href="edit-course.jsp?code=<%= courseCode %>" class="btn btn-warning">
                                        <i class="fas fa-edit me-1"></i>Edit Course
                                    </a>
                                    <form method="POST" action="manage-courses.jsp" style="display: inline;" onsubmit="return confirm('Are you sure you want to delete this course?');">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="courseCode" value="<%= courseCode %>">
                                        <button type="submit" class="btn btn-danger">
                                            <i class="fas fa-trash me-1"></i>Delete Course
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card mt-4">
                    <div class="card-body">
                        <h5 class="card-title"><i class="fas fa-users me-2"></i>Enrolled Students</h5>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead>
                                    <tr>
                                        <th>Student ID</th>
                                        <th>Name</th>
                                        <th>Department</th>
                                        <th>Level</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        pstmt = connection.prepareStatement(
                                            "SELECT u.user_id, u.full_name, u.department, u.level " +
                                            "FROM users u " +
                                            "JOIN course_selections cs ON u.user_id = cs.student_id " +
                                            "WHERE cs.course_code = ? " +
                                            "ORDER BY u.full_name"
                                        );
                                        pstmt.setString(1, courseCode);
                                        rs = pstmt.executeQuery();

                                        while (rs.next()) {
                                            String studentId = rs.getString("user_id");
                                            String studentName = rs.getString("full_name");
                                            String studentDept = rs.getString("department");
                                            int studentLevel = rs.getInt("level");
                                    %>
                                    <tr>
                                        <td><%= studentId %></td>
                                        <td><%= studentName %></td>
                                        <td><%= studentDept %></td>
                                        <td><%= studentLevel %></td>
                                        <td>
                                            <a href="view-student-attendance.jsp?studentId=<%= studentId %>&courseCode=<%= courseCode %>" 
                                               class="btn btn-info btn-sm" title="View Attendance">
                                                <i class="fas fa-clipboard-check"></i>
                                            </a>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
<% 
    try {
        if (rs != null) rs.close();
        if (pstmt != null) pstmt.close();
        if (connection != null) connection.close();
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
