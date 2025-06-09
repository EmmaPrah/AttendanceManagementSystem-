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
    String message = null;
    String messageType = null;
    
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

    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            // Handle form submission
            String newCourseName = request.getParameter("courseName");
            String newDepartment = request.getParameter("department");
            String newLevel = request.getParameter("level");
            String newSemester = request.getParameter("semester");

            pstmt = connection.prepareStatement(
                "UPDATE courses SET course_name = ?, department = ?, level = ?, semester = ? " +
                "WHERE course_code = ? AND lecturer_id = ?"
            );
            pstmt.setString(1, newCourseName);
            pstmt.setString(2, newDepartment);
            pstmt.setInt(3, Integer.parseInt(newLevel));
            pstmt.setInt(4, Integer.parseInt(newSemester));
            pstmt.setString(5, courseCode);
            pstmt.setString(6, lecturerId);
            
            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected > 0) {
                response.sendRedirect("manage-courses.jsp?success=Course updated successfully");
                return;
            } else {
                message = "Failed to update course";
                messageType = "danger";
            }
        }

        // Get course details
        pstmt = connection.prepareStatement(
            "SELECT * FROM courses WHERE course_code = ? AND lecturer_id = ?"
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
    <title>Edit Course - <%= courseCode %> - Attendify</title>
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
            <div class="col-md-6 mx-auto">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">
                            <i class="fas fa-edit me-2"></i>Edit Course
                            <a href="manage-courses.jsp" class="btn btn-outline-primary btn-sm float-end">
                                <i class="fas fa-arrow-left me-1"></i>Back to Courses
                            </a>
                        </h5>

                        <% if (message != null) { %>
                            <div class="alert alert-<%= messageType %> alert-dismissible fade show" role="alert">
                                <i class="fas fa-<%= messageType.equals("success") ? "check" : "exclamation" %>-circle me-2"></i><%= message %>
                                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                            </div>
                        <% } %>

                        <form action="edit-course.jsp" method="POST">
                            <input type="hidden" name="code" value="<%= courseCode %>">
                            
                            <div class="mb-3">
                                <label for="courseCode" class="form-label">Course Code</label>
                                <input type="text" class="form-control" id="courseCode" value="<%= courseCode %>" readonly>
                            </div>
                            
                            <div class="mb-3">
                                <label for="courseName" class="form-label">Course Name</label>
                                <input type="text" class="form-control" id="courseName" name="courseName" value="<%= courseName %>" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="department" class="form-label">Department</label>
                                <input type="text" class="form-control" id="department" name="department" value="<%= department %>" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="level" class="form-label">Level</label>
                                <select class="form-select" id="level" name="level" required>
                                    <option value="100" <%= level == 100 ? "selected" : "" %>>100 Level</option>
                                    <option value="200" <%= level == 200 ? "selected" : "" %>>200 Level</option>
                                    <option value="300" <%= level == 300 ? "selected" : "" %>>300 Level</option>
                                    <option value="400" <%= level == 400 ? "selected" : "" %>>400 Level</option>
                                </select>
                            </div>
                            
                            <div class="mb-3">
                                <label for="semester" class="form-label">Semester</label>
                                <select class="form-select" id="semester" name="semester" required>
                                    <option value="1" <%= semester == 1 ? "selected" : "" %>>First Semester</option>
                                    <option value="2" <%= semester == 2 ? "selected" : "" %>>Second Semester</option>
                                </select>
                            </div>
                            
                            <div class="d-grid">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save me-1"></i>Save Changes
                                </button>
                            </div>
                        </form>
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
