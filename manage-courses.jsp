<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
    String lecturerDepartment = (String) session.getAttribute("department");
    String lecturerName = (String) session.getAttribute("fullName");
    String errorMsg = request.getParameter("error");
    String successMsg = request.getParameter("success");
    String message = null;
    String messageType = null;

    // Database connection
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);

        // Handle form submissions
        String action = request.getParameter("action");
        if (action != null) {
            if ("add".equals(action)) {
                String courseCode = request.getParameter("courseCode");
                String courseName = request.getParameter("courseName");
                String level = request.getParameter("level");
                String semester = request.getParameter("semester");
                String department = request.getParameter("department");

                // Check if course code already exists
                pstmt = connection.prepareStatement("SELECT 1 FROM courses WHERE course_code = ?");
                pstmt.setString(1, courseCode);
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    message = "Course code already exists!";
                    messageType = "danger";
                } else {
                    pstmt = connection.prepareStatement(
                        "INSERT INTO courses (course_code, course_name, department, lecturer_id, level, semester) " +
                        "VALUES (?, ?, ?, ?, ?, ?)"
                    );
                    pstmt.setString(1, courseCode);
                    pstmt.setString(2, courseName);
                    pstmt.setString(3, department);
                    pstmt.setString(4, lecturerId);
                    pstmt.setInt(5, Integer.parseInt(level));
                    pstmt.setInt(6, Integer.parseInt(semester));
                    pstmt.executeUpdate();

                    message = "Course added successfully!";
                    messageType = "success";
                }
            } else if ("delete".equals(action)) {
                String courseCode = request.getParameter("courseCode");
                pstmt = connection.prepareStatement("DELETE FROM courses WHERE course_code = ? AND lecturer_id = ?");
                pstmt.setString(1, courseCode);
                pstmt.setString(2, lecturerId);
                int rowsAffected = pstmt.executeUpdate();

                if (rowsAffected > 0) {
                    message = "Course deleted successfully!";
                    messageType = "success";
                } else {
                    message = "Failed to delete course!";
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
    <title>Manage Courses - Attendify</title>
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
        .btn-primary {
            background: linear-gradient(to right, #0062cc, #0096ff);
            border: none;
        }
        .btn-primary:hover {
            background: linear-gradient(to right, #0051a9, #0084e2);
        }
        .table {
            background: white;
            border-radius: 10px;
            overflow: hidden;
        }
        .table th {
            background: #f8f9fa;
            color: #0062cc;
            font-weight: 600;
        }
        .form-control, .form-select {
            border-radius: 8px;
            padding: 0.6rem 1rem;
        }
        .form-label {
            font-weight: 500;
            color: #495057;
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
                        <a class="nav-link active" href="manage-courses.jsp"><i class="fas fa-book me-1"></i>Manage Courses</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp"><i class="fas fa-clipboard-list me-1"></i>View Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="enrolled-students.jsp"><i class="fas fa-users me-1"></i>Enrolled Students</a>
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
        <% if (message != null) { %>
            <div class="alert alert-<%= messageType %> alert-dismissible fade show" role="alert">
                <i class="fas fa-<%= messageType.equals("success") ? "check" : "exclamation" %>-circle me-2"></i><%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        <% } %>
        <% if (errorMsg != null && !errorMsg.isEmpty()) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><%= errorMsg %>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        <% } %>
        <% if (successMsg != null && !successMsg.isEmpty()) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i><%= successMsg %>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        <% } %>

        <div class="row">
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title"><i class="fas fa-plus-circle me-2"></i>Add New Course</h5>
                        <form action="manage-courses.jsp" method="POST">
                            <input type="hidden" name="action" value="add">
                            <div class="mb-3">
                                <label for="courseCode" class="form-label">Course Code</label>
                                <input type="text" class="form-control" id="courseCode" name="courseCode" placeholder="e.g., CS101" required>
                            </div>
                            <div class="mb-3">
                                <label for="courseName" class="form-label">Course Name</label>
                                <input type="text" class="form-control" id="courseName" name="courseName" placeholder="e.g., Introduction to Programming" required>
                            </div>
                            <div class="mb-3">
                                <label for="department" class="form-label">Department</label>
                                <input type="text" class="form-control" id="department" name="department" placeholder="e.g., Computer Science" required>
                            </div>
                            <div class="mb-3">
                                <label for="level" class="form-label">Level</label>
                                <select class="form-select" id="level" name="level" required>
                                    <option value="100">100 Level</option>
                                    <option value="200">200 Level</option>
                                    <option value="300">300 Level</option>
                                    <option value="400">400 Level</option>
                                </select>
                            </div>
                            <div class="mb-3">
                                <label for="semester" class="form-label">Semester</label>
                                <select class="form-select" id="semester" name="semester" required>
                                    <option value="1">First Semester</option>
                                    <option value="2">Second Semester</option>
                                </select>
                            </div>
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="fas fa-plus-circle me-2"></i>Add Course
                            </button>
                        </form>
                    </div>
                </div>
            </div>

            <div class="col-md-8">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title"><i class="fas fa-book me-2"></i>Your Courses</h5>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead>
                                    <tr>
                                        <th>Course Code</th>
                                        <th>Course Name</th>
                                        <th>Department</th>
                                        <th>Level</th>
                                        <th>Semester</th>
                                        <th>Students</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        pstmt = connection.prepareStatement(
                                            "SELECT c.*, (SELECT COUNT(*) FROM course_selections cs WHERE cs.course_code = c.course_code) as student_count " +
                                            "FROM courses c WHERE c.lecturer_id = ? ORDER BY c.level, c.semester, c.course_code"
                                        );
                                        pstmt.setString(1, lecturerId);
                                        rs = pstmt.executeQuery();

                                        while (rs.next()) {
                                            String courseCode = rs.getString("course_code");
                                            String courseName = rs.getString("course_name");
                                            String department = rs.getString("department");
                                            int level = rs.getInt("level");
                                            int semester = rs.getInt("semester");
                                            int studentCount = rs.getInt("student_count");
                                    %>
                                    <tr>
                                        <td><%= courseCode %></td>
                                        <td><%= courseName %></td>
                                        <td><%= department %></td>
                                        <td><%= level %></td>
                                        <td><%= semester == 1 ? "First" : "Second" %></td>
                                        <td>
                                            <span class="badge bg-info">
                                                <i class="fas fa-users me-1"></i><%= studentCount %> students
                                            </span>
                                        </td>
                                        <td>
                                            <div class="btn-group" role="group">
                                                <a href="view-course.jsp?code=<%= courseCode %>" class="btn btn-info btn-sm" title="View Course Details">
                                                    <i class="fas fa-eye"></i>
                                                </a>
                                                <a href="edit-course.jsp?code=<%= courseCode %>" class="btn btn-warning btn-sm" title="Edit Course">
                                                    <i class="fas fa-edit"></i>
                                                </a>
                                                <form method="POST" action="manage-courses.jsp" style="display: inline;">
                                                    <input type="hidden" name="action" value="delete">
                                                    <input type="hidden" name="courseCode" value="<%= courseCode %>">
                                                    <button type="submit" class="btn btn-danger btn-sm" title="Delete Course" onclick="return confirm('Are you sure you want to delete this course?');">
                                                        <i class="fas fa-trash"></i>
                                                    </button>
                                                </form>
                                            </div>
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
