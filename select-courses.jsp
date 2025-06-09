<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a student");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    String studentDepartment = (String) session.getAttribute("department");
    Integer studentLevel = (Integer) session.getAttribute("level");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    // Get selected filters
    String selectedLevel = request.getParameter("level");
    String selectedSemester = request.getParameter("semester");
    
    // Default to student's level if no filter selected, or 100 if student level is not set
    int level;
    if (selectedLevel != null && !selectedLevel.trim().isEmpty()) {
        level = Integer.parseInt(selectedLevel);
    } else if (studentLevel != null) {
        level = studentLevel;
    } else {
        level = 100; // Default to 100 level if no level is set
    }
    
    int semester = (selectedSemester != null && !selectedSemester.trim().isEmpty()) ? 
                   Integer.parseInt(selectedSemester) : 1;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Select Courses - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .course-card {
            border-radius: 15px;
            transition: transform 0.2s, box-shadow 0.2s;
            overflow: hidden;
            height: 100%;
        }
        .course-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }
        .course-header {
            background: linear-gradient(45deg, #0072ff, #00c6ff);
            color: white;
            padding: 20px;
        }
        .course-body {
            padding: 20px;
        }
        .course-stats {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 15px;
            margin-top: 20px;
        }
        .selected {
            border: 2px solid #0072ff;
            background-color: #f0f9ff;
        }
        .course-action {
            position: relative;
            bottom: 0;
            width: 100%;
            padding: 15px;
            background: #fff;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body class="bg-light">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="student-dashboard.jsp">
                <i class="fas fa-user-graduate me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="student-dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="select-courses.jsp">Select Courses</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance-record.jsp">My Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="student-check-in.jsp">Check In</a>
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
                <h2><i class="fas fa-book me-2"></i>Course Selection</h2>
                <p class="text-muted">Select the courses you want to enroll in this semester</p>
            </div>
        </div>

        <!-- Filters -->
        <div class="card mb-4">
            <div class="card-body">
                <form method="GET" class="row g-3">
                    <div class="col-md-4">
                        <label for="level" class="form-label">Level</label>
                        <select class="form-select" id="level" name="level">
                            <option value="">All Levels</option>
                            <option value="100" <%= level == 100 ? "selected" : "" %>>100 Level</option>
                            <option value="200" <%= level == 200 ? "selected" : "" %>>200 Level</option>
                            <option value="300" <%= level == 300 ? "selected" : "" %>>300 Level</option>
                            <option value="400" <%= level == 400 ? "selected" : "" %>>400 Level</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label for="semester" class="form-label">Semester</label>
                        <select class="form-select" id="semester" name="semester">
                            <option value="1" <%= semester == 1 ? "selected" : "" %>>First Semester</option>
                            <option value="2" <%= semester == 2 ? "selected" : "" %>>Second Semester</option>
                        </select>
                    </div>
                    <div class="col-md-4 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-filter me-2"></i>Apply Filters
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <% 
        String error = request.getParameter("error");
        if (error != null && !error.isEmpty()) {
        %>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="fas fa-exclamation-circle me-2"></i><%= error %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <%
        }
        String success = request.getParameter("success");
        if (success != null && !success.isEmpty()) {
        %>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-check-circle me-2"></i><%= success %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <%
        }
        %>

        <form action="process-course-selection.jsp" method="POST">
            <div class="row g-4">
                <%
                try {
                    Class.forName("org.sqlite.JDBC");
                    connection = DriverManager.getConnection(jdbcURL);

                    // Get filtered courses with lecturer information
                    StringBuilder sql = new StringBuilder(
                        "SELECT c.*, u.full_name as lecturer_name, " +
                        "(SELECT COUNT(*) FROM course_selections cs WHERE cs.course_code = c.course_code) as enrolled_students, " +
                        "(SELECT 1 FROM course_selections cs WHERE cs.course_code = c.course_code AND cs.student_id = ?) as is_enrolled " +
                        "FROM courses c " +
                        "JOIN users u ON c.lecturer_id = u.user_id " +
                        "WHERE c.semester = ? "
                    );
                    
                    // Only add level filter if a specific level is selected
                    if (selectedLevel != null && !selectedLevel.trim().isEmpty()) {
                        sql.append("AND c.level = ? ");
                    }
                    
                    sql.append("ORDER BY c.course_code");
                    
                    pstmt = connection.prepareStatement(sql.toString());
                    int paramIndex = 1;
                    pstmt.setString(paramIndex++, studentId);
                    pstmt.setInt(paramIndex++, semester);
                    
                    if (selectedLevel != null && !selectedLevel.trim().isEmpty()) {
                        pstmt.setInt(paramIndex, level);
                    }
                    rs = pstmt.executeQuery();

                    while (rs.next()) {
                        String courseCode = rs.getString("course_code");
                        String courseName = rs.getString("course_name");
                        String department = rs.getString("department");
                        String lecturerName = rs.getString("lecturer_name");
                        int enrolledStudents = rs.getInt("enrolled_students");
                        boolean isEnrolled = rs.getObject("is_enrolled") != null;
                        %>
                        <div class="col-md-6 col-lg-4">
                            <div class="card course-card <%= isEnrolled ? "selected" : "" %>">
                                <div class="course-header">
                                    <h5 class="card-title mb-1"><%= courseCode %></h5>
                                    <p class="card-subtitle mb-0"><%= courseName %></p>
                                </div>
                                <div class="course-body">
                                    <div class="mb-3">
                                        <i class="fas fa-building me-2 text-primary"></i>
                                        <strong>Department:</strong> <%= department %>
                                    </div>
                                    <div class="mb-3">
                                        <i class="fas fa-layer-group me-2 text-primary"></i>
                                        <strong>Level:</strong> <%= rs.getInt("level") %> Level
                                    </div>
                                    <div class="mb-3">
                                        <i class="fas fa-calendar me-2 text-primary"></i>
                                        <strong>Semester:</strong> <%= rs.getInt("semester") == 1 ? "First" : "Second" %>
                                    </div>
                                    <div class="mb-3">
                                        <i class="fas fa-chalkboard-teacher me-2 text-primary"></i>
                                        <strong>Lecturer:</strong> <%= lecturerName %>
                                    </div>
                                    <div class="course-stats text-center">
                                        <h4 class="mb-0"><%= enrolledStudents %></h4>
                                        <small class="text-muted">Students Enrolled</small>
                                    </div>
                                </div>
                                <div class="course-action text-center">
                                    <div class="form-check form-switch d-flex justify-content-center align-items-center">
                                        <input class="form-check-input me-2" type="checkbox" 
                                               name="selectedCourses" 
                                               value="<%= courseCode %>"
                                               id="course<%= courseCode %>"
                                               <%= isEnrolled ? "checked" : "" %>>
                                        <label class="form-check-label" for="course<%= courseCode %>">
                                            <%= isEnrolled ? "Enrolled" : "Select Course" %>
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <%
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    %>
                    <div class="col-12">
                        <div class="alert alert-danger">
                            <i class="fas fa-exclamation-circle me-2"></i>
                            Error loading courses: <%= e.getMessage() %>
                        </div>
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

            <div class="text-center mt-4">
                <button type="submit" class="btn btn-primary btn-lg">
                    <i class="fas fa-save me-2"></i>Save Course Selection
                </button>
            </div>
        </form>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Highlight selected courses
        document.querySelectorAll('input[name="selectedCourses"]').forEach(checkbox => {
            checkbox.addEventListener('change', function() {
                const card = this.closest('.course-card');
                if (this.checked) {
                    card.classList.add('selected');
                    this.nextElementSibling.textContent = 'Enrolled';
                } else {
                    card.classList.remove('selected');
                    this.nextElementSibling.textContent = 'Select Course';
                }
            });
        });
    </script>
</body>
</html>
